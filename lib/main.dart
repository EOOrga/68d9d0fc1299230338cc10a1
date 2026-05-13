import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bool kScreenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');

void main() {
  runApp(const RoustanRobertApp());
}

class RoustanRobertApp extends StatelessWidget {
  const RoustanRobertApp({
    super.key,
    this.store,
    this.screenshotMode = kScreenshotMode,
  });

  final OperationsStore? store;
  final bool screenshotMode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF24423E),
      brightness: Brightness.light,
      primary: const Color(0xFF24423E),
      secondary: const Color(0xFFB77838),
      tertiary: const Color(0xFF2C6D63),
      surface: const Color(0xFFF8F4EC),
    );

    return MaterialApp(
      title: 'ROUSTAN ROBERT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF8F4EC),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Color(0xFFF8F4EC),
          foregroundColor: Color(0xFF19212A),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: colorScheme.primaryContainer,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            );
          }),
        ),
      ),
      home: store == null
          ? FutureBuilder<OperationsStore>(
              future: OperationsStore.load(screenshotMode: screenshotMode),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const LoadingScreen();
                }
                return OperationsShell(store: snapshot.data!);
              },
            )
          : OperationsShell(store: store!),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class OperationsStore extends ChangeNotifier {
  OperationsStore._({
    required this.screenshotMode,
    required List<QualityCheck> qualityChecks,
    required List<ResourceAllocation> resources,
    required List<LeadRecord> leads,
    required List<ShipmentLog> shipments,
    required SettingsState settings,
    SharedPreferences? preferences,
  }) : _qualityChecks = qualityChecks,
       _resources = resources,
       _leads = leads,
       _shipments = shipments,
       _settings = settings,
       _preferences = preferences;

  final bool screenshotMode;
  final SharedPreferences? _preferences;

  static const _qualityKey = 'quality_checks';
  static const _resourceKey = 'resource_allocations';
  static const _leadKey = 'lead_records';
  static const _shipmentKey = 'shipment_logs';
  static const _settingsKey = 'operations_settings';

  List<QualityCheck> _qualityChecks;
  final List<ResourceAllocation> _resources;
  List<LeadRecord> _leads;
  final List<ShipmentLog> _shipments;
  SettingsState _settings;

  List<QualityCheck> get qualityChecks => List.unmodifiable(_qualityChecks);
  List<ResourceAllocation> get resources => List.unmodifiable(_resources);
  List<LeadRecord> get leads => List.unmodifiable(_leads);
  List<ShipmentLog> get shipments => List.unmodifiable(_shipments);
  SettingsState get settings => _settings;

  int get openQualityChecks =>
      _qualityChecks.where((item) => item.status != 'Passed').length;
  int get highLoadResources =>
      _resources.where((item) => item.loadPercent >= 85).length;
  int get activeLeads => _leads.where((item) => item.stage != 'Won').length;
  int get shipmentRisks =>
      _shipments.where((item) => item.status == 'Delayed').length;

  static Future<OperationsStore> load({bool screenshotMode = false}) async {
    if (screenshotMode) {
      return screenshotStore();
    }

    final preferences = await SharedPreferences.getInstance();
    return OperationsStore._(
      screenshotMode: false,
      preferences: preferences,
      qualityChecks: _decodeList(
        preferences.getString(_qualityKey),
        QualityCheck.fromJson,
      ),
      resources: _decodeList(
        preferences.getString(_resourceKey),
        ResourceAllocation.fromJson,
      ),
      leads: _decodeList(preferences.getString(_leadKey), LeadRecord.fromJson),
      shipments: _decodeList(
        preferences.getString(_shipmentKey),
        ShipmentLog.fromJson,
      ),
      settings: SettingsState.fromJson(
        _decodeMap(preferences.getString(_settingsKey)),
      ),
    );
  }

  static OperationsStore screenshotStore() {
    return OperationsStore._(
      screenshotMode: true,
      qualityChecks: [
        const QualityCheck(
          id: 'qc-001',
          area: 'Packaging line A',
          batch: 'Batch RR-1842',
          owner: 'Nadia',
          due: 'Today 14:00',
          status: 'In review',
          stepsPassed: 7,
          stepsTotal: 9,
          note:
              'Seal pressure verified; final carton sample waiting on approval.',
        ),
        const QualityCheck(
          id: 'qc-002',
          area: 'Inbound inspection',
          batch: 'Supplier lot M31',
          owner: 'Omar',
          due: 'Today 16:30',
          status: 'Open',
          stepsPassed: 3,
          stepsTotal: 8,
          note: 'Two pallets need barcode relabeling before release.',
        ),
        const QualityCheck(
          id: 'qc-003',
          area: 'Dispatch staging',
          batch: 'Route Casablanca East',
          owner: 'Salma',
          due: 'Tomorrow 09:15',
          status: 'Passed',
          stepsPassed: 10,
          stepsTotal: 10,
          note: 'Load checks complete and staged for driver handoff.',
        ),
      ],
      resources: [
        const ResourceAllocation(
          id: 'res-001',
          team: 'Quality team',
          asset: 'Line inspectors',
          shift: 'Morning',
          loadPercent: 82,
          note: 'Two inspectors assigned to packaging line A.',
        ),
        const ResourceAllocation(
          id: 'res-002',
          team: 'Warehouse',
          asset: 'Forklift bay 2',
          shift: 'Late shift',
          loadPercent: 91,
          note: 'High usage during shipment consolidation.',
        ),
        const ResourceAllocation(
          id: 'res-003',
          team: 'Sales desk',
          asset: 'Lead follow-up block',
          shift: 'Afternoon',
          loadPercent: 64,
          note: 'Capacity available for two more callbacks.',
        ),
      ],
      leads: [
        const LeadRecord(
          id: 'lead-001',
          company: 'Atlas Distribution',
          contact: 'Imane B.',
          stage: 'Proposal',
          nextAction: 'Confirm service window and pricing notes',
          value: 42000,
        ),
        const LeadRecord(
          id: 'lead-002',
          company: 'Rabat Retail Group',
          contact: 'Youssef K.',
          stage: 'Qualified',
          nextAction: 'Prepare quality assurance summary',
          value: 18000,
        ),
        const LeadRecord(
          id: 'lead-003',
          company: 'North Port Traders',
          contact: 'Leila M.',
          stage: 'Won',
          nextAction: 'Convert to onboarding shipment checklist',
          value: 53000,
        ),
      ],
      shipments: [
        const ShipmentLog(
          id: 'ship-001',
          reference: 'RR-SH-2201',
          destination: 'Casablanca East',
          status: 'Ready',
          eta: 'Today 18:00',
          cartons: 84,
        ),
        const ShipmentLog(
          id: 'ship-002',
          reference: 'RR-SH-2202',
          destination: 'Marrakesh Hub',
          status: 'Delayed',
          eta: 'Tomorrow 10:30',
          cartons: 51,
        ),
        const ShipmentLog(
          id: 'ship-003',
          reference: 'RR-SH-2203',
          destination: 'Rabat North',
          status: 'In transit',
          eta: 'Today 21:15',
          cartons: 38,
        ),
      ],
      settings: const SettingsState(
        compactDashboard: false,
        riskTags: true,
        handoffNotes: true,
      ),
    );
  }

  static OperationsStore testStore() {
    return OperationsStore._(
      screenshotMode: true,
      qualityChecks: [],
      resources: const [
        ResourceAllocation(
          id: 'res-test',
          team: 'Warehouse',
          asset: 'Dock team',
          shift: 'Morning',
          loadPercent: 70,
          note: 'Balanced shift coverage.',
        ),
      ],
      leads: const [],
      shipments: const [],
      settings: const SettingsState(
        compactDashboard: false,
        riskTags: true,
        handoffNotes: true,
      ),
    );
  }

  static List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) mapper,
  ) {
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return [];
    }
    return decoded
        .whereType<Map>()
        .map((item) => mapper(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Map<String, dynamic> _decodeMap(String? raw) {
    if (raw == null || raw.isEmpty) {
      return {};
    }
    final decoded = jsonDecode(raw);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
  }

  void addQualityCheck(QualityCheck check) {
    _qualityChecks = [check, ..._qualityChecks];
    _persist();
    notifyListeners();
  }

  void addLead(LeadRecord lead) {
    _leads = [lead, ..._leads];
    _persist();
    notifyListeners();
  }

  void updateSettings(SettingsState settings) {
    _settings = settings;
    _persist();
    notifyListeners();
  }

  void _persist() {
    if (screenshotMode || _preferences == null) {
      return;
    }

    unawaited(
      Future.wait([
        _preferences.setString(
          _qualityKey,
          jsonEncode(_qualityChecks.map((item) => item.toJson()).toList()),
        ),
        _preferences.setString(
          _resourceKey,
          jsonEncode(_resources.map((item) => item.toJson()).toList()),
        ),
        _preferences.setString(
          _leadKey,
          jsonEncode(_leads.map((item) => item.toJson()).toList()),
        ),
        _preferences.setString(
          _shipmentKey,
          jsonEncode(_shipments.map((item) => item.toJson()).toList()),
        ),
        _preferences.setString(_settingsKey, jsonEncode(_settings.toJson())),
      ]),
    );
  }
}

class QualityCheck {
  const QualityCheck({
    required this.id,
    required this.area,
    required this.batch,
    required this.owner,
    required this.due,
    required this.status,
    required this.stepsPassed,
    required this.stepsTotal,
    required this.note,
  });

  final String id;
  final String area;
  final String batch;
  final String owner;
  final String due;
  final String status;
  final int stepsPassed;
  final int stepsTotal;
  final String note;

  double get completion => stepsTotal == 0 ? 0 : stepsPassed / stepsTotal;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'area': area,
      'batch': batch,
      'owner': owner,
      'due': due,
      'status': status,
      'stepsPassed': stepsPassed,
      'stepsTotal': stepsTotal,
      'note': note,
    };
  }

  factory QualityCheck.fromJson(Map<String, dynamic> json) {
    return QualityCheck(
      id: (json['id'] as String?) ?? _newId('qc'),
      area: (json['area'] as String?) ?? '',
      batch: (json['batch'] as String?) ?? '',
      owner: (json['owner'] as String?) ?? '',
      due: (json['due'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'Open',
      stepsPassed: (json['stepsPassed'] as num?)?.toInt() ?? 0,
      stepsTotal: (json['stepsTotal'] as num?)?.toInt() ?? 8,
      note: (json['note'] as String?) ?? '',
    );
  }
}

class ResourceAllocation {
  const ResourceAllocation({
    required this.id,
    required this.team,
    required this.asset,
    required this.shift,
    required this.loadPercent,
    required this.note,
  });

  final String id;
  final String team;
  final String asset;
  final String shift;
  final int loadPercent;
  final String note;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team': team,
      'asset': asset,
      'shift': shift,
      'loadPercent': loadPercent,
      'note': note,
    };
  }

  factory ResourceAllocation.fromJson(Map<String, dynamic> json) {
    return ResourceAllocation(
      id: (json['id'] as String?) ?? _newId('res'),
      team: (json['team'] as String?) ?? '',
      asset: (json['asset'] as String?) ?? '',
      shift: (json['shift'] as String?) ?? '',
      loadPercent: (json['loadPercent'] as num?)?.toInt() ?? 0,
      note: (json['note'] as String?) ?? '',
    );
  }
}

