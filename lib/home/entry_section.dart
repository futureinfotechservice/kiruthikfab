import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/entry/call_register_screen.dart';
import '../screens/entry/delivery_management_screen.dart';
import '../screens/entry/invoice_list.dart';
import '../screens/entry/kyc_list_screen.dart';
import '../screens/navigation_provider.dart';

class EntrySectionScreen extends StatefulWidget {
  final int initialSubIndex;
  final ValueChanged<int>? onSubIndexChanged;

  const EntrySectionScreen({
    super.key,
    this.initialSubIndex = 0,
    this.onSubIndexChanged,
  });

  @override
  State<EntrySectionScreen> createState() => EntrySectionScreenState();
}

class EntrySectionScreenState extends State<EntrySectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final navProvider = context.read<NavigationProvider>();
    // init();
    // entrySubIndex = widget.initialSubIndex;
    _tabController = TabController(
      length: 4, // Updated to 1 tab
      vsync: this,
      initialIndex: navProvider.entrySubIndex,
    );

    _tabController.addListener(_handleTabChange);
  }

  // Future<void> init() async {
  //   final navProvider = context.read<NavigationProvider>();
  //   navProvider.updateIndex(
  //     selectedIndex: navProvider.selectedIndex,
  //     entrySubIndex: widget.initialSubIndex,
  //   );
  // }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      final navProvider = context.read<NavigationProvider>();
      navProvider.updateIndex(
        selectedIndex: navProvider.selectedIndex,
        entrySubIndex: _tabController.index,
      );
      // setState(() {
      //   entrySubIndex = _tabController.index;
      // });

      widget.onSubIndexChanged?.call(navProvider.entrySubIndex);
    }
  }

  void switchToSubScreen(int subIndex) {
    final navProvider = context.read<NavigationProvider>();
    navProvider.updateIndex(
      selectedIndex: navProvider.selectedIndex,
      entrySubIndex: subIndex,
    );
    // setState(() {
    //   entrySubIndex = subIndex;
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
  void didUpdateWidget(covariant EntrySectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_tabController.index != widget.initialSubIndex) {
      _tabController.animateTo(widget.initialSubIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;
    final navProvider = context.read<NavigationProvider>();
    //
    // if (_tabController.index != navProvider.entrySubIndex) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     if (mounted) {
    //       _tabController.animateTo(navProvider.entrySubIndex);
    //     }
    //   });
    // }
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
                Tab(icon: Icon(Icons.receipt), text: 'Bill Entry'),
                Tab(icon: Icon(Icons.pages_outlined), text: 'KYC Entry'),
                Tab(icon: Icon(Icons.call), text: 'Call Register'),
                Tab(
                  icon: Icon(Icons.delivery_dining),
                  text: 'Delivery Management',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const InvoiceListPage(),
                const KYCListScreen(),
                const CallRegisterScreen(),
                const DeliveryManagementListScreen(),
              ],
            ),
          ),
        ],
      );
    } else {
      // Web: Show selected screen
      return IndexedStack(
        index: navProvider.entrySubIndex,
        children: const [
          InvoiceListPage(),
          KYCListScreen(),
          CallRegisterScreen(),
          DeliveryManagementListScreen(),
        ],
      );
    }
  }
}
