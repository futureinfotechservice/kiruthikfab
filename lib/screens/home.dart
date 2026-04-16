import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kiruthikfab/screens/product_master_screen.dart';
import 'package:kiruthikfab/screens/refer_master_screen.dart';
import 'package:kiruthikfab/screens/salesperson_master_screen.dart';
import 'package:kiruthikfab/screens/salesperson_report.dart';
import 'package:kiruthikfab/screens/size_master_screen.dart';
import 'package:kiruthikfab/screens/source_list_screen.dart';
import 'package:kiruthikfab/screens/unit_master_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'InvoiceEntryPage.dart';
import 'agent_master_screen.dart';
import 'area_master_screen.dart';
import 'call_register_screen.dart';
import 'customerlist_screen.dart';
import 'dashboardscreen.dart';
import 'delivery_management_screen.dart';
import 'incharge_master_screen.dart';
import 'invoice_list.dart';
import 'kyc_list_screen.dart';
import 'loginpage.dart';
import 'model_master_screen.dart';
import 'occupation_master_screen.dart';



class CustomerManagementApp extends StatefulWidget {
  const CustomerManagementApp({super.key});

  @override
  State<CustomerManagementApp> createState() => _CustomerManagementAppState();
}

class _CustomerManagementAppState extends State<CustomerManagementApp> {
  int _selectedIndex = 0;
  int _masterSubIndex =
  0; // 0: Customer Master, 1: Product Master, 2: Model Master, 3: Size Master, 4: Unit Master, 5: Area Master, 6: Refer Master, 7: Incharge Master, 8: Agent Master, 9: Sales Person Master, 10: Occupation Master
  int _entrySubIndex =
  0; // 0: Bill Entry
  int _reportSubIndex =
  0; // 0: Sales Report
  int _backupIndex = 5; // Add backup index
  // Create GlobalKey for MasterSectionScreen, EntrySectionScreen and ReportSectionScreen
  final GlobalKey<_MasterSectionScreenState> _masterSectionKey = GlobalKey();
  final GlobalKey<_EntrySectionScreenState> _entrySectionKey = GlobalKey();
  final GlobalKey<_ReportSectionScreenState> _reportSectionKey = GlobalKey();

  void _switchMasterScreen(int subIndex) {
    setState(() {
      _selectedIndex = 1;
      _masterSubIndex = subIndex;
    });

    if (_masterSectionKey.currentState != null) {
      _masterSectionKey.currentState!.setState(() {
        _masterSectionKey.currentState!.masterSubIndex = subIndex;
      });
    }
  }

  void _switchEntryScreen(int subIndex) {
    setState(() {
      _selectedIndex = 2;
      _entrySubIndex = subIndex;
    });

    if (_entrySectionKey.currentState != null) {
      _entrySectionKey.currentState!.setState(() {
        _entrySectionKey.currentState!.entrySubIndex = subIndex;
      });
    }
  }

  void _switchReportScreen(int subIndex) {
    setState(() {
      _selectedIndex = 3;
      _reportSubIndex = subIndex;
    });

    if (_reportSectionKey.currentState != null) {
      _reportSectionKey.currentState!.setState(() {
        _reportSectionKey.currentState!.reportSubIndex = subIndex;
      });
    }
  }