class LeadRecord {
  const LeadRecord({
    required this.id,
    required this.company,
    required this.contact,
    required this.stage,
    required this.nextAction,
    required this.value,
  });

  final String id;
  final String company;
  final String contact;
  final String stage;
  final String nextAction;
  final int value;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company': company,
      'contact': contact,
      'stage': stage,
      'nextAction': nextAction,
      'value': value,
    };
  }

  factory LeadRecord.fromJson(Map<String, dynamic> json) {
    return LeadRecord(
      id: (json['id'] as String?) ?? _newId('lead'),
      company: (json['company'] as String?) ?? '',
      contact: (json['contact'] as String?) ?? '',
      stage: (json['stage'] as String?) ?? 'Qualified',
      nextAction: (json['nextAction'] as String?) ?? '',
      value: (json['value'] as num?)?.toInt() ?? 0,
    );
  }
}

class ShipmentLog {
  const ShipmentLog({
    required this.id,
    required this.reference,
    required this.destination,
    required this.status,
    required this.eta,
    required this.cartons,
  });

  final String id;
  final String reference;
  final String destination;
  final String status;
  final String eta;
  final int cartons;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'destination': destination,
      'status': status,
      'eta': eta,
      'cartons': cartons,
    };
  }

  factory ShipmentLog.fromJson(Map<String, dynamic> json) {
    return ShipmentLog(
      id: (json['id'] as String?) ?? _newId('ship'),
      reference: (json['reference'] as String?) ?? '',
      destination: (json['destination'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'Ready',
      eta: (json['eta'] as String?) ?? '',
      cartons: (json['cartons'] as num?)?.toInt() ?? 0,
    );
  }
}

class SettingsState {
  const SettingsState({
    required this.compactDashboard,
    required this.riskTags,
    required this.handoffNotes,
  });

  final bool compactDashboard;
  final bool riskTags;
  final bool handoffNotes;

  SettingsState copyWith({
    bool? compactDashboard,
    bool? riskTags,
    bool? handoffNotes,
  }) {
    return SettingsState(
      compactDashboard: compactDashboard ?? this.compactDashboard,
      riskTags: riskTags ?? this.riskTags,
      handoffNotes: handoffNotes ?? this.handoffNotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'compactDashboard': compactDashboard,
      'riskTags': riskTags,
      'handoffNotes': handoffNotes,
    };
  }

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    return SettingsState(
      compactDashboard: (json['compactDashboard'] as bool?) ?? false,
      riskTags: (json['riskTags'] as bool?) ?? true,
      handoffNotes: (json['handoffNotes'] as bool?) ?? true,
    );
  }
}

