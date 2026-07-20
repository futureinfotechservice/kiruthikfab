import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:kiruthikfab/indigator/main.dart';
import 'package:kiruthikfab/models/in_charge_master_model.dart';
import 'package:kiruthikfab/screens/navigation_provider.dart';
import 'package:kiruthikfab/services/incharge_apiservice.dart';
import 'package:provider/provider.dart';

class InchargeMasterScreen extends StatefulWidget {
  const InchargeMasterScreen({super.key});

  @override
  State<InchargeMasterScreen> createState() => _InchargeMasterScreenState();
}

class _InchargeMasterScreenState extends State<InchargeMasterScreen> {
  final _formKey = GlobalKey<FormState>();
  final InchargeApiService _apiService = InchargeApiService();
  final TextEditingController _inchargeNameController = TextEditingController();

  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isListLoading = true;

  // Store the incharge being edited
  InChargeMasterModel? _editingIncharge;

  List<InChargeMasterModel> _incharges = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadIncharges();
  }

  @override
  void dispose() {
    _inchargeNameController.dispose();
    super.dispose();
  }

  Future<void> _loadIncharges() async {
    if (!mounted) return;

    setState(() {
      _isListLoading = true;
    });

    try {
      final incharges = await _apiService.fetchIncharges(context);
      if (mounted) {
        setState(() {
          _incharges = incharges;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading incharges: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isListLoading = false;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String result;

      if (_isEditMode && _editingIncharge != null) {
        // Update existing incharge
        result = await _apiService.updateIncharge(
          context: context,
          inchargeId: _editingIncharge!.id,
          inchargetname: _inchargeNameController.text,
        );
      } else {
        // Insert new incharge
        result = await _apiService.insertIncharge(
          context: context,
          inchargetname: _inchargeNameController.text,
        );
      }

      if (result == "Success") {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditMode
                    ? 'Incharge updated successfully!'
                    : 'Incharge created successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Reset form and reload list
        _cancelEdit();
        await _loadIncharges();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteIncharge(String inchargeId, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this incharge?'),
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

    if (confirmed == true && mounted) {
      final result = await _apiService.deleteIncharge(context, inchargeId);
      if (result == "Success" && mounted) {
        setState(() {
          _incharges.removeAt(index);
          // If we were editing this incharge, cancel edit mode
          if (_editingIncharge?.id == inchargeId) {
            _cancelEdit();
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incharge deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _editIncharge(InChargeMasterModel incharge) {
    setState(() {
      _isEditMode = true;
      _editingIncharge = incharge;
      _inchargeNameController.text = incharge.inchargetname;
    });

    // Scroll to top to show the form
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _cancelEdit() {
    setState(() {
      _isEditMode = false;
      _editingIncharge = null;
      _inchargeNameController.clear();
    });
  }

  List<InChargeMasterModel> get _filteredIncharges {
    if (_searchQuery.isEmpty) return _incharges;
    return _incharges.where((incharge) {
      return incharge.inchargetname.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;
    final navProvider = context.watch<NavigationProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            navProvider.updateIndex(
              selectedIndex: 1,
              reportSubIndex: 0,
              masterSubIndex: 0,
              entrySubIndex: 0,
            );
          },
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text('Incharge Master'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadIncharges,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularWaveProgress(),
                  SizedBox(height: 16),
                  Text(
                    'Processing...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Card
                        _buildHeaderCard(),

                        const SizedBox(height: 24),

                        // Form Card
                        _buildFormCard(isWeb),

                        const SizedBox(height: 32),

                        // Incharge List Header
                        _buildListHeader(isWeb),

                        const SizedBox(height: 16),

                        // Incharge List
                        if (_isListLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularWaveProgress(),
                            ),
                          )
                        else if (_filteredIncharges.isEmpty)
                          _buildEmptyState()
                        else
                          isWeb ? _buildWebTable() : _buildMobileList(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditMode ? 'Edit Incharge' : 'Add New Incharge',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isEditMode
                ? 'Updating: ${_editingIncharge?.inchargetname ?? ''}'
                : 'Create a new incharge record',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(bool isWeb) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Incharge Name',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
                const Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              _submitForm();
                            },
                            controller: _inchargeNameController,
                            decoration: InputDecoration(
                              hintText:
                                  'Enter incharge name (e.g., John Doe, Manager Name, etc.)',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              border: InputBorder.none,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Incharge name is required';
                              }
                              if (value.length < 2) {
                                return 'Incharge name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 2),
                        if (_isEditMode)
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: _cancelEdit,
                            tooltip: 'Cancel Edit',
                          ),
                      ],
                    ),
                  ),
                ),
                if (isWeb) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E293B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _isEditMode ? 'Update' : 'Create',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_isEditMode) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: OutlinedButton(
                                onPressed: _cancelEdit,
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (!isWeb) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _isEditMode ? 'Update Incharge' : 'Create Incharge',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (_isEditMode) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _cancelEdit,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListHeader(bool isWeb) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Incharge List',
          style: TextStyle(
            fontSize: isWeb ? 24 : 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        Container(
          width: 250,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search incharges...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No matching incharges found'
                  : 'No incharges yet',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 1,
                  child: Text(
                    'S.No',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'Incharge Name',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Actions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Table Rows
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredIncharges.length,
            itemBuilder: (context, index) {
              final incharge = _filteredIncharges[index];
              final bool isEditing = _editingIncharge?.id == incharge.id;

              return Container(
                decoration: BoxDecoration(
                  color: isEditing ? Colors.blue.shade50 : null,
                  border: index < _filteredIncharges.length - 1
                      ? const Border(
                          bottom: BorderSide(color: Color(0xFFE2E8F0)),
                        )
                      : null,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: isEditing
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isEditing ? Colors.blue : Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        incharge.inchargetname,
                        style: TextStyle(
                          fontWeight: isEditing
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isEditing ? Colors.blue : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Edit button
                          IconButton(
                            onPressed: isEditing
                                ? null
                                : () => _editIncharge(incharge),
                            icon: Icon(
                              Icons.edit,
                              color: isEditing ? Colors.grey : Colors.blue,
                              size: 20,
                            ),
                            tooltip: 'Edit',
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          // Delete button
                          IconButton(
                            onPressed: () =>
                                _deleteIncharge(incharge.id, index),
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            tooltip: 'Delete',
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredIncharges.length,
      itemBuilder: (context, index) {
        final incharge = _filteredIncharges[index];
        final bool isEditing = _editingIncharge?.id == incharge.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isEditing ? Colors.blue.shade50 : Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: isEditing ? Colors.blue : Colors.blue.shade700,
              radius: 20,
              child: Text(
                (index + 1).toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              incharge.inchargetname,
              style: TextStyle(
                fontWeight: isEditing ? FontWeight.bold : FontWeight.w500,
                color: isEditing ? Colors.blue : Colors.black87,
                fontSize: 16,
              ),
            ),
            subtitle: isEditing
                ? const Text(
                    'Currently editing',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit button
                IconButton(
                  onPressed: isEditing ? null : () => _editIncharge(incharge),
                  icon: Icon(
                    Icons.edit,
                    color: isEditing ? Colors.grey : Colors.blue,
                    size: 22,
                  ),
                  tooltip: 'Edit',
                  splashRadius: 20,
                ),
                // Delete button
                IconButton(
                  onPressed: () => _deleteIncharge(incharge.id, index),
                  icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                  tooltip: 'Delete',
                  splashRadius: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