  // Method to show logout confirmation dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout Confirmation"),
          content: const Text("Are you sure you want to logout?"),
          actions: <Widget>[
            TextButton(
              child: const Text("No"),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
            ),
            TextButton(
              child: const Text("Yes", style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _performLogout(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _loadCounterremove() async {
    String id;
    String username;
    String password;
    String user_type;
    String companyid;
    String activestatus;
    String email;
    String companyname;
    String logourl;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      WidgetsFlutterBinding.ensureInitialized();

      prefs.clear();
      id = (prefs.remove('id')).toString();
      print('idempty' + id);
      username = (prefs.remove('username')).toString();
      print('username' + username);
      password = (prefs.remove('password')).toString();
      print('password' + password);
      email = (prefs.remove('email')).toString();
      print('email' + email);
      user_type = (prefs.remove('user_type')).toString();
      print('type' + user_type);
      companyid = (prefs.remove('companyid')).toString();
      print('companyid' + companyid);
      activestatus = (prefs.remove('activestatus')).toString();
      print('activestatus' + activestatus);

      companyname = (prefs.remove('companyname')).toString();
      print('companyname' + companyname);

      logourl = (prefs.remove('logourl')).toString();
      print('logourl' + logourl);
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // Method to perform logout
  void _performLogout(BuildContext context) {
    _loadCounterremove();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;

    if (isWeb) {
      return Scaffold(
        body: Row(
          children: [
            // Sidebar Navigation for Web
            _buildWebSidebar(),
            // Main Content Area
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  const DashboardScreen(),
                  MasterSectionScreen(
                    key: _masterSectionKey,
                    initialSubIndex: _masterSubIndex,
                    onSubIndexChanged: (subIndex) {
                      setState(() {
                        _masterSubIndex = subIndex;
                      });
                    },
                  ),
                  EntrySectionScreen(
                    key: _entrySectionKey,
                    initialSubIndex: _entrySubIndex,
                    onSubIndexChanged: (subIndex) {
                      setState(() {
                        _entrySubIndex = subIndex;
                      });
                    },
                  ),
                  ReportSectionScreen(
                    key: _reportSectionKey,
                    initialSubIndex: _reportSubIndex,
                    onSubIndexChanged: (subIndex) {
                      setState(() {
                        _reportSubIndex = subIndex;
                      });
                    },
                  ),
                  // const SettingsScreen(),
                  // const BackupScreenWeb(),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: _buildAppBar(),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            const DashboardScreen(),
            MasterSectionScreen(
              key: _masterSectionKey,
              initialSubIndex: _masterSubIndex,
              onSubIndexChanged: (subIndex) {
                setState(() {
                  _masterSubIndex = subIndex;
                });
              },
            ),
            EntrySectionScreen(
              key: _entrySectionKey,
              initialSubIndex: _entrySubIndex,
              onSubIndexChanged: (subIndex) {
                setState(() {
                  _entrySubIndex = subIndex;
                });
              },
            ),
            ReportSectionScreen(
              key: _reportSectionKey,
              initialSubIndex: _reportSubIndex,
              onSubIndexChanged: (subIndex) {
                setState(() {
                  _reportSubIndex = subIndex;
                });
              },
            ),
            // const SettingsScreen(),
            // const BackupScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
              if (index != 1) {
                _masterSubIndex = 0; // Reset when leaving master section
              }
              if (index != 2) {
                _entrySubIndex = 0; // Reset when leaving entry section
              }
              if (index != 3) {
                _reportSubIndex = 0; // Reset when leaving report section
              }
            });
          },
          backgroundColor: const Color(0xFF1E293B),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey[400],
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_special),
              label: 'Master',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit_document),
              label: 'Entry',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assessment),
              label: 'Reports',
            ),
          ],
        ),
      );
    }
  }

  // Add this method to build the AppBar with back button and logout button
  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        _getScreenTitle(),
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: const Color(0xFF1E293B),
      // Add back button only if not on Dashboard
      leading: _selectedIndex != 0
          ? IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          // Navigate to Dashboard
          setState(() {
            _selectedIndex = 0;
            _masterSubIndex = 0;
            _entrySubIndex = 0;
            _reportSubIndex = 0;
          });
        },
      )
          : null,
      // Add logout button as action button
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () {
            _showLogoutDialog(context);
          },
        ),
      ],
    );
  }

  Widget _buildWebSidebar() {
    return Container(
      width: 240,
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          // App Title
          Container(
            padding: const EdgeInsets.all(20),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kiruthik Fab',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Fab Management',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.grey, height: 1),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildSidebarItem(0, Icons.dashboard, 'Dashboard'),

                // Master Section
                _buildMasterSection(),

                // Entry Section
                _buildEntrySection(),

                // Report Section
                _buildReportSection(),
                _buildSidebarItem(5, Icons.backup, 'Backup'),
                // Logout button in sidebar for web
                _buildLogoutSidebarItem(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build logout item for web sidebar
  Widget _buildLogoutSidebarItem() {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.white),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        onTap: () {
          _showLogoutDialog(context);
        },
      ),
    );
  }

  Widget _buildMasterSection() {
    final bool isMasterSelected = _selectedIndex == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isMasterSelected ? const Color(0xFF4318D1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: const Text('Master', style: TextStyle(color: Colors.white)),
        leading: const Icon(Icons.folder_special, color: Colors.white),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        initiallyExpanded: isMasterSelected,
        onExpansionChanged: (expanded) {
          if (expanded) {
            setState(() {
              _selectedIndex = 1;
            });
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              children: [
                _buildMasterSubItem(0, Icons.person, 'Source Master'),
                _buildMasterSubItem(1, Icons.shopping_bag, 'Product Master'),
                _buildMasterSubItem(2, Icons.model_training, 'Model Master'),
                _buildMasterSubItem(3, Icons.straighten, 'Size Master'),
                _buildMasterSubItem(4, Icons.scale, 'Unit Master'),
                _buildMasterSubItem(5, Icons.map, 'Area Master'),
                _buildMasterSubItem(6, Icons.people_alt, 'Refer Master'),
                _buildMasterSubItem(7, Icons.manage_accounts, 'Incharge Master'),
                _buildMasterSubItem(8, Icons.business_center, 'Agent Master'),
                _buildMasterSubItem(9, Icons.person_add, 'Sales Person Master'),
                _buildMasterSubItem(10, Icons.work, 'Occupation Master'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntrySection() {
    final bool isEntrySelected = _selectedIndex == 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isEntrySelected ? const Color(0xFF4318D1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: const Text('Entry', style: TextStyle(color: Colors.white)),
        leading: const Icon(Icons.edit_document, color: Colors.white),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        initiallyExpanded: isEntrySelected,
        onExpansionChanged: (expanded) {
          if (expanded) {
            setState(() {
              _selectedIndex = 2;
            });
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              children: [
                _buildEntrySubItem(0, Icons.receipt, 'Bill Entry'),
                _buildEntrySubItem(1, Icons.pages_outlined, 'KYC Entry'),
                _buildEntrySubItem(2, Icons.pages_outlined, 'Call Register'),
                _buildEntrySubItem(3, Icons.pages_outlined, 'Delivery'),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSection() {
    final bool isReportSelected = _selectedIndex == 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isReportSelected ? const Color(0xFF4318D1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: const Text('Reports', style: TextStyle(color: Colors.white)),
        leading: const Icon(Icons.assessment, color: Colors.white),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        initiallyExpanded: isReportSelected,
        onExpansionChanged: (expanded) {
          if (expanded) {
            setState(() {
              _selectedIndex = 3;
            });
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              children: [
                // _buildReportSubItem(0, Icons.bar_chart, 'Sales Report'),
                _buildReportSubItem(0, Icons.bar_chart, 'Performance Report'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: _selectedIndex == index
            ? const Color(0xFF4318D1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildMasterSubItem(int subIndex, IconData icon, String label) {
    final bool isActive = _selectedIndex == 1 && _masterSubIndex == subIndex;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF5F3DC4) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        contentPadding: const EdgeInsets.only(left: 16),
        onTap: () {
          _switchMasterScreen(subIndex);
        },
      ),
    );
  }

  Widget _buildEntrySubItem(int subIndex, IconData icon, String label) {
    final bool isActive = _selectedIndex == 2 && _entrySubIndex == subIndex;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF5F3DC4) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        contentPadding: const EdgeInsets.only(left: 16),
        onTap: () {
          _switchEntryScreen(subIndex);
        },
      ),
    );
  }

  Widget _buildReportSubItem(int subIndex, IconData icon, String label) {
    final bool isActive = _selectedIndex == 3 && _reportSubIndex == subIndex;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF5F3DC4) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        contentPadding: const EdgeInsets.only(left: 16),
        onTap: () {
          _switchReportScreen(subIndex);
        },
      ),
    );
  }

  String _getScreenTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return _getMasterScreenTitle();
      case 2:
        return _getEntryScreenTitle();
      case 3:
        return _getReportScreenTitle();
      case 4:
        return 'Settings';
      case 5:
        return 'Data Backup';
      default:
        return 'Finance System';
    }
  }

  String _getMasterScreenTitle() {
    switch (_masterSubIndex) {
      case 0:
        return 'Source Master';
      case 1:
        return 'Product Master';
      case 2:
        return 'Model Master';
      case 3:
        return 'Size Master';
      case 4:
        return 'Unit Master';
      case 5:
        return 'Area Master';
      case 6:
        return 'Refer Master';
      case 7:
        return 'Incharge Master';
      case 8:
        return 'Agent Master';
      case 9:
        return 'Sales Person Master';
      case 10:
        return 'Occupation Master';
      default:
        return 'Master';
    }
  }

  String _getEntryScreenTitle() {
    switch (_entrySubIndex) {
      case 0:
        return 'Bill Entry';
      case 1:
        return 'KYC Entry';
      case 2:
        return 'Call Register';
      case 3:
        return 'Delivery';
      default:
        return 'Entry';
    }
  }

  String _getReportScreenTitle() {
    switch (_reportSubIndex) {
      // case 0:
      //   return 'Sales Report';
      case 0:
        return 'Performance Report';
      default:
        return 'Reports';
    }
  }
}

// Master Section Wrapper Screen (updated)
class MasterSectionScreen extends StatefulWidget {
  final int initialSubIndex;
  final ValueChanged<int>? onSubIndexChanged;

  const MasterSectionScreen({
    Key? key,
    this.initialSubIndex = 0,
    this.onSubIndexChanged,
  }) : super(key: key);

  @override
  State<MasterSectionScreen> createState() => _MasterSectionScreenState();
}

class _MasterSectionScreenState extends State<MasterSectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int masterSubIndex = 0;

  @override
  void initState() {
    super.initState();
    masterSubIndex = widget.initialSubIndex;
    _tabController = TabController(
      length: 11, // Updated to 11 tabs
      vsync: this,
      initialIndex: masterSubIndex,
    );

    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        masterSubIndex = _tabController.index;
      });

      widget.onSubIndexChanged?.call(masterSubIndex);
    }
  }

  void switchToSubScreen(int subIndex) {
    setState(() {
      masterSubIndex = subIndex;
    });

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
  Widget build(BuildContext context) {
    final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;

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
              ],
            ),
          ),
        ],
      );
    } else {
      // Web: Show selected screen
      return IndexedStack(
        index: masterSubIndex,
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
        ],
      );
    }
  }
}