String _newId(String prefix) =>
    '$prefix-${DateTime.now().microsecondsSinceEpoch}';

class OperationsShell extends StatefulWidget {
  const OperationsShell({super.key, required this.store});

  final OperationsStore store;

  @override
  State<OperationsShell> createState() => _OperationsShellState();
}

class _OperationsShellState extends State<OperationsShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(store: widget.store),
      QualityPage(store: widget.store),
      LeadsPage(store: widget.store),
      ShipmentsPage(store: widget.store),
      SettingsPage(store: widget.store),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const _BrandTitle(),
        actions: [
          IconButton(
            tooltip: 'Privacy',
            onPressed: () => setState(() => _index = 4),
            icon: const Icon(Icons.privacy_tip_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: pages[_index],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Quality',
          ),
          NavigationDestination(
            icon: Icon(Icons.handshake_outlined),
            selectedIcon: Icon(Icons.handshake),
            label: 'Leads',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'Shipments',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'ROUSTAN ROBERT',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        Text(
          'Operations control',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.store});

  final OperationsStore store;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('dashboard'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Text(
          'Daily command board',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Track quality, staffing, leads, and shipment status without accounts or cloud sync.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.45,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            MetricCard(
              label: 'Open checks',
              value: '${store.openQualityChecks}',
              icon: Icons.fact_check_outlined,
              color: const Color(0xFF2C6D63),
            ),
            MetricCard(
              label: 'High loads',
              value: '${store.highLoadResources}',
              icon: Icons.groups_2_outlined,
              color: const Color(0xFFB77838),
            ),
            MetricCard(
              label: 'Active leads',
              value: '${store.activeLeads}',
              icon: Icons.trending_up,
              color: const Color(0xFF24423E),
            ),
            MetricCard(
              label: 'Shipment risks',
              value: '${store.shipmentRisks}',
              icon: Icons.warning_amber_outlined,
              color: const Color(0xFF9D3D2E),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionHeader(
          title: 'Resource allocation',
          subtitle: '${store.resources.length} active assignments',
        ),
        const SizedBox(height: 10),
        ...store.resources.map(
          (resource) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ResourceCard(resource: resource),
          ),
        ),
        const SizedBox(height: 8),
        _SectionHeader(
          title: 'Priority handoffs',
          subtitle: 'Local operational notes',
        ),
        const SizedBox(height: 10),
        PriorityCard(
          icon: Icons.inventory_2_outlined,
          title: 'Quality release queue',
          text: store.qualityChecks.isEmpty
              ? 'No quality checks are waiting.'
              : store.qualityChecks.first.note,
        ),
        const SizedBox(height: 10),
        PriorityCard(
          icon: Icons.route_outlined,
          title: 'Shipment follow-up',
          text: store.shipments.isEmpty
              ? 'No shipment logs are stored.'
              : '${store.shipments.first.reference} to ${store.shipments.first.destination} is ${store.shipments.first.status.toLowerCase()}.',
        ),
      ],
    );
  }
}

