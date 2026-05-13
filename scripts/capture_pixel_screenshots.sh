#!/usr/bin/env bash

set -euo pipefail

package_id="com.taziggg100.roustanrobert"
apk_path="${SCREENSHOT_APK_PATH:-docs/screenshot-app-debug.apk}"
screens_dir="docs/screens"

adb_cmd() {
  if [[ -n "${ANDROID_SERIAL:-}" ]]; then
    adb -s "${ANDROID_SERIAL}" "$@"
  else
    adb "$@"
  fi
}

device_count="$(adb devices | awk 'NR > 1 && $2 == "device" { count++ } END { print count + 0 }')"
if [[ "${device_count}" != "1" && -z "${ANDROID_SERIAL:-}" ]]; then
  echo "Expected exactly one connected emulator, found ${device_count}. Set ANDROID_SERIAL if needed." >&2
  exit 1
fi

mkdir -p "${screens_dir}"
find "${screens_dir}" -maxdepth 1 -type f -name '*.png' -delete
touch "${screens_dir}/.gitkeep"

if [[ "${SKIP_SCREENSHOT_BUILD:-0}" != "1" ]]; then
  flutter build apk --debug --dart-define=SCREENSHOT_MODE=true
fi

if [[ "${SKIP_SCREENSHOT_INSTALL:-0}" != "1" ]]; then
  if [[ ! -f "${apk_path}" ]]; then
    echo "Expected screenshot APK at ${apk_path}" >&2
    exit 1
  fi
  adb_cmd install -r "${apk_path}" >/dev/null
elif ! adb_cmd shell pm path "${package_id}" >/dev/null 2>&1; then
  echo "Package ${package_id} is not installed; cannot skip screenshot install." >&2
  exit 1
fi
adb_cmd shell input keyevent KEYCODE_WAKEUP >/dev/null 2>&1 || true
adb_cmd shell wm dismiss-keyguard >/dev/null 2>&1 || true
if [[ "${SKIP_SCREENSHOT_LAUNCH:-0}" != "1" ]]; then
  adb_cmd shell input keyevent KEYCODE_HOME >/dev/null 2>&1 || true
  sleep 1
  adb_cmd shell am force-stop "${package_id}" >/dev/null 2>&1 || true
  adb_cmd shell am start -W -n "${package_id}/.MainActivity" >/dev/null
  sleep 4
fi

screen_size() {
  adb_cmd shell wm size | tr -d '\r' | sed -nE 's/.*Physical size: ([0-9]+)x([0-9]+).*/\1 \2/p' | tail -n 1
}

read -r screen_w screen_h < <(screen_size)
if [[ -z "${screen_w:-}" || -z "${screen_h:-}" ]]; then
  echo "Could not determine emulator screen size." >&2
  exit 1
fi

assert_foreground() {
  local focus
  focus="$(adb_cmd shell dumpsys window | tr -d '\r' | grep -E 'mCurrentFocus|mFocusedApp' || true)"
  if [[ "${focus}" != *"${package_id}"* ]]; then
    echo "The app is not in the foreground; refusing to capture a store screenshot." >&2
    echo "${focus}" >&2
    exit 1
  fi
}

capture() {
  local name="$1"
  assert_foreground
  sleep 1
  adb_cmd exec-out screencap -p > "${screens_dir}/${name}.png"
}

tap_nav() {
  local index="$1"
  local x=$((screen_w * (index * 2 + 1) / 10))
  local y=$((screen_h - 170))
  adb_cmd shell input tap "${x}" "${y}"
  sleep 1
}

tap_nav 0
capture "01_dashboard"

tap_nav 1
capture "02_quality"

adb_cmd shell input tap $((screen_w - 220)) $((screen_h - 390))
sleep 1
capture "03_quality_form"

adb_cmd shell input keyevent 4
sleep 1

adb_cmd shell input tap $((screen_w / 2)) $((screen_h * 24 / 100))
sleep 1
capture "04_quality_detail"

adb_cmd shell input keyevent 4
sleep 1
tap_nav 2
capture "05_leads"

tap_nav 3
capture "06_shipments"

tap_nav 4
capture "07_settings"

echo "Captured screenshots in ${screens_dir}"
