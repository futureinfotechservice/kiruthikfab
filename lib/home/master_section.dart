import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/master/agent/agent_master_screen.dart';
import '../screens/master/area/area_master_screen.dart';
import '../screens/master/delivery_partner/delivery_partner_master.dart';
import '../screens/master/district/district.dart';
import '../screens/master/incharge/incharge_master_screen.dart';
import '../screens/master/interest/customer_interest_master_screen.dart';
import '../screens/master/model/model_master_screen.dart';
import '../screens/master/occupation/occupation_master_screen.dart';
import '../screens/master/product/product_master_screen.dart';
import '../screens/master/refer/refer_master_screen.dart';
import '../screens/master/relation/relation_master_screen.dart';
import '../screens/master/salesperson/salesperson_master_screen.dart';
import '../screens/master/size/size_master_screen.dart';
import '../screens/master/source/source_list_screen.dart';
import '../screens/master/source_mode/source_mode.dart';
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

  @override
  void initState() {
    super.initState();
    final navProvider = context.read<NavigationProvider>();

    // init();
    // masterSubIndex = widget.initialSubIndex;
    _tabController = TabController(
      length: 16,
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
    final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;
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
                Tab(icon: Icon(Icons.location_city), text: 'District Mode'),
                Tab(
                  icon: Icon(Icons.delivery_dining),
                  text: 'Delivery Partner',
                ),
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
                DeliveryPartnerMasterScreen(),
              ],
            ),
          ),
        ],
      );
    } else {
      // Web: Show selected screen
      return IndexedStack(
        index: navProvider.masterSubIndex,
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
          DeliveryPartnerMasterScreen(),
        ],
      );
    }
  }
}