// Entry Section Wrapper Screen (updated)
class EntrySectionScreen extends StatefulWidget {
  final int initialSubIndex;
  final ValueChanged<int>? onSubIndexChanged;

  const EntrySectionScreen({
    Key? key,
    this.initialSubIndex = 0,
    this.onSubIndexChanged,
  }) : super(key: key);

  @override
  State<EntrySectionScreen> createState() => _EntrySectionScreenState();
}

class _EntrySectionScreenState extends State<EntrySectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int entrySubIndex = 0;

  @override
  void initState() {
    super.initState();
    entrySubIndex = widget.initialSubIndex;
    _tabController = TabController(
      length: 2, // Updated to 1 tab
      vsync: this,
      initialIndex: entrySubIndex,
    );

    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        entrySubIndex = _tabController.index;
      });

      widget.onSubIndexChanged?.call(entrySubIndex);
    }
  }

  void switchToSubScreen(int subIndex) {
    setState(() {
      entrySubIndex = subIndex;
    });

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
  Widget build(BuildContext context) {
    final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;

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
                Tab(icon: Icon(Icons.pages_outlined), text: 'Call Register'),
                Tab(icon: Icon(Icons.pages_outlined), text: 'Delivery'),

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
        index: entrySubIndex,
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

// Report Section Wrapper Screen (updated)
class ReportSectionScreen extends StatefulWidget {
  final int initialSubIndex;
  final ValueChanged<int>? onSubIndexChanged;

  const ReportSectionScreen({
    Key? key,
    this.initialSubIndex = 0,
    this.onSubIndexChanged,
  }) : super(key: key);

  @override
  State<ReportSectionScreen> createState() => _ReportSectionScreenState();
}

class _ReportSectionScreenState extends State<ReportSectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int reportSubIndex = 0;

  @override
  void initState() {
    super.initState();
    reportSubIndex = widget.initialSubIndex;
    _tabController = TabController(
      length: 1, // Updated to 1 tab
      vsync: this,
      initialIndex: reportSubIndex,
    );

    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        reportSubIndex = _tabController.index;
      });

      widget.onSubIndexChanged?.call(reportSubIndex);
    }
  }

  void switchToSubScreen(int subIndex) {
    setState(() {
      reportSubIndex = subIndex;
    });

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
  Widget build(BuildContext context) {
    final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;

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
                // Tab(icon: Icon(Icons.bar_chart), text: 'Sales Report'),
                Tab(icon: Icon(Icons.bar_chart), text: 'Performance Report'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // SalesReportScreen(),
                SalespersonReport(),
              ],
            ),
          ),
        ],
      );
    } else {
      // Web: Show selected screen
      return IndexedStack(
        index: reportSubIndex,
        children: const [
          // SalesReportScreen(),
          SalespersonReport(),
        ],
      );
    }
  }
}

