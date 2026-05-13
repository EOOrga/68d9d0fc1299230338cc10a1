import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roustan_robert/main.dart';

void main() {
  testWidgets('dashboard opens and bottom navigation reaches leads', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      RoustanRobertApp(store: OperationsStore.screenshotStore()),
    );

    expect(find.text('Daily command board'), findsOneWidget);
    expect(find.text('Open checks'), findsOneWidget);

    await tester.tap(find.text('Leads'));
    await tester.pumpAndSettle();

    expect(find.text('Lead management'), findsOneWidget);
    expect(find.text('Atlas Distribution'), findsOneWidget);
  });

  testWidgets('quality workflow saves a local checklist', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = OperationsStore.testStore();
    await tester.pumpWidget(RoustanRobertApp(store: store));

    await tester.tap(find.text('Quality'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New check'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('quality-area-field')),
      'Returns desk',
    );
    await tester.enterText(
      find.byKey(const ValueKey('quality-batch-field')),
      'RR-RET-44',
    );
    await tester.enterText(
      find.byKey(const ValueKey('quality-owner-field')),
      'Samir',
    );
    await tester.enterText(
      find.byType(TextFormField).last,
      'Inspect carton labels.',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('quality-save-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quality-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('Returns desk'), findsOneWidget);
    expect(store.qualityChecks.length, 1);
  });
}
