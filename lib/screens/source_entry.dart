import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/CustomerInterestModel.dart';
import '../../models/source_master_model.dart';
import '../../services/customer_interest_apiservice.dart';
import '../../services/source_apiservice.dart';
import '../../widgets/customdropdownwidget.dart';

class SourceEntryScreen extends StatefulWidget {
  final SourceMasterModel? source;
  const SourceEntryScreen({super.key, this.source});

  @override
  State<SourceEntryScreen> createState() => _SourceEntryScreenState();
}

class _SourceEntryScreenState extends State<SourceEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final SourceApiService _apiService = SourceApiService();
  final CustomerInterestApiservice _apiService1 = CustomerInterestApiservice();

  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isDropdownDataLoaded = false;

  String _sourceNo = '';
  String _generatedSourceNo = '';

  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _areas = [];
  List<Map<String, dynamic>> _occupations = [];
  List<Map<String, dynamic>> _refers = [];
  List<Map<String, dynamic>> _agents = [];
  List<Map<String, dynamic>> _sourcingModes = [];
  // List<Map<String, dynamic>> _entryPersons = [];
  List<Map<String, dynamic>> _salesPersons = [];
  List<CustomerInterestModel> _interests = [];
  CustomerInterestModel? _selectedInterest;
  // Selected IDs for dropdowns
  String? _selectedDistrict;
  String? _selectedAreaId;
  String? _selectedOccupationId;
  String? _selectedReferById;
  String? _selectedAgentId;
  String? _selectedSourcingModeId;
  // String? _selectedEntryPersonId;
  // String? _selectedInterestId;
  String? _selectedSalesPersonId;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _mobileNoController = TextEditingController();
  final TextEditingController _contactNoController = TextEditingController();
  final TextEditingController _whatsappNoController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _backgroundNetworkController =
      TextEditingController();
  // final TextEditingController _customerInterestController =
  //     TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController1 = TextEditingController();

  late FocusNode _nameFocusNode;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.source != null;
    _nameFocusNode = FocusNode();

    _loadDropdownData();

    if (!_isEditMode) {
      _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
      _getNextSourceNumber();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _nameFocusNode.requestFocus();
      });
    });
  }

  Future<void> _getNextSourceNumber() async {
    String nextNo = await _apiService.getNextSourceNumber(context);
    setState(() {
      _generatedSourceNo = nextNo;
    });
  }

  Future<void> _loadDropdownData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _apiService.fetchDistricts(context),
        _apiService.fetchAreas(context),
        _apiService.fetchOccupations(context),
        _apiService.fetchRefers(context),
        _apiService.fetchAgents(context),
        _apiService.fetchSourcingModes(context),
        // _apiService.fetchEntryPersons(context),
        _apiService.fetchSalesPersons(context),
      ]);
      final res = await _apiService1.fetchInterests(context);

      if (mounted) {
        setState(() {
          _districts = results[0];
          _areas = results[1];
          _occupations = results[2];
          _refers = results[3];
          _agents = results[4];
          _sourcingModes = results[5];
          // _entryPersons = results[6];
          // _salesPersons = results[7];
          _salesPersons = results[6];
          _interests = res;
          _isDropdownDataLoaded = true;
        });

        if (_isEditMode) {
          _loadSourceData();
        }
      }
    } catch (e) {
      print('error $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading dropdown data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadSourceData() {
    if (widget.source != null && _isDropdownDataLoaded) {
      setState(() {
        _sourceNo = widget.source!.sourceNo;
        _dateController.text = widget.source!.sourceDateDisplay.isNotEmpty
            ? widget.source!.sourceDateDisplay
            : widget.source!.sourceDate;
        _nameController.text = widget.source!.name;
        _companyNameController.text = widget.source!.companyName;
        _mobileNoController.text = widget.source!.mobileNo;
        _contactNoController.text = widget.source!.contactNo;
        _whatsappNoController.text = widget.source!.whatsappNo;
        _addressController.text = widget.source!.address;
        _backgroundNetworkController.text = widget.source!.backgroundNetwork;
        _selectedInterest = _interests.firstWhere(
          (item) => item.id == widget.source!.customerInterest,
        );
        // _customerInterestController.text = widget.source!.customerInterest;
        _notesController.text = widget.source!.notes;

        _selectedDistrict = widget.source!.branch;
        _selectedAreaId = widget.source!.areaId.isNotEmpty
            ? widget.source!.areaId
            : null;
        _selectedOccupationId = widget.source!.occupationId.isNotEmpty
            ? widget.source!.occupationId
            : null;
        _selectedReferById = widget.source!.referById.isNotEmpty
            ? widget.source!.referById
            : null;
        _selectedAgentId = widget.source!.agentId.isNotEmpty
            ? widget.source!.agentId
            : null;
        _selectedSourcingModeId = widget.source!.sourcingModeId;
        // _selectedEntryPersonId = widget.source!.entryPersonId.isNotEmpty
        //     ? widget.source!.entryPersonId
        //     : null;
        _selectedSalesPersonId = widget.source!.salesPersonId.isNotEmpty
            ? widget.source!.salesPersonId
            : null;
      });
    }
    print('_loadSourceData out');
  }

  String _getNameById(List<Map<String, dynamic>> items, String? id) {
    if (id == null || id.isEmpty) return '';
    final item = items.firstWhere(
      (item) => item['id'].toString() == id,
      orElse: () => {},
    );
    return item['name'] ?? '';
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _submitForm() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final loggedName = prefs.getString('username').toString();
    final loggedId = prefs.getString('id').toString();
    if (!_formKey.currentState!.validate()) return;

    // Validate required dropdowns
    if (_selectedDistrict == null || _selectedDistrict!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Branch'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedSourcingModeId == null || _selectedSourcingModeId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Sourcing Mode'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String result;

      if (_isEditMode) {
        result = await _apiService.updateSource(
          context: context,
          sourceId: widget.source!.id,
          sourceDate: _dateController.text,
          branch: _selectedDistrict!,
          name: _nameController.text,
          companyName: _companyNameController.text,
          mobileNo: _mobileNoController.text,
          contactNo: _contactNoController.text,
          whatsappNo: _whatsappNoController.text,
          area: _getNameById(_areas, _selectedAreaId),
          areaId: _selectedAreaId ?? '',
          address: _addressController.text,
          occupation: _getNameById(_occupations, _selectedOccupationId),
          occupationId: _selectedOccupationId,
          referBy: _getNameById(_refers, _selectedReferById),
          referById: _selectedReferById,
          agent: _getNameById(_agents, _selectedAgentId),
          agentId: _selectedAgentId,
          sourcingMode: _getNameById(_sourcingModes, _selectedSourcingModeId),
          sourcingModeId: _selectedSourcingModeId!,
          // entryPerson: _getNameById(_entryPersons, _selectedEntryPersonId),
          entryPerson: loggedName,
          // entryPersonId: _selectedEntryPersonId,
          entryPersonId: loggedId,
          backgroundNetwork: _backgroundNetworkController.text,
          // customerInterest: _customerInterestController.text,
          customerInterest: _selectedInterest!.id,
          notes: _notesController.text,
          salesPerson: _getNameById(_salesPersons, _selectedSalesPersonId),
          salesPersonId: _selectedSalesPersonId,
        );
      } else {
        result = await _apiService.insertSource(
          context: context,
          sourceDate: _dateController.text,
          branch: _selectedDistrict!,
          name: _nameController.text,
          companyName: _companyNameController.text,
          mobileNo: _mobileNoController.text,
          contactNo: _contactNoController.text,
          whatsappNo: _whatsappNoController.text,
          area: _getNameById(_areas, _selectedAreaId),
          areaId: _selectedAreaId ?? '',
          address: _addressController.text,
          occupation: _getNameById(_occupations, _selectedOccupationId),
          occupationId: _selectedOccupationId,
          referBy: _getNameById(_refers, _selectedReferById),
          referById: _selectedReferById,
          agent: _getNameById(_agents, _selectedAgentId),
          agentId: _selectedAgentId,
          sourcingMode: _getNameById(_sourcingModes, _selectedSourcingModeId),
          sourcingModeId: _selectedSourcingModeId!,
          // entryPerson: _getNameById(_entryPersons, _selectedEntryPersonId),
          entryPerson: loggedName,
          // entryPersonId: _selectedEntryPersonId,
          entryPersonId: loggedId,
          backgroundNetwork: _backgroundNetworkController.text,
          customerInterest: _selectedInterest!.id,
          // customerInterest: _customerInterestController.text,
          notes: _notesController.text,
          salesPerson: _getNameById(_salesPersons, _selectedSalesPersonId),
          salesPersonId: _selectedSalesPersonId,
        );
      }

      if (result == "Success") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Source updated successfully!'
                  : 'Source created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    FocusNode? focusNode,
    bool isRequired = false,
    bool isTextArea = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3748),
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: isTextArea ? 98 : 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            maxLines: isTextArea ? 4 : maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 16,
                color: Color(0xFF999999),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isTextArea ? 12 : 0,
              ),
              border: InputBorder.none,
            ),
            validator: (value) {
              if (isRequired && (value == null || value.isEmpty)) {
                return 'This field is required';
              }
              if (label.contains('Mobile') &&
                  value != null &&
                  value.isNotEmpty) {
                final phoneRegex = RegExp(r'^[0-9]{10}$');
                if (!phoneRegex.hasMatch(value)) {
                  return 'Enter valid 10-digit mobile number';
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required List<Map<String, dynamic>> items,
    required String? selectedId,
    required ValueChanged<String?> onChanged,
    bool isRequired = true,
    String? hint,
  }) {
    String? selectedName = selectedId != null && selectedId.isNotEmpty
        ? _getNameById(items, selectedId)
        : null;

    List<String> itemNames = items
        .map((item) => item['name'] as String)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3748),
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 8),
        CustomDropdownSearch(
          label: "",
          isRequired: isRequired,
          items: itemNames,
          selectedItem: selectedName,
          // hint: hint,
          onChanged: (value) {
            if (value != null && value.isNotEmpty) {
              final selectedItem = items.firstWhere(
                (item) => item['name'] == value,
                orElse: () => {},
              );
              onChanged(selectedItem['id']?.toString());
            } else {
              onChanged(null);
            }
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _dateController.dispose();
    _nameController.dispose();
    _companyNameController.dispose();
    _mobileNoController.dispose();
    _contactNoController.dispose();
    _whatsappNoController.dispose();
    _addressController.dispose();
    _backgroundNetworkController.dispose();
    // _customerInterestController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  OutlineInputBorder border({Color color = const Color(0xFFD1D5DB)}) {
    return OutlineInputBorder(
      borderSide: BorderSide(color: color, width: 1.4),
      borderRadius: BorderRadius.circular(6),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Source' : 'Add Source'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Source No (Auto-generated)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Sourcing No: ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isEditMode ? _sourceNo : _generatedSourceNo,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4318D1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Date Field
                      GestureDetector(
                        onTap: _selectDate,
                        child: AbsorbPointer(
                          child: _buildInputField(
                            label: 'Date',
                            hint: 'DD/MM/YYYY',
                            controller: _dateController,
                            isRequired: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Branch Dropdown (District)
                      _buildDropdownField(
                        label: 'Branch',
                        items: _districts,
                        selectedId: _selectedDistrict,
                        isRequired: true,
                        hint: 'Select District',
                        onChanged: (value) {
                          setState(() {
                            _selectedDistrict = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Name
                      _buildInputField(
                        label: 'Name',
                        hint: 'Enter full name',
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        isRequired: true,
                      ),
                      const SizedBox(height: 20),

                      // Company Name
                      _buildInputField(
                        label: 'Company Name',
                        hint: 'Enter company name',
                        controller: _companyNameController,
                      ),
                      const SizedBox(height: 20),

                      // Mobile No (Unique)
                      _buildInputField(
                        label: 'Mobile No',
                        hint: '9876543210',
                        controller: _mobileNoController,
                        isRequired: true,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),

                      // Contact No & WhatsApp No Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              label: 'Contact No',
                              hint: '9876543210',
                              controller: _contactNoController,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInputField(
                              label: 'WhatsApp No',
                              hint: '9876543210',
                              controller: _whatsappNoController,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Area Dropdown
                      _buildDropdownField(
                        label: 'Area',
                        items: _areas,
                        selectedId: _selectedAreaId,
                        isRequired: false,
                        hint: 'Select Area',
                        onChanged: (value) {
                          setState(() {
                            _selectedAreaId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Address
                      _buildInputField(
                        label: 'Address',
                        hint: 'Enter complete address',
                        controller: _addressController,
                        isTextArea: true,
                      ),
                      const SizedBox(height: 20),

                      // Occupation Dropdown
                      _buildDropdownField(
                        label: 'Occupation',
                        items: _occupations,
                        selectedId: _selectedOccupationId,
                        isRequired: false,
                        hint: 'Select Occupation',
                        onChanged: (value) {
                          setState(() {
                            _selectedOccupationId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Refer By & Agent Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Refer By',
                              items: _refers,
                              selectedId: _selectedReferById,
                              isRequired: false,
                              hint: 'Select Referrer',
                              onChanged: (value) {
                                setState(() {
                                  _selectedReferById = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Agent',
                              items: _agents,
                              selectedId: _selectedAgentId,
                              isRequired: false,
                              hint: 'Select Agent',
                              onChanged: (value) {
                                setState(() {
                                  _selectedAgentId = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Sourcing Mode (Required)
                      _buildDropdownField(
                        label: 'Sourcing Mode',
                        items: _sourcingModes,
                        selectedId: _selectedSourcingModeId,
                        isRequired: true,
                        hint: 'Select Sourcing Mode',
                        onChanged: (value) {
                          setState(() {
                            _selectedSourcingModeId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Entry Person & Sales Person Row
                      Row(
                        children: [
                          // Expanded(
                          //   child: _buildDropdownField(
                          //     label: 'Entry Person',
                          //     items: _entryPersons,
                          //     selectedId: _selectedEntryPersonId,
                          //     isRequired: false,
                          //     hint: 'Select Entry Person',
                          //     onChanged: (value) {
                          //       setState(() {
                          //         _selectedEntryPersonId = value;
                          //       });
                          //     },
                          //   ),
                          // ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Customer Interest',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2D3748),
                                      ),
                                    ),

                                    const Text(
                                      ' *',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                DropdownSearch<CustomerInterestModel>(
                                  selectedItem: _selectedInterest,

                                  compareFn: (item, selectedItem) =>
                                      item.id == selectedItem.id,

                                  items: (filter, loadProps) => _interests,

                                  itemAsString: (CustomerInterestModel item) =>
                                      item.interest,

                                  decoratorProps: DropDownDecoratorProps(
                                    baseStyle: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFFF3F4F6),
                                      border: border(),
                                      enabledBorder: border(),
                                      focusedBorder: border(),
                                      disabledBorder: border(
                                        color: const Color(0xFFD1D5DB),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 14,
                                          ),
                                      hintText: "Select Interest",
                                      hintStyle: const TextStyle(
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ),

                                  onChanged: (CustomerInterestModel? value) {
                                    setState(() {
                                      _selectedInterest = value;
                                    });
                                  },

                                  popupProps: PopupProps.menu(
                                    showSearchBox: true,

                                    searchFieldProps: TextFieldProps(
                                      controller: _searchController1,
                                      decoration: InputDecoration(
                                        hintText: 'Search...',
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            _searchController1.clear();
                                          },
                                        ),
                                      ),
                                    ),

                                    menuProps: MenuProps(
                                      borderRadius: BorderRadius.circular(12),
                                      elevation: 6,
                                      color: Colors.white,
                                      backgroundColor: Colors.white,
                                    ),

                                    itemBuilder:
                                        (
                                          context,
                                          CustomerInterestModel item,
                                          bool isDisabled,
                                          bool isSelected,
                                        ) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            child: Text(
                                              item.interest,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isSelected
                                                    ? Theme.of(
                                                        context,
                                                      ).primaryColor
                                                    : Colors.black,
                                              ),
                                            ),
                                          );
                                        },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Sales Person',
                              items: _salesPersons,
                              selectedId: _selectedSalesPersonId,
                              isRequired: false,
                              hint: 'Select Sales Person',
                              onChanged: (value) {
                                setState(() {
                                  _selectedSalesPersonId = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Background Network
                      _buildInputField(
                        label: 'Background Network',
                        hint: 'Enter background network details',
                        controller: _backgroundNetworkController,
                      ),
                      const SizedBox(height: 20),

                      // Customer Interest
                      // _buildInputField(
                      //   label: 'Customer Interest',
                      //   hint: 'Enter customer interests',
                      //   controller: _customerInterestController,
                      // ),
                      // const SizedBox(height: 20),

                      // Notes
                      _buildInputField(
                        label: 'Notes',
                        hint: 'Enter any additional notes',
                        controller: _notesController,
                        isTextArea: true,
                      ),
                      const SizedBox(height: 30),

                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF4A5568),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4318D1),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              _isEditMode ? 'Update Source' : 'Create Source',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