// import 'package:flutter/cupertino.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:kiruthikfab/screens/product_master_screen.dart';
// import 'package:kiruthikfab/screens/size_master_screen.dart';
// import 'package:kiruthikfab/screens/unit_master_screen.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import 'InvoiceEntryPage.dart';
// import 'customerlist_screen.dart';
// import 'dashboardscreen.dart';
// import 'invoice_list.dart';
// import 'loginpage.dart';
// import 'model_master_screen.dart';
//
// class CustomerManagementApp extends StatefulWidget {
//   const CustomerManagementApp({super.key});
//
//   @override
//   State<CustomerManagementApp> createState() => _CustomerManagementAppState();
// }
//
// class _CustomerManagementAppState extends State<CustomerManagementApp> {
//   int _selectedIndex = 0;
//   int _masterSubIndex =
//   0; // 0: Customer Master, 1: Product Master, 2: Model Master, 3: Size Master, 4: Unit Master
//   int _entrySubIndex =
//   0; // 0: Bill Entry
//   int _reportSubIndex =
//   0; // 0: Sales Report
//   int _backupIndex = 5; // Add backup index
//   // Create GlobalKey for MasterSectionScreen, EntrySectionScreen and ReportSectionScreen
//   final GlobalKey<_MasterSectionScreenState> _masterSectionKey = GlobalKey();
//   final GlobalKey<_EntrySectionScreenState> _entrySectionKey = GlobalKey();
//   final GlobalKey<_ReportSectionScreenState> _reportSectionKey = GlobalKey();
//
//   void _switchMasterScreen(int subIndex) {
//     setState(() {
//       _selectedIndex = 1;
//       _masterSubIndex = subIndex;
//     });
//
//     if (_masterSectionKey.currentState != null) {
//       _masterSectionKey.currentState!.setState(() {
//         _masterSectionKey.currentState!.masterSubIndex = subIndex;
//       });
//     }
//   }
//
//   void _switchEntryScreen(int subIndex) {
//     setState(() {
//       _selectedIndex = 2;
//       _entrySubIndex = subIndex;
//     });
//
//     if (_entrySectionKey.currentState != null) {
//       _entrySectionKey.currentState!.setState(() {
//         _entrySectionKey.currentState!.entrySubIndex = subIndex;
//       });
//     }
//   }
//
//   void _switchReportScreen(int subIndex) {
//     setState(() {
//       _selectedIndex = 3;
//       _reportSubIndex = subIndex;
//     });
//
//     if (_reportSectionKey.currentState != null) {
//       _reportSectionKey.currentState!.setState(() {
//         _reportSectionKey.currentState!.reportSubIndex = subIndex;
//       });
//     }
//   }
//
//   // Method to show logout confirmation dialog
//   void _showLogoutDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text("Logout Confirmation"),
//           content: const Text("Are you sure you want to logout?"),
//           actions: <Widget>[
//             TextButton(
//               child: const Text("No"),
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close dialog
//               },
//             ),
//             TextButton(
//               child: const Text("Yes", style: TextStyle(color: Colors.red)),
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close dialog
//                 _performLogout(context);
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _loadCounterremove() async {
//
//
//     String id;
//     String username;
//     String password;
//     String user_type;
//     String companyid;
//     String activestatus;
//     String email;
//     String companyname;
//     String logourl;
//
//
//
//
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     setState(() {
//
//       WidgetsFlutterBinding.ensureInitialized();
//
//
//
//       prefs.clear();
//       id = (prefs.remove('id')).toString();
//       print('idempty' + id);
//       username = (prefs.remove('username')).toString();
//       print('username' + username);
//       password = (prefs.remove('password')).toString();
//       print('password' + password);
//       email = (prefs.remove('email')).toString();
//       print('email' + email);
//       user_type = (prefs.remove('user_type')).toString();
//       print('type' + user_type);
//       companyid = (prefs.remove('companyid')).toString();
//       print('companyid' + companyid);
//       activestatus = (prefs.remove('activestatus')).toString();
//       print('activestatus' + activestatus);
//
//       companyname = (prefs.remove('companyname')).toString();
//       print('companyname' + companyname);
//
//       logourl = (prefs.remove('logourl')).toString();
//       print('logourl' + logourl);
//
//     });
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const LoginScreen()),
//     );
//   }
//
//
//   // Method to perform logout
//   void _performLogout(BuildContext context) {
//
//     // ScaffoldMessenger.of(context).showSnackBar(
//     //   const SnackBar(
//     //     content: Text("Logged out successfully"),
//     //     duration: Duration(seconds: 2),
//     //   ),
//     // );
//     _loadCounterremove();
//
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;
//
//     if (isWeb) {
//       return Scaffold(
//         body: Row(
//           children: [
//             // Sidebar Navigation for Web
//             _buildWebSidebar(),
//             // Main Content Area
//             Expanded(
//               child: IndexedStack(
//                 index: _selectedIndex,
//                 children: [
//                   const DashboardScreen(),
//                   MasterSectionScreen(
//                     key: _masterSectionKey,
//                     initialSubIndex: _masterSubIndex,
//                     onSubIndexChanged: (subIndex) {
//                       setState(() {
//                         _masterSubIndex = subIndex;
//                       });
//                     },
//                   ),
//                   EntrySectionScreen(
//                     key: _entrySectionKey,
//                     initialSubIndex: _entrySubIndex,
//                     onSubIndexChanged: (subIndex) {
//                       setState(() {
//                         _entrySubIndex = subIndex;
//                       });
//                     },
//                   ),
//                   ReportSectionScreen(
//                     key: _reportSectionKey,
//                     initialSubIndex: _reportSubIndex,
//                     onSubIndexChanged: (subIndex) {
//                       setState(() {
//                         _reportSubIndex = subIndex;
//                       });
//                     },
//                   ),
//                   // const SettingsScreen(),
//                   // const BackupScreenWeb(),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       );
//     } else {
//       return Scaffold(
//         appBar: _buildAppBar(),
//         body: IndexedStack(
//           index: _selectedIndex,
//           children: [
//             const DashboardScreen(),
//             MasterSectionScreen(
//               key: _masterSectionKey,
//               initialSubIndex: _masterSubIndex,
//               onSubIndexChanged: (subIndex) {
//                 setState(() {
//                   _masterSubIndex = subIndex;
//                 });
//               },
//             ),
//             EntrySectionScreen(
//               key: _entrySectionKey,
//               initialSubIndex: _entrySubIndex,
//               onSubIndexChanged: (subIndex) {
//                 setState(() {
//                   _entrySubIndex = subIndex;
//                 });
//               },
//             ),
//             ReportSectionScreen(
//               key: _reportSectionKey,
//               initialSubIndex: _reportSubIndex,
//               onSubIndexChanged: (subIndex) {
//                 setState(() {
//                   _reportSubIndex = subIndex;
//                 });
//               },
//             ),
//             // const SettingsScreen(),
//             // const BackupScreen(),
//           ],
//         ),
//         bottomNavigationBar: BottomNavigationBar(
//           type: BottomNavigationBarType.fixed,
//           currentIndex: _selectedIndex,
//           onTap: (index) {
//             setState(() {
//               _selectedIndex = index;
//               if (index != 1) {
//                 _masterSubIndex = 0; // Reset when leaving master section
//               }
//               if (index != 2) {
//                 _entrySubIndex = 0; // Reset when leaving entry section
//               }
//               if (index != 3) {
//                 _reportSubIndex = 0; // Reset when leaving report section
//               }
//             });
//           },
//           backgroundColor: const Color(0xFF1E293B),
//           selectedItemColor: Colors.white,
//           unselectedItemColor: Colors.grey[400],
//           items: const [
//             BottomNavigationBarItem(
//               icon: Icon(Icons.dashboard),
//               label: 'Dashboard',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.folder_special),
//               label: 'Master',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.edit_document),
//               label: 'Entry',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.assessment),
//               label: 'Reports',
//             ),
//             // BottomNavigationBarItem(
//             //   label: 'Settings',
//             //   icon: Icon(Icons.settings),
//             // ),
//             // BottomNavigationBarItem(
//             //   icon: Icon(Icons.backup),
//             //   label: 'Backup',
//             // ),
//           ],
//         ),
//       );
//     }
//   }
//
//   // Add this method to build the AppBar with back button and logout button
//   AppBar _buildAppBar() {
//     return AppBar(
//       title: Text(
//         _getScreenTitle(),
//         style: const TextStyle(color: Colors.white),
//       ),
//       backgroundColor: const Color(0xFF1E293B),
//       // Add back button only if not on Dashboard
//       leading: _selectedIndex != 0
//           ? IconButton(
//         icon: const Icon(Icons.arrow_back, color: Colors.white),
//         onPressed: () {
//           // Navigate to Dashboard
//           setState(() {
//             _selectedIndex = 0;
//             _masterSubIndex = 0;
//             _entrySubIndex = 0;
//             _reportSubIndex = 0;
//           });
//         },
//       )
//           : null,
//       // Add logout button as action button
//       actions: [
//         IconButton(
//           icon: const Icon(Icons.logout, color: Colors.white),
//           onPressed: () {
//             _showLogoutDialog(context);
//           },
//         ),
//       ],
//     );
//   }
//
//   Widget _buildWebSidebar() {
//     return Container(
//       width: 240,
//       color: const Color(0xFF1E293B),
//       child: Column(
//         children: [
//           // App Title
//           Container(
//             padding: const EdgeInsets.all(20),
//             child: const Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Kiruthik Fab',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   'Fab Management',
//                   style: TextStyle(color: Colors.grey, fontSize: 12),
//                 ),
//               ],
//             ),
//           ),
//
//           const Divider(color: Colors.grey, height: 1),
//
//           // Navigation Items
//           Expanded(
//             child: ListView(
//               padding: const EdgeInsets.all(12),
//               children: [
//                 _buildSidebarItem(0, Icons.dashboard, 'Dashboard'),
//
//                 // Master Section
//                 _buildMasterSection(),
//
//                 // Entry Section
//                 _buildEntrySection(),
//
//                 // Report Section
//                 _buildReportSection(),
//                 _buildSidebarItem(5, Icons.backup, 'Backup'),
//                 // Logout button in sidebar for web
//                 _buildLogoutSidebarItem(),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Build logout item for web sidebar
//   Widget _buildLogoutSidebarItem() {
//     return Container(
//       margin: const EdgeInsets.only(top: 20, bottom: 4),
//       decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
//       child: ListTile(
//         leading: const Icon(Icons.logout, color: Colors.white),
//         title: const Text('Logout', style: TextStyle(color: Colors.white)),
//         onTap: () {
//           _showLogoutDialog(context);
//         },
//       ),
//     );
//   }
//
//   Widget _buildMasterSection() {
//     final bool isMasterSelected = _selectedIndex == 1;
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 4),
//       decoration: BoxDecoration(
//         color: isMasterSelected ? const Color(0xFF4318D1) : Colors.transparent,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: ExpansionTile(
//         title: const Text('Master', style: TextStyle(color: Colors.white)),
//         leading: const Icon(Icons.folder_special, color: Colors.white),
//         backgroundColor: Colors.transparent,
//         collapsedBackgroundColor: Colors.transparent,
//         initiallyExpanded: isMasterSelected,
//         onExpansionChanged: (expanded) {
//           if (expanded) {
//             setState(() {
//               _selectedIndex = 1;
//             });
//           }
//         },
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(left: 16),
//             child: Column(
//               children: [
//                 _buildMasterSubItem(0, Icons.person, 'Customer Master'),
//                 _buildMasterSubItem(1, Icons.shopping_bag, 'Product Master'),
//                 _buildMasterSubItem(2, Icons.model_training, 'Model Master'),
//                 _buildMasterSubItem(3, Icons.straighten, 'Size Master'),
//                 _buildMasterSubItem(4, Icons.scale, 'Unit Master'),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildEntrySection() {
//     final bool isEntrySelected = _selectedIndex == 2;
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 4),
//       decoration: BoxDecoration(
//         color: isEntrySelected ? const Color(0xFF4318D1) : Colors.transparent,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: ExpansionTile(
//         title: const Text('Entry', style: TextStyle(color: Colors.white)),
//         leading: const Icon(Icons.edit_document, color: Colors.white),
//         backgroundColor: Colors.transparent,
//         collapsedBackgroundColor: Colors.transparent,
//         initiallyExpanded: isEntrySelected,
//         onExpansionChanged: (expanded) {
//           if (expanded) {
//             setState(() {
//               _selectedIndex = 2;
//             });
//           }
//         },
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(left: 16),
//             child: Column(
//               children: [
//                 _buildEntrySubItem(0, Icons.receipt, 'Bill Entry'),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildReportSection() {
//     final bool isReportSelected = _selectedIndex == 3;
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 4),
//       decoration: BoxDecoration(
//         color: isReportSelected ? const Color(0xFF4318D1) : Colors.transparent,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: ExpansionTile(
//         title: const Text('Reports', style: TextStyle(color: Colors.white)),
//         leading: const Icon(Icons.assessment, color: Colors.white),
//         backgroundColor: Colors.transparent,
//         collapsedBackgroundColor: Colors.transparent,
//         initiallyExpanded: isReportSelected,
//         onExpansionChanged: (expanded) {
//           if (expanded) {
//             setState(() {
//               _selectedIndex = 3;
//             });
//           }
//         },
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(left: 16),
//             child: Column(
//               children: [
//                 _buildReportSubItem(0, Icons.bar_chart, 'Sales Report'),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSidebarItem(int index, IconData icon, String label) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 4),
//       decoration: BoxDecoration(
//         color: _selectedIndex == index
//             ? const Color(0xFF4318D1)
//             : Colors.transparent,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: ListTile(
//         leading: Icon(icon, color: Colors.white),
//         title: Text(label, style: const TextStyle(color: Colors.white)),
//         onTap: () {
//           setState(() {
//             _selectedIndex = index;
//           });
//         },
//       ),
//     );
//   }
//
//   Widget _buildMasterSubItem(int subIndex, IconData icon, String label) {
//     final bool isActive = _selectedIndex == 1 && _masterSubIndex == subIndex;
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 4),
//       decoration: BoxDecoration(
//         color: isActive ? const Color(0xFF5F3DC4) : Colors.transparent,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: ListTile(
//         leading: Icon(icon, color: Colors.white),
//         title: Text(
//           label,
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 14,
//             fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
//           ),
//         ),
//         contentPadding: const EdgeInsets.only(left: 16),
//         onTap: () {
//           _switchMasterScreen(subIndex);
//         },
//       ),
//     );
//   }
//
//   Widget _buildEntrySubItem(int subIndex, IconData icon, String label) {
//     final bool isActive = _selectedIndex == 2 && _entrySubIndex == subIndex;
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 4),
//       decoration: BoxDecoration(
//         color: isActive ? const Color(0xFF5F3DC4) : Colors.transparent,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: ListTile(
//         leading: Icon(icon, color: Colors.white),
//         title: Text(
//           label,
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 14,
//             fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
//           ),
//         ),
//         contentPadding: const EdgeInsets.only(left: 16),
//         onTap: () {
//           _switchEntryScreen(subIndex);
//         },
//       ),
//     );
//   }
//
//   Widget _buildReportSubItem(int subIndex, IconData icon, String label) {
//     final bool isActive = _selectedIndex == 3 && _reportSubIndex == subIndex;
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 4),
//       decoration: BoxDecoration(
//         color: isActive ? const Color(0xFF5F3DC4) : Colors.transparent,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: ListTile(
//         leading: Icon(icon, color: Colors.white),
//         title: Text(
//           label,
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 14,
//             fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
//           ),
//         ),
//         contentPadding: const EdgeInsets.only(left: 16),
//         onTap: () {
//           _switchReportScreen(subIndex);
//         },
//       ),
//     );
//   }
//
//   String _getScreenTitle() {
//     switch (_selectedIndex) {
//       case 0:
//         return 'Dashboard';
//       case 1:
//         return _getMasterScreenTitle();
//       case 2:
//         return _getEntryScreenTitle();
//       case 3:
//         return _getReportScreenTitle();
//       case 4:
//         return 'Settings';
//       case 5:
//         return 'Data Backup';
//       default:
//         return 'Finance System';
//     }
//   }
//
//   String _getMasterScreenTitle() {
//     switch (_masterSubIndex) {
//       case 0:
//         return 'Customer Master';
//       case 1:
//         return 'Product Master';
//       case 2:
//         return 'Model Master';
//       case 3:
//         return 'Size Master';
//       case 4:
//         return 'Unit Master';
//       default:
//         return 'Master';
//     }
//   }
//
//   String _getEntryScreenTitle() {
//     switch (_entrySubIndex) {
//       case 0:
//         return 'Bill Entry';
//       default:
//         return 'Entry';
//     }
//   }
//
//   String _getReportScreenTitle() {
//     switch (_reportSubIndex) {
//       case 0:
//         return 'Sales Report';
//       default:
//         return 'Reports';
//     }
//   }
// }
//
// // Master Section Wrapper Screen (updated)
// class MasterSectionScreen extends StatefulWidget {
//   final int initialSubIndex;
//   final ValueChanged<int>? onSubIndexChanged;
//
//   const MasterSectionScreen({
//     Key? key,
//     this.initialSubIndex = 0,
//     this.onSubIndexChanged,
//   }) : super(key: key);
//
//   @override
//   State<MasterSectionScreen> createState() => _MasterSectionScreenState();
// }
//
// class _MasterSectionScreenState extends State<MasterSectionScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   int masterSubIndex = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     masterSubIndex = widget.initialSubIndex;
//     _tabController = TabController(
//       length: 5, // Updated to 5 tabs
//       vsync: this,
//       initialIndex: masterSubIndex,
//     );
//
//     _tabController.addListener(_handleTabChange);
//   }
//
//   void _handleTabChange() {
//     if (!_tabController.indexIsChanging) {
//       setState(() {
//         masterSubIndex = _tabController.index;
//       });
//
//       widget.onSubIndexChanged?.call(masterSubIndex);
//     }
//   }
//
//   void switchToSubScreen(int subIndex) {
//     setState(() {
//       masterSubIndex = subIndex;
//     });
//
//     if (_tabController.index != subIndex) {
//       _tabController.animateTo(subIndex);
//     }
//
//     widget.onSubIndexChanged?.call(subIndex);
//   }
//
//   @override
//   void dispose() {
//     _tabController.removeListener(_handleTabChange);
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;
//
//     if (!isWeb) {
//       // Mobile: Show tabs at the top
//       return Column(
//         children: [
//           Container(
//             color: const Color(0xFF1E293B),
//             child: TabBar(
//               controller: _tabController,
//               indicatorColor: Colors.white,
//               labelColor: Colors.white,
//               unselectedLabelColor: Colors.grey[400],
//               isScrollable: true,
//               tabs: const [
//                 Tab(icon: Icon(Icons.person), text: 'Customer'),
//                 Tab(icon: Icon(Icons.shopping_bag), text: 'Product'),
//                 Tab(icon: Icon(Icons.model_training), text: 'Model'),
//                 Tab(icon: Icon(Icons.straighten), text: 'Size'),
//                 Tab(icon: Icon(Icons.scale), text: 'Unit'),
//               ],
//             ),
//           ),
//           Expanded(
//             child: TabBarView(
//               controller: _tabController,
//               children: const [
//                 CustomerListScreen(),
//                 ProductMasterScreen(),
//                 ModelMasterScreen(),
//                 SizeMasterScreen(),
//                 UnitMasterScreen(),
//               ],
//             ),
//           ),
//         ],
//       );
//     } else {
//       // Web: Show selected screen
//       return IndexedStack(
//         index: masterSubIndex,
//         children: const [
//           CustomerListScreen(),
//           ProductMasterScreen(),
//           ModelMasterScreen(),
//           SizeMasterScreen(),
//           UnitMasterScreen(),
//         ],
//       );
//     }
//   }
// }
//
// // Entry Section Wrapper Screen (updated)
// class EntrySectionScreen extends StatefulWidget {
//   final int initialSubIndex;
//   final ValueChanged<int>? onSubIndexChanged;
//
//   const EntrySectionScreen({
//     Key? key,
//     this.initialSubIndex = 0,
//     this.onSubIndexChanged,
//   }) : super(key: key);
//
//   @override
//   State<EntrySectionScreen> createState() => _EntrySectionScreenState();
// }
//
// class _EntrySectionScreenState extends State<EntrySectionScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   int entrySubIndex = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     entrySubIndex = widget.initialSubIndex;
//     _tabController = TabController(
//       length: 1, // Updated to 1 tab
//       vsync: this,
//       initialIndex: entrySubIndex,
//     );
//
//     _tabController.addListener(_handleTabChange);
//   }
//
//   void _handleTabChange() {
//     if (!_tabController.indexIsChanging) {
//       setState(() {
//         entrySubIndex = _tabController.index;
//       });
//
//       widget.onSubIndexChanged?.call(entrySubIndex);
//     }
//   }
//
//   void switchToSubScreen(int subIndex) {
//     setState(() {
//       entrySubIndex = subIndex;
//     });
//
//     if (_tabController.index != subIndex) {
//       _tabController.animateTo(subIndex);
//     }
//
//     widget.onSubIndexChanged?.call(subIndex);
//   }
//
//   @override
//   void dispose() {
//     _tabController.removeListener(_handleTabChange);
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;
//
//     if (!isWeb) {
//       // Mobile: Show tabs at the top
//       return Column(
//         children: [
//           Container(
//             color: const Color(0xFF1E293B),
//             child: TabBar(
//               controller: _tabController,
//               indicatorColor: Colors.white,
//               labelColor: Colors.white,
//               unselectedLabelColor: Colors.grey[400],
//               isScrollable: true,
//               tabs: const [
//                 Tab(icon: Icon(Icons.receipt), text: 'Bill Entry'),
//               ],
//             ),
//           ),
//           Expanded(
//             child: TabBarView(
//               controller: _tabController,
//               children: [
//                 const InvoiceListPage(),
//               ],
//             ),
//           ),
//         ],
//       );
//     } else {
//       // Web: Show selected screen
//       return IndexedStack(
//         index: entrySubIndex,
//         children: const [
//           InvoiceListPage(),
//         ],
//       );
//     }
//   }
// }
//
// // Report Section Wrapper Screen (updated)
// class ReportSectionScreen extends StatefulWidget {
//   final int initialSubIndex;
//   final ValueChanged<int>? onSubIndexChanged;
//
//   const ReportSectionScreen({
//     Key? key,
//     this.initialSubIndex = 0,
//     this.onSubIndexChanged,
//   }) : super(key: key);
//
//   @override
//   State<ReportSectionScreen> createState() => _ReportSectionScreenState();
// }
//
// class _ReportSectionScreenState extends State<ReportSectionScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   int reportSubIndex = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     reportSubIndex = widget.initialSubIndex;
//     _tabController = TabController(
//       length: 1, // Updated to 1 tab
//       vsync: this,
//       initialIndex: reportSubIndex,
//     );
//
//     _tabController.addListener(_handleTabChange);
//   }
//
//   void _handleTabChange() {
//     if (!_tabController.indexIsChanging) {
//       setState(() {
//         reportSubIndex = _tabController.index;
//       });
//
//       widget.onSubIndexChanged?.call(reportSubIndex);
//     }
//   }
//
//   void switchToSubScreen(int subIndex) {
//     setState(() {
//       reportSubIndex = subIndex;
//     });
//
//     if (_tabController.index != subIndex) {
//       _tabController.animateTo(subIndex);
//     }
//
//     widget.onSubIndexChanged?.call(subIndex);
//   }
//
//   @override
//   void dispose() {
//     _tabController.removeListener(_handleTabChange);
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;
//
//     if (!isWeb) {
//       // Mobile: Show tabs at the top
//       return Column(
//         children: [
//           Container(
//             color: const Color(0xFF1E293B),
//             child: TabBar(
//               controller: _tabController,
//               indicatorColor: Colors.white,
//               labelColor: Colors.white,
//               unselectedLabelColor: Colors.grey[400],
//               isScrollable: true,
//               tabs: const [
//                 Tab(icon: Icon(Icons.bar_chart), text: 'Sales Report'),
//               ],
//             ),
//           ),
//           Expanded(
//             child: TabBarView(
//               controller: _tabController,
//               children: [
//                 // SalesReportScreen(),
//               ],
//             ),
//           ),
//         ],
//       );
//     } else {
//       // Web: Show selected screen
//       return IndexedStack(
//         index: reportSubIndex,
//         children: const [
//           // SalesReportScreen(),
//         ],
//       );
//     }
//   }
// }