class QualityPage extends StatelessWidget {
  const QualityPage({super.key, required this.store});

  final OperationsStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('quality'),
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        children: [
          const _SectionHeader(
            title: 'Quality control',
            subtitle: 'Checklist progress by area and batch',
          ),
          const SizedBox(height: 12),
          if (store.qualityChecks.isEmpty)
            const EmptyState(
              icon: Icons.fact_check_outlined,
              title: 'No checklists yet',
              text:
                  'Create the first checklist to track an area, owner, and handoff note.',
            )
          else
            ...store.qualityChecks.map(
              (check) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: QualityCard(
                  check: check,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => QualityDetailPage(check: check),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<QualityCheck>(
            MaterialPageRoute<QualityCheck>(
              builder: (context) => const QualityFormPage(),
            ),
          );
          if (created != null) {
            store.addQualityCheck(created);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New check'),
      ),
    );
  }
}

class QualityDetailPage extends StatelessWidget {
  const QualityDetailPage({super.key, required this.check});

  final QualityCheck check;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checklist detail')),
      body: ListView(
        key: const ValueKey('quality-detail'),
        padding: const EdgeInsets.all(16),
        children: [
          StatusBanner(status: check.status),
          const SizedBox(height: 12),
          Text(
            check.area,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${check.batch} - owner ${check.owner}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          ProgressPanel(
            title: 'Checklist completion',
            progress: check.completion,
            footer:
                '${check.stepsPassed} of ${check.stepsTotal} checkpoints complete',
          ),
          const SizedBox(height: 12),
          InfoPanel(
            title: 'Handoff note',
            text: check.note,
            icon: Icons.notes_outlined,
          ),
          const SizedBox(height: 12),
          InfoPanel(
            title: 'Due window',
            text: check.due,
            icon: Icons.schedule_outlined,
          ),
        ],
      ),
    );
  }
}

