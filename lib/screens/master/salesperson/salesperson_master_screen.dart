import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../../models/salespersonmaster_model.dart';
import '../../../../services/salesperson_apiservice.dart';

class SalesPersonMasterScreen extends StatefulWidget {
  const SalesPersonMasterScreen({super.key});

  @override
  State<SalesPersonMasterScreen> createState() =>
      _SalesPersonMasterScreenState();
}

class _SalesPersonMasterScreenState extends State<SalesPersonMasterScreen> {
  final _formKey = GlobalKey<FormState>();
  final SalesPersonApiService _apiService = SalesPersonApiService();
  final TextEditingController _salesPersonNameController =
      TextEditingController();
  final TextEditingController _salesPersonPassController =
      TextEditingController();

  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isListLoading = true;
  bool isobscureText = true;

  // Store the sales person being edited
  SalesPersonMasterModel? _editingSalesPerson;

  List<SalesPersonMasterModel> _salesPersons = [];
  String _searchQuery = '';
  String? selectedRole;

  @override
  void initState() {
    super.initState();
    _loadSalesPersons();
  }

  @override
  void dispose() {
    _salesPersonNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSalesPersons() async {
    if (!mounted) return;

    setState(() {
      _isListLoading = true;
    });

    try {
      final salesPersons = await _apiService.fetchSalesPersons(context);
      if (mounted) {
        setState(() {
          _salesPersons = salesPersons;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading sales persons: $e"),
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

      if (_isEditMode && _editingSalesPerson != null) {
        // Update existing sales person
        result = await _apiService.updateSalesPerson(
          context: context,
          salesPersonId: _editingSalesPerson!.id,
          salespersonname: _salesPersonNameController.text,
          usertype: selectedRole.toString().toUpperCase(),
        );
      } else {
        // Insert new sales person
        result = await _apiService.insertSalesPerson(
          context: context,
          salespersonname: _salesPersonNameController.text,
          password: _salesPersonPassController.text,
          usertype: selectedRole.toString().toUpperCase(),
        );
      }

      if (result == "Success") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Sales Person updated successfully!'
                  : 'Sales Person created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form and reload list
        _cancelEdit();
        await _loadSalesPersons();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteSalesPerson(String salesPersonId, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete this sales person?',
        ),
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
      final result = await _apiService.deleteSalesPerson(
        context,
        salesPersonId,
      );
      if (result == "Success" && mounted) {
        setState(() {
          _salesPersons.removeAt(index);
          // If we were editing this sales person, cancel edit mode
          if (_editingSalesPerson?.id == salesPersonId) {
            _cancelEdit();
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sales Person deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _editSalesPerson(SalesPersonMasterModel salesPerson) {
    setState(() {
      _isEditMode = true;
      _editingSalesPerson = salesPerson;
      _salesPersonNameController.text = salesPerson.salespersonname;
      selectedRole = salesPerson.type;
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
      _editingSalesPerson = null;
      _salesPersonNameController.clear();
      _salesPersonNameController.clear();
      selectedRole = null;
    });
  }

  List<SalesPersonMasterModel> get _filteredSalesPersons {
    if (_searchQuery.isEmpty) return _salesPersons;
    return _salesPersons.where((salesPerson) {
      return salesPerson.salespersonname.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // automaticallyImplyActions: false,
        title: const Text('Sales Person Master'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadSalesPersons,
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
                  CircularProgressIndicator(),
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

                        // Sales Person List Header
                        _buildListHeader(isWeb),

                        const SizedBox(height: 16),

                        // Sales Person List
                        if (_isListLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_filteredSalesPersons.isEmpty)
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
            _isEditMode ? 'Edit Sales Person' : 'Add New Sales Person',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isEditMode
                ? 'Updating: ${_editingSalesPerson?.salespersonname ?? ''}'
                : 'Create a new sales person record',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget roleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "User Type",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: selectedRole,
          decoration: InputDecoration(
            hintText: "Select User Type",
            prefixIcon: const Icon(Icons.person_outline),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: 'ADMIN',
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings, size: 18),
                  SizedBox(width: 8),
                  Text('ADMIN'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'USER',
              child: Row(
                children: [
                  Icon(Icons.person, size: 18),
                  SizedBox(width: 8),
                  Text('USER'),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              selectedRole = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildFormCard(bool isWeb) {
    final isMobile = MediaQuery.of(context).size.width < 600;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Sales Person Name',
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
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextFormField(
                          controller: _salesPersonNameController,
                          decoration: InputDecoration(
                            hintText:
                                'Enter sales person name (e.g., John Doe, Sales Executive, etc.)',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            border: InputBorder.none,
                            suffixIcon: _isEditMode
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.grey,
                                    ),
                                    onPressed: _cancelEdit,
                                    tooltip: 'Cancel Edit',
                                  )
                                : null,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Sales Person name is required';
                            }
                            if (value.length < 2) {
                              return 'Sales Person name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      isMobile
                          ? Column(
                              children: [
                                if (_isEditMode != true)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Password",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: const Color(0xFFD1D5DB),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: TextFormField(
                                          obscureText: isobscureText,
                                          controller:
                                              _salesPersonPassController,
                                          decoration: InputDecoration(
                                            suffix: IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  isobscureText =
                                                      !isobscureText;
                                                });
                                              },
                                              icon: isobscureText
                                                  ? const Icon(
                                                      Icons.visibility_off,
                                                    )
                                                  : const Icon(
                                                      Icons.visibility,
                                                    ),
                                            ),
                                            hintText: 'Password',
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                ),
                                            border: InputBorder.none,
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return '_filterProducts is required';
                                            }
                                            if (value.length < 2) {
                                              return '_filterProducts must be at least 2 characters';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 16),
                                roleDropdown(),
                              ],
                            )
                          : Row(
                              children: [
                                if (_isEditMode != true)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Password",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          height: 50,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: const Color(0xFFD1D5DB),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: TextFormField(
                                            obscureText: isobscureText,
                                            controller:
                                                _salesPersonPassController,
                                            decoration: InputDecoration(
                                              suffix: IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    isobscureText =
                                                        !isobscureText;
                                                  });
                                                },
                                                icon: isobscureText
                                                    ? const Icon(
                                                        Icons.visibility_off,
                                                      )
                                                    : const Icon(
                                                        Icons.visibility,
                                                      ),
                                              ),
                                              hintText: 'Password',
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                  ),
                                              border: InputBorder.none,
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return '_filterProducts is required';
                                              }
                                              if (value.length < 2) {
                                                return '_filterProducts must be at least 2 characters';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (_isEditMode != true)
                                  const SizedBox(width: 16),
                                Expanded(child: roleDropdown()),
                              ],
                            ),
                    ],
                  ),
                ),
                if (isWeb) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const SizedBox(height: 24),
                          Row(
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
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
                        _isEditMode
                            ? 'Update Sales Person'
                            : 'Create Sales Person',
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    return isMobile
        ? Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sales Person List',
                style: TextStyle(
                  fontSize: isWeb ? 24 : 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 250,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search sales persons...',
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
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sales Person List',
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
                    hintText: 'Search sales persons...',
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
            Icon(Icons.person_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No matching sales persons found'
                  : 'No sales persons yet',
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
                    'Sales Person Name',
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
            itemCount: _filteredSalesPersons.length,
            itemBuilder: (context, index) {
              final salesPerson = _filteredSalesPersons[index];
              final bool isEditing = _editingSalesPerson?.id == salesPerson.id;

              return Container(
                decoration: BoxDecoration(
                  color: isEditing ? Colors.blue.shade50 : null,
                  border: index < _filteredSalesPersons.length - 1
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
                        salesPerson.salespersonname,
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
                                : () => _editSalesPerson(salesPerson),
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
                                _deleteSalesPerson(salesPerson.id, index),
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
      itemCount: _filteredSalesPersons.length,
      itemBuilder: (context, index) {
        final salesPerson = _filteredSalesPersons[index];
        final bool isEditing = _editingSalesPerson?.id == salesPerson.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isEditing ? Colors.blue.shade50 : Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Material(
            color: Colors.transparent,
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
                salesPerson.salespersonname,
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
                    onPressed: isEditing
                        ? null
                        : () => _editSalesPerson(salesPerson),
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
                    onPressed: () => _deleteSalesPerson(salesPerson.id, index),
                    icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                    tooltip: 'Delete',
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
