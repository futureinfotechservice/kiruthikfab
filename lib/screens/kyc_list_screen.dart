import 'package:flutter/material.dart';
import '../models/kyc_master_model.dart';
import '../services/kyc_apiservice.dart';
import 'kyc_entry_screen.dart';

class KYCListScreen extends StatefulWidget {
  const KYCListScreen({super.key});

  @override
  State<KYCListScreen> createState() => _KYCListScreenState();
}

class _KYCListScreenState extends State<KYCListScreen> {
  final KYCApiService _kycService = KYCApiService();
  List<KYCMasterModel> _kycList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadKYCList();
  }

  Future<void> _loadKYCList() async {
    setState(() => _isLoading = true);
    try {
      final kycList = await _kycService.fetchKYCList(context);
      setState(() {
        _kycList = kycList;
      });
    } catch (e) {
      print("Error loading KYC: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading KYC: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteKYC(String kycId, int index) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this KYC record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await _kycService.deleteKYC(context, kycId);
        if (result == "Success" && mounted) {
          setState(() {
            _kycList.removeAt(index);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('KYC deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print("Delete error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting KYC: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToKYCEntry({Map<String, dynamic>? kycData}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KYCEntryScreen(kycData: kycData),
      ),
    );
    if (result == true && mounted) {
      _loadKYCList();
    }
  }

  List<KYCMasterModel> get _filteredKYC {
    if (_searchQuery.isEmpty) return _kycList;
    return _kycList.where((kyc) {
      return kyc.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          kyc.customerId.contains(_searchQuery);
    }).toList();
  }

  // Mobile-optimized product card for expanded view
  Widget _buildProductCard(var product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  product.productName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  product.size,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Qty: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(product.quantity, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
              Row(
                children: [
                  const Text('Price: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('₹ ${double.tryParse(product.price)?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
              Row(
                children: [
                  const Text('Total: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('₹ ${double.tryParse(product.totalAmount)?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Mobile-optimized family member card
  Widget _buildFamilyMemberCard(var member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Member Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.purple[100],
                  radius: 20,
                  child: Text(
                    member.memberName.isNotEmpty ? member.memberName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[800],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.memberName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            member.relation,
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                          Text(
                            '•',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                          Text(
                            '${member.age} yrs',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                          Text(
                            '•',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                          Expanded(
                            child: Text(
                              member.occupation,
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '₹ ${double.tryParse(member.memberTotal)?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Products Section
          if (member.products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Products',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...member.products.map((product) => _buildProductCard(product)).toList(),
                ],
              ),
            ),

          if (member.products.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No products added',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKYCCard(KYCMasterModel kyc, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          leading: CircleAvatar(
            backgroundColor: Colors.purple,
            radius: 25,
            child: Text(
              kyc.customerName.isNotEmpty ? kyc.customerName[0].toUpperCase() : 'K',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            kyc.customerName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.family_restroom, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${kyc.children.length} Members',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_bag, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${kyc.children.fold(0, (sum, member) => sum + member.products.length)} Products',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.currency_rupee, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Total: ₹ ${double.tryParse(kyc.totalAmount)?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  Map<String, dynamic> kycData = {
                    'id': kyc.id,
                    'customer_id': kyc.customerId,
                    'customer_name': kyc.customerName,
                    'total_amount': kyc.totalAmount,
                    'family_members': kyc.children.map((c) => {
                      'name': c.memberName,
                      'gender': c.gender,
                      'age': c.age,
                      'relation': c.relation,
                      'occupation': c.occupation,
                      'occupation_id': c.occupationId,
                      'member_total': c.memberTotal,
                      'products': c.products.map((p) => {
                        'product_id': p.productId,
                        'product_name': p.productName,
                        'size': p.size,
                        'quantity': p.quantity,
                        'price': p.price,
                        'total': p.totalAmount,
                      }).toList(),
                    }).toList(),
                  };
                  _navigateToKYCEntry(kycData: kycData);
                },
                icon: const Icon(Icons.edit, color: Colors.blue),
                tooltip: 'Edit',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _deleteKYC(kyc.id, index),
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Delete',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ...kyc.children.map((member) => _buildFamilyMemberCard(member)).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Family KYC'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadKYCList,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by customer name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Records: ${_filteredKYC.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // List or Empty State
          Expanded(
            child: _isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading KYC records...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
                : _filteredKYC.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No KYC records found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Try a different search term'
                        : 'Create your first KYC record',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  if (_searchQuery.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: ElevatedButton(
                        onPressed: () => _navigateToKYCEntry(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Create KYC'),
                      ),
                    ),
                ],
              ),
            )
                : ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: _filteredKYC.length,
              itemBuilder: (context, index) {
                return _buildKYCCard(_filteredKYC[index], index);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToKYCEntry(),
        backgroundColor: const Color(0xFF1E293B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}