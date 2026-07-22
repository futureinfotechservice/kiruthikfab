import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../indigator/main.dart';
import '../../models/dashboard_model.dart';
import '../../services/dashboard_api_service.dart';
import '../entry/add_call_register_screen.dart';
import '../entry/delivery_management.dart';
import '../navigation_provider.dart';

class AppColors {
  static const background = Color(0xFFF6F7FB);
  static const surface = Colors.white;
  static const border = Color(0xFFEAECF0);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);

  static const indigo = Color(0xFF4F46E5);
  static const indigoLight = Color(0xFFEEF2FF);
  static const indigoDark = Color(0xFF3730A3);

  static const emerald = Color(0xFF10B981);
  static const emeraldLight = Color(0xFFECFDF5);
  static const amber = Color(0xFFF59E0B);
  static const amberLight = Color(0xFFFFFBEB);
  static const rose = Color(0xFFF43F5E);
  static const roseLight = Color(0xFFFFF1F2);
  static const violet = Color(0xFF8B5CF6);
  static const violetLight = Color(0xFFF5F3FF);
  static const sky = Color(0xFF0EA5E9);
  static const skyLight = Color(0xFFF0F9FF);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final TextEditingController _deliverySearchController =
      TextEditingController();
  final TextEditingController _callSearchController = TextEditingController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  int _selectedDeliveryFilter = 0;
  final List<String> _deliveryFilters = ['All', 'Pending', 'Delivered'];

  List<SalesModel> _salespersons = [];

  List<DeliveryDashboardModel> deliveries = [];

  List<CallDashboardModel> callRecords = [];

  List<DeliveryDashboardModel> _filteredDeliveries = [];
  List<CallDashboardModel> _filteredCallRecords = [];
  DashboardModel counts = DashboardModel(
    source: '0',
    called: '0',
    notCalled: '0',
    kyc: '0',
    value: '0',
  );
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _fadeController.forward();
    init();
  }

  Future<void> loadDelivery() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final companyId = int.tryParse(prefs.getString('companyid') ?? '') ?? 0;
    final userType = prefs.getString('user_type')?.toUpperCase();
    final id = prefs.getString('id');
    final deliveryName = _deliverySearchController.text.trim();

    deliveries = await DashboardApiService().fetchDeliveryList(
      companyId.toString(),
      deliveryName,
      userType!,
      id!,
    );

    setState(() {
      _filteredDeliveries = List.from(deliveries);
    });
  }

  Future<void> loadCall() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final companyId = int.tryParse(prefs.getString('companyid') ?? '') ?? 0;
    final userType = prefs.getString('user_type')?.toUpperCase();
    final id = prefs.getString('id');
    final deliveryName = _callSearchController.text.trim();

    callRecords = await DashboardApiService().fetchCallList(
      companyId.toString(),
      deliveryName,
      userType!,
      id!,
    );

    setState(() {
      _filteredCallRecords = List.from(callRecords);
    });
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final companyId = int.tryParse(prefs.getString('companyid') ?? '') ?? 0;
      final userType = prefs.getString('user_type')?.toUpperCase() ?? '';
      final id = prefs.getString('id') ?? '';
      final name = prefs.getString('name') ?? '';

      final deliveryName = userType == 'ADMIN' ? '' : name;

      final res = await Future.wait([
        DashboardApiService().fetchRecords(companyId, userType, id),
        DashboardApiService().fetchAllSalesPerson(
          companyId.toString(),
          userType,
          id,
        ),
        DashboardApiService().fetchDeliveryList(
          companyId.toString(),
          deliveryName,
          userType,
          id,
        ),
        DashboardApiService().fetchCallList(
          companyId.toString(),
          deliveryName,
          userType,
          id,
        ),
      ]);

      counts = res[0] as DashboardModel;
      _salespersons = res[1] as List<SalesModel>;
      deliveries = res[2] as List<DeliveryDashboardModel>;
      callRecords = res[3] as List<CallDashboardModel>;
      _filteredDeliveries = List.from(deliveries);
      _filteredCallRecords = List.from(callRecords);

      _deliverySearchController.addListener(_filterDeliveries);
      _callSearchController.addListener(_filterCallRecords);

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Init Error: $e');

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _deliverySearchController.dispose();
    _callSearchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _filterDeliveries() {
    final query = _deliverySearchController.text.toLowerCase();
    setState(() {
      _filteredDeliveries = deliveries.where((d) {
        final matchesQuery =
            d.customerName.toLowerCase().contains(query) ||
            d.entryNo.toLowerCase().contains(query) ||
            d.address.toLowerCase().contains(query);
        final filter = _deliveryFilters[_selectedDeliveryFilter];
        final matchesFilter = filter == 'All' || d.status == filter;
        return matchesQuery && matchesFilter;
      }).toList();
    });
  }

  void _applyDeliveryFilter(int index) {
    setState(() => _selectedDeliveryFilter = index);
    _filterDeliveries();
  }

  void _filterCallRecords() {
    final query = _callSearchController.text.toLowerCase();
    setState(() {
      _filteredCallRecords = callRecords.where((r) {
        final matchesQuery =
            r.sourceName.toLowerCase().contains(query) ||
            r.entryNo.toLowerCase().contains(query) ||
            r.callByName.toLowerCase().contains(query) ||
            r.mobile.contains(query);
        return matchesQuery;
      }).toList();
    });
  }

  // void _showSnackBar(String message) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(message),
  //       behavior: SnackBarBehavior.floating,
  //       backgroundColor: AppColors.textPrimary,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  //       margin: const EdgeInsets.all(16),
  //       duration: const Duration(seconds: 2),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isMedium = screenWidth < 900 && screenWidth > 600;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: isLoading
          ? Center(child: CircularWaveProgress())
          : FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 12 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(),
                    SizedBox(height: isMobile ? 16 : 20),
                    _buildStatStrip(isMobile || isMedium),
                    SizedBox(height: isMobile ? 16 : 20),
                    _buildSalespersonRecords(isMobile),
                    SizedBox(height: isMobile ? 16 : 20),
                    _buildDeliveryList(isMobile),
                    SizedBox(height: isMobile ? 16 : 20),
                    _buildCallRecords(isMobile),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Page Header ───────────────────────────────────────────────────────────
  Widget _buildPageHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monday, 29 June 2026',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: init,
          icon: const Icon(Icons.refresh, color: Colors.black),
        ),
        // _PillButton(
        //   label: 'Export',
        //   icon: Icons.download_rounded,
        //   onTap: () => _showSnackBar('Exporting report…'),
        // ),
        // const SizedBox(width: 8),
        // _PillButton(
        //   label: 'Filter',
        //   icon: Icons.tune_rounded,
        //   onTap: () => _showSnackBar('Filter options'),
        // ),
      ],
    );
  }

  // ─── Stat Strip ────────────────────────────────────────────────────────────
  Widget _buildStatStrip(bool isMobile) {
    // Ensure counts is not empty
    if (counts.source == '' || counts.source == '0') {
      return _buildEmptyState();
    }

    // Build stat models with better null safety
    final statModels = [
      _StatModel(
        onTap: () {
          final navProvider = Provider.of<NavigationProvider>(
            context,
            listen: false,
          );
          navProvider.updateIndex(
            selectedIndex: 1,
            reportSubIndex: 0,
            entrySubIndex: 0,
            masterSubIndex: 0,
          );
        },
        'Source',
        counts.source,
        Icons.layers_outlined,
        AppColors.indigo,
        AppColors.indigoLight,
        'Total sources available',
      ),
      _StatModel(
        onTap: () {
          final navProvider = Provider.of<NavigationProvider>(
            context,
            listen: false,
          );
          navProvider.updateIndex(
            selectedIndex: 2,
            entrySubIndex: 3,
            masterSubIndex: 0,
            reportSubIndex: 0,
          );
        },
        'Called',
        counts.called,
        Icons.phone_outlined,
        AppColors.emerald,
        AppColors.emeraldLight,
        'Number of calls made',
      ),
      _StatModel(
        onTap: () {
          final navProvider = Provider.of<NavigationProvider>(
            context,
            listen: false,
          );
          navProvider.updateIndex(
            selectedIndex: 2,
            entrySubIndex: 3,
            masterSubIndex: 0,
            reportSubIndex: 0,
          );
        },
        'Not Called',
        counts.notCalled,
        Icons.phone_missed_outlined,
        AppColors.amber,
        AppColors.amberLight,
        'Pending calls to make',
      ),
      _StatModel(
        onTap: () {
          final navProvider = Provider.of<NavigationProvider>(
            context,
            listen: false,
          );
          navProvider.updateIndex(
            selectedIndex: 2,
            entrySubIndex: 2,
            masterSubIndex: 0,
            reportSubIndex: 0,
          );
        },
        'KYC Filled',
        counts.kyc,
        Icons.verified_outlined,
        AppColors.violet,
        AppColors.violetLight,
        'KYC completed',
      ),
      _StatModel(
        onTap: () {
          final navProvider = Provider.of<NavigationProvider>(
            context,
            listen: false,
          );
          navProvider.updateIndex(
            selectedIndex: 2,
            entrySubIndex: 1,
            reportSubIndex: 0,
            masterSubIndex: 0,
          );
        },
        'Total Value',
        counts.value,
        Icons.currency_rupee_rounded,
        AppColors.sky,
        AppColors.skyLight,
        'Total invoice value',
      ),
    ];

    if (counts.source == '' || counts.source == '0') {
      return _buildEmptyState();
    }

    return isMobile
        ? _buildMobileLayout(statModels)
        : _buildDesktopLayout(statModels);
  }

  Widget _buildMobileLayout(List<_StatModel> stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(stat: stats[0])),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(stat: stats[1])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _StatCard(stat: stats[2])),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(stat: stats[3])),
          ],
        ),
        const SizedBox(height: 10),
        if (stats.length > 4) _StatCard(stat: stats[4], fullWidth: true),
      ],
    );
  }

  Widget _buildDesktopLayout(List<_StatModel> stats) {
    return Row(
      children: stats
          .map(
            (s) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: stats.indexOf(s) == stats.length - 1 ? 0 : 12,
                ),
                child: _StatCard(stat: s),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Center(
        child: Text(
          'No statistics available',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }

  // ─── Salesperson Records ───────────────────────────────────────────────────
  Widget _buildSalespersonRecords(bool isMobile) {
    return _SectionCard(
      title: 'Salesperson Records',
      trailing: _PillButton(
        label: 'View all',
        icon: Icons.arrow_forward_rounded,
        onTap: () {
          final navProvider = Provider.of<NavigationProvider>(
            context,
            listen: false,
          );
          navProvider.updateIndex(selectedIndex: 3, reportSubIndex: 0);

          // _reportSectionKey.currentState?.switchToSubScreen(0);
        },
      ),
      child: Column(
        children: _salespersons
            .map((p) => _SalespersonRow(person: p, isMobile: isMobile))
            .toList(),
      ),
    );
  }

  // ─── Delivery List ─────────────────────────────────────────────────────────
  Widget _buildDeliveryList(bool isMobile) {
    return _SectionCard(
      title: 'Delivery List',
      trailing: Row(
        children: [
          _PillButton(
            label: '+ New',
            icon: null,
            color: AppColors.indigo,
            textColor: Colors.white,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeliveryManagement(billNO: '0'),
                ),
              );
            },
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          Row(
            children: [
              Expanded(
                child: _SearchField(
                  controller: _deliverySearchController,
                  hint: 'Search by ID, customer, area…',
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  _deliverySearchController.clear();
                  loadDelivery();
                },
                child: const Text('Clear'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: loadDelivery,
                child: const Text('Search'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_deliveryFilters.length, (i) {
                final selected = _selectedDeliveryFilter == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: _deliveryFilters[i],
                    selected: selected,
                    onTap: () => _applyDeliveryFilter(i),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          if (_filteredDeliveries.isEmpty)
            _EmptyState(message: 'No deliveries match your search.')
          else
            ...(_filteredDeliveries.map((d) => _DeliveryCard(delivery: d))),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                final navProvider = Provider.of<NavigationProvider>(
                  context,
                  listen: false,
                );
                navProvider.updateIndex(selectedIndex: 2, entrySubIndex: 3);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.indigo,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: const Text('View all →'),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Call Records ──────────────────────────────────────────────────────────
  Widget _buildCallRecords(bool isMobile) {
    return _SectionCard(
      title: 'Call Records',
      trailing: _PillButton(
        label: '+ Add',
        icon: null,
        color: AppColors.indigo,
        textColor: Colors.white,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddCallRegisterScreen()),
          );
        },
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SearchField(
                  controller: _callSearchController,
                  hint: 'Search by name, ID, mobile…',
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  _callSearchController.clear();
                  loadCall();
                },
                child: const Text('Clear'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: loadCall,
                child: const Text('Search'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_filteredCallRecords.isEmpty)
            _EmptyState(message: 'No records match your search.')
          else
            ..._filteredCallRecords.map((r) => _CallRecordCard(record: r)),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                final navProvider = Provider.of<NavigationProvider>(
                  context,
                  listen: false,
                );
                navProvider.updateIndex(selectedIndex: 2, entrySubIndex: 2);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.indigo,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: const Text('View all →'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _StatModel {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String sub;
  final GestureTapCallback onTap;

  const _StatModel(
    this.label,
    this.value,
    this.icon,
    this.color,
    this.bgColor,
    this.sub, {
    required this.onTap,
  });
}

class _StatCard extends StatelessWidget {
  final _StatModel stat;
  final bool fullWidth;

  const _StatCard({required this.stat, this.fullWidth = false});

  String formatAmount(String val) {
    if (val.isEmpty || val == 'null') return '0';
    try {
      final value = num.parse(val);
      if (value >= 10000000) {
        return '${(value / 10000000).toStringAsFixed((value / 10000000) % 1 == 0 ? 0 : 1)} CR';
      } else if (value >= 100000) {
        return '${(value / 100000).toStringAsFixed((value / 100000) % 1 == 0 ? 0 : 1)} L';
      } else if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed((value / 1000) % 1 == 0 ? 0 : 1)} K';
      } else {
        return value.toString();
      }
    } catch (e) {
      return '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: stat.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: stat.bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: stat.color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: stat.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(stat.icon, color: stat.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatAmount(stat.value),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    stat.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: stat.color,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    stat.sub,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
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

class _SalespersonRow extends StatelessWidget {
  final SalesModel person;
  final bool isMobile;

  const _SalespersonRow({required this.person, required this.isMobile});

  Color get _perfColor {
    final p = person.efficiency;
    if (p >= 0.8) return AppColors.emerald;
    if (p >= 0.6) return AppColors.amber;
    return AppColors.rose;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.indigoLight,
            child: Text(
              person.name[0],
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.indigo,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                // Mini stats row
                Wrap(
                  spacing: 12,
                  children: [
                    _InlineStat('Calls', person.totalCalls.toString()),
                    _InlineStat('Approach', person.approach.toString()),
                    _InlineStat('KYC', person.kycFilled.toString()),
                    _InlineStat('Time', '${person.totalTime}m'),
                  ],
                ),
                const SizedBox(height: 6),
                // Performance bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: person.efficiency,
                          minHeight: 5,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(_perfColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${((person.efficiency) * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _perfColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _PerformanceBadge(value: person.efficiency),
        ],
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  final String label;
  final String value;

  const _InlineStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceBadge extends StatelessWidget {
  final double value;

  const _PerformanceBadge({required this.value});

  String get _rank {
    if (value >= 0.8) return '★';
    if (value >= 0.6) return '▲';
    return '▼';
  }

  Color get _color {
    if (value >= 0.8) return AppColors.emerald;
    if (value >= 0.6) return AppColors.amber;
    return AppColors.rose;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(_rank, style: TextStyle(fontSize: 16, color: _color)),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final DeliveryDashboardModel delivery;

  const _DeliveryCard({required this.delivery});

  bool get _isDelivered => delivery.status.toLowerCase() == 'delivered';

  @override
  Widget build(BuildContext context) {
    final color = _isDelivered ? AppColors.emerald : AppColors.amber;
    final bgColor = _isDelivered
        ? AppColors.emeraldLight
        : AppColors.amberLight;
    final address = delivery.address;
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Status dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            delivery.entryNo,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          Text(
                            delivery.customerName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Text(
                            delivery.entryNo,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '·  ${delivery.customerName}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 3),

                    Text(
                      address.length > 30
                          ? '${address.substring(0, 25)}...'
                          : address,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      delivery.date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              delivery.status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CallRecordCard extends StatelessWidget {
  final CallDashboardModel record;

  const _CallRecordCard({required this.record});

  // Color _tagColor(String tag) {
  //   switch (tag) {
  //     case 'Hot':
  //       return AppColors.rose;
  //     case 'Warm':
  //       return AppColors.amber;
  //     default:
  //       return AppColors.textMuted;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    // final tag = record['tag'] as String? ?? '';
    // final tc = _tagColor(tag);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.indigoLight,
            child: Text(
              record.sourceName[0],
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.indigo,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      record.sourceName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    // const SizedBox(width: 8),
                    // if (tag.isNotEmpty)
                    //   Container(
                    //     padding: const EdgeInsets.symmetric(
                    //       horizontal: 6,
                    //       vertical: 2,
                    //     ),
                    //     decoration: BoxDecoration(
                    //       color: tc.withValues(alpha: 0.12),
                    //       borderRadius: BorderRadius.circular(4),
                    //     ),
                    //     child: Text(
                    //       tag,
                    //       style: TextStyle(
                    //         fontSize: 10,
                    //         fontWeight: FontWeight.w700,
                    //         color: tc,
                    //         letterSpacing: 0.3,
                    //       ),
                    //     ),
                    //   ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      record.entryNo,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.person,
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      record.callByName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.phone_outlined,
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      record.mobile,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Call action
          _IconAction(
            icon: Icons.phone_outlined,
            color: AppColors.emerald,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;

  const _PillButton({
    required this.label,
    this.icon,
    required this.onTap,
    this.color = AppColors.background,
    this.textColor = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: icon != null ? 10 : 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color == AppColors.indigo
                ? Colors.transparent
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: textColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _SearchField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 18,
          color: AppColors.textMuted,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.indigo, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        isDense: true,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.indigo : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.indigo : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 36, color: AppColors.textMuted),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class NumberFormatter {
  static String formatWithSuffix(
    num value, {
    bool includeCurrency = true,
    String currencySymbol = '₹',
    bool alwaysShowDecimal = false,
    int decimalPlaces = 1,
  }) {
    final double numValue = value.toDouble();
    if (numValue < 0) {
      return '-${formatWithSuffix(numValue.abs(), includeCurrency: includeCurrency, currencySymbol: currencySymbol)}';
    }
    String suffix = '';
    double displayValue = numValue;
    if (numValue >= 10000000) {
      displayValue = numValue / 10000000;
      suffix = 'CR';
    } else if (numValue >= 100000) {
      displayValue = numValue / 100000;
      suffix = 'L';
    } else if (numValue >= 1000) {
      displayValue = numValue / 1000;
      suffix = 'K';
    }
    String formattedValue;
    if (displayValue % 1 == 0 && !alwaysShowDecimal) {
      formattedValue = displayValue.toInt().toString();
    } else {
      formattedValue = displayValue.toStringAsFixed(decimalPlaces);
    }
    final result = '$formattedValue$suffix';
    return includeCurrency ? '$currencySymbol$result' : result;
  }
}