class QualityFormPage extends StatefulWidget {
  const QualityFormPage({super.key});

  @override
  State<QualityFormPage> createState() => _QualityFormPageState();
}

class _QualityFormPageState extends State<QualityFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _areaController = TextEditingController();
  final _batchController = TextEditingController();
  final _ownerController = TextEditingController();
  final _noteController = TextEditingController();
  String _status = 'Open';
  double _stepsPassed = 4;

  @override
  void dispose() {
    _areaController.dispose();
    _batchController.dispose();
    _ownerController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New quality check')),
      body: Form(
        key: _formKey,
        child: ListView(
          key: const ValueKey('quality-form'),
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Create a checklist',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('quality-area-field'),
              controller: _areaController,
              decoration: const InputDecoration(labelText: 'Area'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('quality-batch-field'),
              controller: _batchController,
              decoration: const InputDecoration(
                labelText: 'Batch or job reference',
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('quality-owner-field'),
              controller: _ownerController,
              decoration: const InputDecoration(labelText: 'Owner'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              items: const [
                DropdownMenuItem(value: 'Open', child: Text('Open')),
                DropdownMenuItem(value: 'In review', child: Text('In review')),
                DropdownMenuItem(value: 'Passed', child: Text('Passed')),
              ],
              decoration: const InputDecoration(labelText: 'Status'),
              onChanged: (value) => setState(() => _status = value ?? 'Open'),
            ),
            const SizedBox(height: 12),
            Text(
              'Completed checkpoints: ${_stepsPassed.round()} of 10',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Slider(
              value: _stepsPassed,
              min: 0,
              max: 10,
              divisions: 10,
              label: _stepsPassed.round().toString(),
              onChanged: (value) => setState(() => _stepsPassed = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              minLines: 3,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Handoff note'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const ValueKey('quality-save-button'),
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save checklist'),
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      QualityCheck(
        id: _newId('qc'),
        area: _areaController.text.trim(),
        batch: _batchController.text.trim(),
        owner: _ownerController.text.trim(),
        due: 'Next shift',
        status: _status,
        stepsPassed: _stepsPassed.round(),
        stepsTotal: 10,
        note: _noteController.text.trim(),
      ),
    );
  }
}

class LeadsPage extends StatelessWidget {
  const LeadsPage({super.key, required this.store});

  final OperationsStore store;

  @override
  Widget build(BuildContext context) {
    final totalValue = store.leads.fold<int>(
      0,
      (sum, lead) => sum + lead.value,
    );

    return Scaffold(
      key: const ValueKey('leads'),
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        children: [
          _SectionHeader(
            title: 'Lead management',
            subtitle: 'Pipeline value MAD ${totalValue.toString()}',
          ),
          const SizedBox(height: 12),
          if (store.leads.isEmpty)
            const EmptyState(
              icon: Icons.handshake_outlined,
              title: 'No leads stored',
              text: 'Add prospects and next actions for daily follow-up.',
            )
          else
            ...store.leads.map(
              (lead) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LeadCard(lead: lead),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<LeadRecord>(
            MaterialPageRoute<LeadRecord>(
              builder: (context) => const LeadFormPage(),
            ),
          );
          if (created != null) {
            store.addLead(created);
          }
        },
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('New lead'),
      ),
    );
  }
}

class LeadFormPage extends StatefulWidget {
  const LeadFormPage({super.key});

  @override
  State<LeadFormPage> createState() => _LeadFormPageState();
}

class _LeadFormPageState extends State<LeadFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _contactController = TextEditingController();
  final _actionController = TextEditingController();
  final _valueController = TextEditingController(text: '0');
  String _stage = 'Qualified';

  @override
  void dispose() {
    _companyController.dispose();
    _contactController.dispose();
    _actionController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New lead')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(labelText: 'Company'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactController,
              decoration: const InputDecoration(labelText: 'Contact'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _stage,
              items: const [
                DropdownMenuItem(value: 'Qualified', child: Text('Qualified')),
                DropdownMenuItem(value: 'Proposal', child: Text('Proposal')),
                DropdownMenuItem(value: 'Won', child: Text('Won')),
              ],
              decoration: const InputDecoration(labelText: 'Stage'),
              onChanged: (value) =>
                  setState(() => _stage = value ?? 'Qualified'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _valueController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Estimated value'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _actionController,
              minLines: 3,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Next action'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save lead'),
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      LeadRecord(
        id: _newId('lead'),
        company: _companyController.text.trim(),
        contact: _contactController.text.trim(),
        stage: _stage,
        nextAction: _actionController.text.trim(),
        value: int.tryParse(_valueController.text.trim()) ?? 0,
      ),
    );
  }
}

class ShipmentsPage extends StatelessWidget {
  const ShipmentsPage({super.key, required this.store});

  final OperationsStore store;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('shipments'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        const _SectionHeader(
          title: 'Shipment log',
          subtitle: 'Dispatch status and carton counts',
        ),
        const SizedBox(height: 12),
        if (store.shipments.isEmpty)
          const EmptyState(
            icon: Icons.local_shipping_outlined,
            title: 'No shipment logs',
            text: 'Shipment records will appear here as they are added.',
          )
        else
          ...store.shipments.map(
            (shipment) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ShipmentCard(shipment: shipment),
            ),
          ),
      ],
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.store});

  final OperationsStore store;

  @override
  Widget build(BuildContext context) {
    final settings = store.settings;

    return ListView(
      key: const ValueKey('settings'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        const _SectionHeader(
          title: 'Settings and privacy',
          subtitle: 'Local controls for this device',
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Compact dashboard'),
                subtitle: const Text('Reduce spacing for morning reviews.'),
                value: settings.compactDashboard,
                onChanged: (value) => store.updateSettings(
                  settings.copyWith(compactDashboard: value),
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Show risk tags'),
                subtitle: const Text(
                  'Highlight delayed shipments and heavy allocations.',
                ),
                value: settings.riskTags,
                onChanged: (value) =>
                    store.updateSettings(settings.copyWith(riskTags: value)),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Handoff notes'),
                subtitle: const Text(
                  'Keep local notes visible on operation cards.',
                ),
                value: settings.handoffNotes,
                onChanged: (value) => store.updateSettings(
                  settings.copyWith(handoffNotes: value),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const InfoPanel(
          title: 'On-device storage',
          text:
              'Quality checks, resources, leads, shipments, and preferences stay on this device. The app does not use accounts, cloud sync, analytics, advertising IDs, location, contacts, microphone, photos, payments, or health data.',
          icon: Icons.lock_outline,
        ),
        const SizedBox(height: 12),
        const InfoPanel(
          title: 'Support contact',
          text: 'ROUSTAN ROBERT\nsupport@roustanrobert.com',
          icon: Icons.support_agent_outlined,
        ),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class ResourceCard extends StatelessWidget {
  const ResourceCard({super.key, required this.resource});

  final ResourceAllocation resource;

  @override
  Widget build(BuildContext context) {
    final color = resource.loadPercent >= 85
        ? const Color(0xFF9D3D2E)
        : Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    resource.team,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Chip(
                  label: Text('${resource.loadPercent}%'),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide.none,
                  backgroundColor: color.withValues(alpha: 0.12),
                  labelStyle: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Text(
              '${resource.asset} - ${resource.shift}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: resource.loadPercent / 100,
                color: color,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Text(resource.note),
          ],
        ),
      ),
    );
  }
}

class QualityCard extends StatelessWidget {
  const QualityCard({super.key, required this.check, required this.onTap});

  final QualityCheck check;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      check.area,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  StatusChip(status: check.status),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '${check.batch} - ${check.due}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: check.completion,
                minHeight: 7,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 8),
              Text(check.note, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class LeadCard extends StatelessWidget {
  const LeadCard({super.key, required this.lead});

  final LeadRecord lead;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    lead.company,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                StatusChip(status: lead.stage),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${lead.contact} - MAD ${lead.value}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.next_plan_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(lead.nextAction)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ShipmentCard extends StatelessWidget {
  const ShipmentCard({super.key, required this.shipment});

  final ShipmentLog shipment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: _statusColor(
                shipment.status,
              ).withValues(alpha: 0.12),
              foregroundColor: _statusColor(shipment.status),
              child: const Icon(Icons.local_shipping_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          shipment.reference,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      StatusChip(status: shipment.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(shipment.destination),
                  const SizedBox(height: 4),
                  Text(
                    '${shipment.cartons} cartons - ETA ${shipment.eta}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PriorityCard extends StatelessWidget {
  const PriorityCard({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(text),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProgressPanel extends StatelessWidget {
  const ProgressPanel({
    super.key,
    required this.title,
    required this.progress,
    required this.footer,
  });

  final String title;
  final double progress;
  final String footer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 10),
            Text(footer),
          ],
        ),
      ),
    );
  }
}

class InfoPanel extends StatelessWidget {
  const InfoPanel({
    super.key,
    required this.title,
    required this.text,
    required this.icon,
  });

  final String title;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(text),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_outlined, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Current status: $status',
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Chip(
      label: Text(status),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'Passed':
    case 'Won':
    case 'Ready':
      return const Color(0xFF2C6D63);
    case 'Delayed':
    case 'Open':
      return const Color(0xFF9D3D2E);
    case 'In review':
    case 'Proposal':
    case 'In transit':
      return const Color(0xFFB77838);
    default:
      return const Color(0xFF24423E);
  }
}
