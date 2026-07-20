// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kiruthikfab/screens/navigation_provider.dart';
import 'package:kiruthikfab/screens/reports/agent_refer_report/agent_refer_report.dart';
import 'package:kiruthikfab/screens/reports/product_based_sales_report/product_based_sales_report.dart';
import 'package:kiruthikfab/screens/reports/salesperson_report.dart';
import 'package:kiruthikfab/screens/reports/source_followup_report.dart';
import 'package:kiruthikfab/screens/reports/stock_ledger/stock_ledger_page.dart';
import 'package:kiruthikfab/screens/reports/stock_statement/stock_statement_page.dart';
import 'package:provider/provider.dart';

class ReportSectionScreen extends StatefulWidget {
  final int initialSubIndex;
  final ValueChanged<int>? onSubIndexChanged;

  const ReportSectionScreen({
    super.key,
    this.initialSubIndex = 0,
    this.onSubIndexChanged,
  });

  @override
  State<ReportSectionScreen> createState() => ReportSectionScreenState();
}

class ReportSectionScreenState extends State<ReportSectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Widget _buildSelectedScreen(int index) {
    switch (index) {
      case 0:
        return const SalespersonReport();
      case 1:
        return const ProductBasedSalesReport();
      case 2:
        return const SourceFollowupReport();
      case 3:
        return const StockLedgerPage();
      case 4:
        return const StockStatementPage();
      case 5:
        return const AgentReferReport();
      default:
        return const SizedBox();
    }
  }

  @override
  void initState() {
    super.initState();
    final navProvider = context.read<NavigationProvider>();
    //init();
    // reportSubIndex = widget.initialSubIndex;
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: navProvider.reportSubIndex,
    );

    _tabController.addListener(_handleTabChange);
  }

  // Future<void> init() async {
  //   final navProvider = context.read<NavigationProvider>();
  //
  //   navProvider.updateIndex(
  //     selectedIndex: navProvider.selectedIndex,
  //     reportSubIndex: widget.initialSubIndex,
  //   );
  // }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      final navProvider = context.read<NavigationProvider>();

      navProvider.updateIndex(
        selectedIndex: navProvider.selectedIndex,
        reportSubIndex: _tabController.index,
      );

      widget.onSubIndexChanged?.call(navProvider.reportSubIndex);
    }
  }

  void switchToSubScreen(int subIndex) {
    final navProvider = context.read<NavigationProvider>();
    navProvider.updateIndex(
      selectedIndex: navProvider.selectedIndex,
      reportSubIndex: subIndex,
    );

    // setState(() {
    //   reportSubIndex = subIndex;
    // });

    if (_tabController.index != subIndex) {
      _tabController.animateTo(subIndex);
    }

    widget.onSubIndexChanged?.call(subIndex);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ReportSectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_tabController.index != widget.initialSubIndex) {
      _tabController.animateTo(widget.initialSubIndex);
    }
    // final navProvider = context.read<NavigationProvider>();
    //
    // if (_tabController.index != navProvider.reportSubIndex) {
    //   _tabController.animateTo(navProvider.reportSubIndex);
    // }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 768;
    final navProvider = context.read<NavigationProvider>();
    if (_tabController.index != widget.initialSubIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tabController.animateTo(widget.initialSubIndex);
        }
      });
    }
    if (!isWeb) {
      // Mobile: Show tabs at the top
      return Column(
        children: [
          Container(
            color: const Color(0xFF1E293B),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[400],
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(Icons.bar_chart), text: 'Performance Report'),
                Tab(
                  icon: Icon(Icons.stacked_bar_chart),
                  text: 'Product Sales Report',
                ),
                Tab(
                  icon: Icon(Icons.follow_the_signs),
                  text: 'Source Followup Report',
                ),
                Tab(icon: Icon(Icons.receipt_long), text: 'Stock ledger'),
                Tab(
                  icon: Icon(Icons.receipt_outlined),
                  text: 'Stock Statement',
                ),
                Tab(icon: Icon(Icons.real_estate_agent), text: 'Agent Refer'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SalespersonReport(),
                ProductBasedSalesReport(),
                SourceFollowupReport(),
                StockLedgerPage(),
                StockStatementPage(),
                AgentReferReport(),
              ],
            ),
          ),
        ],
      );
    } else {
      // Web: Show selected screen
      return _buildSelectedScreen(navProvider.reportSubIndex);
    }
  }
}
