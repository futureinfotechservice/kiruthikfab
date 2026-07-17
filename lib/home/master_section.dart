// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/master/agent/agent_master_screen.dart';
import '../screens/master/area/area_master_screen.dart';
import '../screens/master/delivery_partner/delivery_partner_master.dart';
import '../screens/master/district/district.dart';
import '../screens/master/incharge/incharge_master_screen.dart';
import '../screens/master/interest/customer_interest_master_screen.dart';
import '../screens/master/inventory/inventory_master.dart';
import '../screens/master/model/model_master_screen.dart';
import '../screens/master/occupation/occupation_master_screen.dart';
import '../screens/master/product/product_master_screen.dart';
import '../screens/master/refer/refer_master_screen.dart';
import '../screens/master/relation/relation_master_screen.dart';
import '../screens/master/salesperson/salesperson_master_screen.dart';
import '../screens/master/size/size_master_screen.dart';
import '../screens/master/source/source_list_screen.dart';
import '../screens/master/source_mode/source_mode.dart';
import '../screens/master/state/state_master.dart';
import '../screens/master/unit/unit_master_screen.dart';
import '../screens/navigation_provider.dart';

class MasterSectionScreen extends StatefulWidget {
  final int initialSubIndex;
  final ValueChanged<int>? onSubIndexChanged;

  const MasterSectionScreen({
    super.key,
    this.initialSubIndex = 0,
    this.onSubIndexChanged,
  });

  @override
  State<MasterSectionScreen> createState() => MasterSectionScreenState();
}

class MasterSectionScreenState extends State<MasterSectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Widget _buildSelectedScreen(int index) {
    switch (index) {
      case 0:
        return const SourceListScreen();
      case 1:
        return const ProductMasterScreen();
      case 2:
        return const ModelMasterScreen();
      case 3:
        return const SizeMasterScreen();
      case 4:
        return const UnitMasterScreen();
      case 5:
        return const AreaMasterScreen();
      case 6:
        return const ReferMasterScreen();
      case 7:
        return const InchargeMasterScreen();
      case 8:
        return const AgentMasterScreen();
      case 9:
        return const SalesPersonMasterScreen();
      case 10:
        return const OccupationMasterScreen();
      case 11:
        return const CustomerInterestMasterScreen();
      case 12:
        return const RelationMasterScreen();
      case 13:
        return const SourceModeMasterScreen();
      case 14:
        return const DistrictMasterScreen();
      case 15:
        return const StateMasterScreen();
      case 16:
        return const DeliveryPartnerMasterScreen();
      case 17:
        return const InventoryMaster();
      default:
        return const SizedBox();
    }
  }

  @override
  void initState() {
    super.initState();
    final navProvider = context.read<NavigationProvider>();

    // init();
    // masterSubIndex = widget.initialSubIndex;
    _tabController = TabController(
      length: 18,
      vsync: this,
      initialIndex: navProvider.masterSubIndex,
    );

    _tabController.addListener(_handleTabChange);
  }

  /* Future<void> init() async {
    final navProvider = context.read<NavigationProvider>();

    navProvider.updateIndex(
      selectedIndex: navProvider.selectedIndex,
      masterSubIndex: widget.initialSubIndex,
    );
  }
*/
  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      final navProvider = context.read<NavigationProvider>();
      navProvider.updateIndex(
        selectedIndex: navProvider.selectedIndex,
        masterSubIndex: _tabController.index,
      );
      // setState(() {
      //   masterSubIndex = _tabController.index;
      // });

      widget.onSubIndexChanged?.call(navProvider.masterSubIndex);
    }
  }

  void switchToSubScreen(int subIndex) {
    final navProvider = context.read<NavigationProvider>();
    navProvider.updateIndex(
      selectedIndex: navProvider.selectedIndex,
      masterSubIndex: subIndex,
    );
    // setState(() {
    //   masterSubIndex = subIndex;
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
  void didUpdateWidget(covariant MasterSectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // final navProvider = context.read<NavigationProvider>();

    if (_tabController.index != widget.initialSubIndex) {
      _tabController.animateTo(widget.initialSubIndex);
    }
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
                Tab(icon: Icon(Icons.person), text: 'Customer'),
                Tab(icon: Icon(Icons.shopping_bag), text: 'Product'),
                Tab(icon: Icon(Icons.model_training), text: 'Model'),
                Tab(icon: Icon(Icons.straighten), text: 'Size'),
                Tab(icon: Icon(Icons.scale), text: 'Unit'),
                Tab(icon: Icon(Icons.map), text: 'Area'),
                Tab(icon: Icon(Icons.people_alt), text: 'Refer'),
                Tab(icon: Icon(Icons.manage_accounts), text: 'Incharge'),
                Tab(icon: Icon(Icons.business_center), text: 'Agent'),
                Tab(icon: Icon(Icons.person_add), text: 'Sales Person'),
                Tab(icon: Icon(Icons.work), text: 'Occupation'),
                Tab(icon: Icon(Icons.interests), text: 'Interest'),
                Tab(icon: Icon(Icons.people_outline), text: 'Relation'),
                Tab(icon: Icon(Icons.source), text: 'Source Mode'),
                Tab(icon: Icon(Icons.location_city), text: 'District Master'),
                Tab(
                  icon: Icon(Icons.location_on_outlined),
                  text: 'State Master',
                ),
                Tab(
                  icon: Icon(Icons.delivery_dining),
                  text: 'Delivery Partner',
                ),
                Tab(icon: Icon(Icons.inventory), text: 'Inventory'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                SourceListScreen(),
                ProductMasterScreen(),
                ModelMasterScreen(),
                SizeMasterScreen(),
                UnitMasterScreen(),
                AreaMasterScreen(),
                ReferMasterScreen(),
                InchargeMasterScreen(),
                AgentMasterScreen(),
                SalesPersonMasterScreen(),
                OccupationMasterScreen(),
                CustomerInterestMasterScreen(),
                RelationMasterScreen(),
                SourceModeMasterScreen(),
                DistrictMasterScreen(),
                StateMasterScreen(),
                DeliveryPartnerMasterScreen(),
                InventoryMaster(),
              ],
            ),
          ),
        ],
      );
    } else {
      // Web: Show selected screen
      return _buildSelectedScreen(navProvider.masterSubIndex);
    }
  }
}
