import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import '../../../models/CustomerMasterModel.dart';
import '../../../services/customer_apiservice.dart';
import '../../../widgets/customdropdownwidget.dart';

class CustomerMasterEntryScreen extends StatefulWidget {
  final CustomerMasterModel? customer;
  const CustomerMasterEntryScreen({super.key, this.customer});

  @override
  State<CustomerMasterEntryScreen> createState() =>
      _CustomerMasterEntryScreenState();
}

class _CustomerMasterEntryScreenState extends State<CustomerMasterEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final CustomerApiService _apiService = CustomerApiService();

  String? _aadharFilePath;
  String? _photoFilePath;
  String? _aadharFileName;
  String? _photoFileName;
  // Uint8List? _aadharBytes;
  // Uint8List? _photoBytes;

  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isDropdownDataLoaded = false;

  // Dropdown data lists
  List<Map<String, dynamic>> _areas = [];
  List<Map<String, dynamic>> _refers = [];
  List<Map<String, dynamic>> _incharges = [];
  List<Map<String, dynamic>> _agents = [];
  List<Map<String, dynamic>> _salesPersons = [];
  List<Map<String, dynamic>> _occupations = [];

  // Selected IDs for dropdowns
  String? _selectedAreaId;
  String? _selectedReferId;
  String? _selectedInchargeId;
  String? _selectedAgentId;
  String? _selectedSalesPersonId;
  String? _selectedOccupationId;

  // Focus Nodes
  late FocusNode _customerNameFocusNode;

  final Map<String, TextEditingController> _controllers = {
    'customerName': TextEditingController(),
    'gstNumber': TextEditingController(),
    'address': TextEditingController(),
    'mobile1': TextEditingController(),
    'mobile2': TextEditingController(),
    'whatsapp': TextEditingController(),
  };

  // Dropdown keys for auto-focus
  final GlobalKey<DropdownSearchState<String>> _areaDropdownKey = GlobalKey();
  final GlobalKey<DropdownSearchState<String>> _referDropdownKey = GlobalKey();
  final GlobalKey<DropdownSearchState<String>> _inchargeDropdownKey =
      GlobalKey();
  final GlobalKey<DropdownSearchState<String>> _agentDropdownKey = GlobalKey();
  final GlobalKey<DropdownSearchState<String>> _salesPersonDropdownKey =
      GlobalKey();
  final GlobalKey<DropdownSearchState<String>> _occupationDropdownKey =
      GlobalKey();

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.customer != null;

    _customerNameFocusNode = FocusNode();

    // Load dropdown data first, then load customer data if in edit mode
    _loadDropdownData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _customerNameFocusNode.requestFocus();
        }
      });
    });
  }

  Future<void> _loadDropdownData() async {
    setState(() => _isLoading = true);

    try {
      // Load all dropdown data in parallel for better performance
      final results = await Future.wait([
        _apiService.fetchAreas(context),
        _apiService.fetchRefers(context),
        _apiService.fetchIncharges(context),
        _apiService.fetchAgents(context),
        _apiService.fetchSalesPersons(context),
        _apiService.fetchOccupations(context),
      ]);

      if (mounted) {
        setState(() {
          _areas = results[0];
          _refers = results[1];
          _incharges = results[2];
          _agents = results[3];
          _salesPersons = results[4];
          _occupations = results[5];
          _isDropdownDataLoaded = true;
        });

        // After dropdown data is loaded, load customer data for edit mode
        if (_isEditMode) {
          _loadCustomerData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dropdown data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadCustomerData() {
    if (widget.customer != null && _isDropdownDataLoaded) {
      // Load text fields
      _controllers['customerName']!.text = widget.customer!.customername;
      _controllers['gstNumber']!.text = widget.customer!.gstNo;
      _controllers['address']!.text = widget.customer!.address;
      _controllers['mobile1']!.text = widget.customer!.mobile1;
      _controllers['mobile2']!.text = widget.customer!.mobile2;
      _controllers['whatsapp']!.text = widget.customer!.whatsapp;

      // Set selected IDs from the customer data
      // These IDs should be stored in the database and retrieved in the model
      if (widget.customer!.areaId.isNotEmpty) {
        _selectedAreaId = widget.customer!.areaId;
      } else if (widget.customer!.area.isNotEmpty) {
        // Fallback: try to find ID by name if ID is empty (for backward compatibility)
        _selectedAreaId = _getIdByName(_areas, widget.customer!.area);
      }

      if (widget.customer!.referId.isNotEmpty) {
        _selectedReferId = widget.customer!.referId;
      } else if (widget.customer!.refer.isNotEmpty) {
        _selectedReferId = _getIdByName(_refers, widget.customer!.refer);
      }

      if (widget.customer!.inchargeId.isNotEmpty) {
        _selectedInchargeId = widget.customer!.inchargeId;
      } else if (widget.customer!.incharge.isNotEmpty) {
        _selectedInchargeId = _getIdByName(
          _incharges,
          widget.customer!.incharge,
        );
      }

      if (widget.customer!.agentId.isNotEmpty) {
        _selectedAgentId = widget.customer!.agentId;
      } else if (widget.customer!.agent.isNotEmpty) {
        _selectedAgentId = _getIdByName(_agents, widget.customer!.agent);
      }

      if (widget.customer!.salespersonId.isNotEmpty) {
        _selectedSalesPersonId = widget.customer!.salespersonId;
      } else if (widget.customer!.salesperson.isNotEmpty) {
        _selectedSalesPersonId = _getIdByName(
          _salesPersons,
          widget.customer!.salesperson,
        );
      }

      if (widget.customer!.occupationId.isNotEmpty) {
        _selectedOccupationId = widget.customer!.occupationId;
      } else if (widget.customer!.occupation.isNotEmpty) {
        _selectedOccupationId = _getIdByName(
          _occupations,
          widget.customer!.occupation,
        );
      }

      // Load file references
      if (widget.customer!.aadharurl.isNotEmpty) {
        setState(() {
          _aadharFileName = widget.customer!.aadharurl.split('/').last;
          _aadharFilePath = widget.customer!.aadharurl;
        });
      }

      if (widget.customer!.photourl.isNotEmpty) {
        setState(() {
          _photoFileName = widget.customer!.photourl.split('/').last;
          _photoFilePath = widget.customer!.photourl;
        });
      }

      // Trigger rebuild to update dropdown selections
      setState(() {});
    }
  }

  // Helper method to find ID by name from dropdown list
  String? _getIdByName(List<Map<String, dynamic>> items, String? name) {
    if (name == null || name.isEmpty) return null;
    final item = items.firstWhere(
      (item) => item['name'].toString().toLowerCase() == name.toLowerCase(),
      orElse: () => {},
    );
    return item['id']?.toString();
  }

  // Helper method to get name by ID
  String _getNameById(List<Map<String, dynamic>> items, String? id) {
    if (id == null || id.isEmpty) return '';
    final item = items.firstWhere(
      (item) => item['id'].toString() == id,
      orElse: () => {},
    );
    return item['name'] ?? '';
  }

  @override
  void dispose() {
    _customerNameFocusNode.dispose();
    _controllers.forEach((key, controller) => controller.dispose());
    // _aadharBytes = null;
    // _photoBytes = null;
    super.dispose();
  }

  // void _showFilePreview(BuildContext context, String fileName, String label) {
  //   Uint8List? fileBytes;
  //   if (label.contains('Aadhar')) {
  //     fileBytes = _aadharBytes;
  //   } else {
  //     fileBytes = _photoBytes;
  //   }
  //
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text('Preview: $fileName'),
  //       content: Container(
  //         constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             if (fileBytes != null)
  //               Image.memory(
  //                 fileBytes,
  //                 fit: BoxFit.contain,
  //                 height: 300,
  //               )
  //             else
  //               const Text('File data not available for preview'),
  //           ],
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('Close'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate dropdown selections
    if (_selectedAreaId == null || _selectedAreaId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Area'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedReferId == null || _selectedReferId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Referred By Name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedInchargeId == null || _selectedInchargeId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Incharge'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedAgentId == null || _selectedAgentId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Agent'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedSalesPersonId == null || _selectedSalesPersonId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Sales Person'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String result;

      if (_isEditMode) {
        result = await _apiService.updateCustomer(
          context: context,
          customerId: widget.customer!.id,
          customername: _controllers['customerName']!.text,
          mobile1: _controllers['mobile1']!.text,
          mobile2: _controllers['mobile2']!.text,
          whatsapp: _controllers['whatsapp']!.text,
          address: _controllers['address']!.text,
          area: _getNameById(_areas, _selectedAreaId),
          areaId: _selectedAreaId!,
          gstNo: _controllers['gstNumber']!.text,
          refer: _getNameById(_refers, _selectedReferId),
          referId: _selectedReferId!,
          incharge: _getNameById(_incharges, _selectedInchargeId),
          inchargeId: _selectedInchargeId!,
          agent: _getNameById(_agents, _selectedAgentId),
          agentId: _selectedAgentId!,
          salesperson: _getNameById(_salesPersons, _selectedSalesPersonId),
          salespersonId: _selectedSalesPersonId!,
          occupation: _getNameById(_occupations, _selectedOccupationId),
          occupationId: _selectedOccupationId,
          aadharFile: _aadharFilePath,
          photoFile: _photoFilePath,
          aadharFileName: _aadharFileName,
          photoFileName: _photoFileName,
        );
      } else {
        result = await _apiService.insertCustomer(
          context: context,
          customername: _controllers['customerName']!.text,
          mobile1: _controllers['mobile1']!.text,
          mobile2: _controllers['mobile2']!.text,
          whatsapp: _controllers['whatsapp']!.text,
          address: _controllers['address']!.text,
          area: _getNameById(_areas, _selectedAreaId),
          areaId: _selectedAreaId!,
          gstNo: _controllers['gstNumber']!.text,
          refer: _getNameById(_refers, _selectedReferId),
          referId: _selectedReferId!,
          incharge: _getNameById(_incharges, _selectedInchargeId),
          inchargeId: _selectedInchargeId!,
          agent: _getNameById(_agents, _selectedAgentId),
          agentId: _selectedAgentId!,
          salesperson: _getNameById(_salesPersons, _selectedSalesPersonId),
          salespersonId: _selectedSalesPersonId!,
          occupation: _getNameById(_occupations, _selectedOccupationId),
          occupationId: _selectedOccupationId,
          aadharFile: _aadharFilePath,
          photoFile: _photoFilePath,
          aadharFileName: _aadharFileName,
          photoFileName: _photoFileName,
        );
      }

      if (result == "Success") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Customer updated successfully!'
                  : 'Customer created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
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
    String? Function(String?)? validator,
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
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
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
            maxLines: isTextArea ? 4 : 1,
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
            validator:
                validator ??
                (value) {
                  if (isRequired && (value == null || value.isEmpty)) {
                    return 'This field is required';
                  }
                  if (keyboardType == TextInputType.phone &&
                      value != null &&
                      value.isNotEmpty) {
                    final phoneRegex = RegExp(r'^[0-9]{10}$');
                    if (!phoneRegex.hasMatch(value)) {
                      return 'Enter valid 10-digit mobile number';
                    }
                  }
                  if (label.contains('GST') &&
                      value != null &&
                      value.isNotEmpty) {
                    final gstRegex = RegExp(
                      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
                    );
                    if (!gstRegex.hasMatch(value)) {
                      return 'Enter valid GST number';
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
    GlobalKey<DropdownSearchState<String>>? dropdownKey,
  }) {
    // Get the selected name based on the ID
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
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        CustomDropdownSearch(
          label: "",
          isRequired: isRequired,
          items: itemNames,
          selectedItem: selectedName,
          dropdownKey: dropdownKey,
          onChanged: (value) {
            if (value != null && value.isNotEmpty) {
              // Find the ID for the selected name
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

  // Widget _buildUploadArea({
  //   required String label,
  //   required String description,
  //   required String fileTypes,
  //   required VoidCallback onTap,
  //   String? fileName,
  //   String? fileUrl,
  // }) {
  //   bool hasExistingFile = fileUrl != null && fileUrl.isNotEmpty;
  //   bool hasNewFile = fileName != null && fileName.isNotEmpty;
  //
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         label,
  //         style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF2D3748)),
  //       ),
  //       const SizedBox(height: 8),
  //       GestureDetector(
  //         onTap: onTap,
  //         child: Container(
  //           width: double.infinity,
  //           height: 132,
  //           decoration: BoxDecoration(
  //             borderRadius: BorderRadius.circular(8),
  //             border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
  //           ),
  //           child: hasExistingFile || hasNewFile
  //               ? Center(
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 const Icon(Icons.file_present, size: 32, color: Colors.green),
  //                 const SizedBox(height: 8),
  //                 Text(
  //                   fileName != null
  //                       ? (fileName.length > 30 ? '${fileName.substring(0, 27)}...' : fileName)
  //                       : (hasExistingFile ? 'Existing file' : ''),
  //                   style: const TextStyle(fontSize: 14, color: Color(0xFF4A5568), fontWeight: FontWeight.w500),
  //                   textAlign: TextAlign.center,
  //                 ),
  //                 const SizedBox(height: 4),
  //                 Text('Click to change', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
  //                 const SizedBox(height: 8),
  //                 if (hasNewFile && !hasExistingFile)
  //                   ElevatedButton.icon(
  //                     onPressed: () => _showFilePreview(context, fileName!, label),
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: Colors.blue,
  //                       foregroundColor: Colors.white,
  //                       minimumSize: const Size(120, 36),
  //                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //                     ),
  //                     icon: const Icon(Icons.preview, size: 16),
  //                     label: const Text('Preview', style: TextStyle(fontSize: 12)),
  //                   ),
  //               ],
  //             ),
  //           )
  //               : Column(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               Container(
  //                 width: 32,
  //                 height: 32,
  //                 decoration: BoxDecoration(
  //                   color: Colors.grey[100],
  //                   borderRadius: BorderRadius.circular(8),
  //                 ),
  //                 child: const Icon(Icons.add, size: 24, color: Colors.grey),
  //               ),
  //               const SizedBox(height: 12),
  //               Text(description, style: const TextStyle(fontSize: 14, color: Color(0xFF4A5568))),
  //               const SizedBox(height: 4),
  //               Text(fileTypes, style: const TextStyle(fontSize: 12, color: Color(0xFFA0AEC0))),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Customer' : 'Add Customer'),
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
                      _buildInputField(
                        label: 'Customer Name',
                        hint: 'Enter customer full name',
                        controller: _controllers['customerName']!,
                        focusNode: _customerNameFocusNode,
                        isRequired: true,
                      ),
                      const SizedBox(height: 20),

                      _buildInputField(
                        label: 'GST Number',
                        hint: '22AAAAA0000A1Z5',
                        controller: _controllers['gstNumber']!,
                      ),
                      const SizedBox(height: 20),

                      _buildInputField(
                        label: 'Address',
                        hint: 'Enter complete address',
                        controller: _controllers['address']!,
                        isRequired: true,
                        isTextArea: true,
                      ),
                      const SizedBox(height: 20),

                      _buildDropdownField(
                        label: 'Area',
                        items: _areas,
                        selectedId: _selectedAreaId,
                        isRequired: true,
                        dropdownKey: _areaDropdownKey,
                        onChanged: (value) {
                          setState(() {
                            _selectedAreaId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              label: 'Mobile Number 1',
                              hint: '9876543210',
                              controller: _controllers['mobile1']!,
                              isRequired: true,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInputField(
                              label: 'Mobile Number 2',
                              hint: '9876543210',
                              controller: _controllers['mobile2']!,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _buildInputField(
                        label: 'WhatsApp Number',
                        hint: '9876543210',
                        controller: _controllers['whatsapp']!,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),

                      _buildDropdownField(
                        label: 'Referred By Name',
                        items: _refers,
                        selectedId: _selectedReferId,
                        isRequired: true,
                        dropdownKey: _referDropdownKey,
                        onChanged: (value) {
                          setState(() {
                            _selectedReferId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Incharge',
                              items: _incharges,
                              selectedId: _selectedInchargeId,
                              isRequired: true,
                              dropdownKey: _inchargeDropdownKey,
                              onChanged: (value) {
                                setState(() {
                                  _selectedInchargeId = value;
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
                              isRequired: true,
                              dropdownKey: _agentDropdownKey,
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

                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Sales Person',
                              items: _salesPersons,
                              selectedId: _selectedSalesPersonId,
                              isRequired: true,
                              dropdownKey: _salesPersonDropdownKey,
                              onChanged: (value) {
                                setState(() {
                                  _selectedSalesPersonId = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Occupation',
                              items: _occupations,
                              selectedId: _selectedOccupationId,
                              isRequired: false,
                              dropdownKey: _occupationDropdownKey,
                              onChanged: (value) {
                                setState(() {
                                  _selectedOccupationId = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // File upload section (uncomment and implement if needed)
                      // Row(
                      //   children: [
                      //     Expanded(
                      //       child: _buildUploadArea(
                      //         label: 'Aadhar Upload',
                      //         description: 'Click to upload Aadhar document',
                      //         fileTypes: 'JPG, PNG up to 5MB',
                      //         onTap: _pickAadharFile,
                      //         fileName: _aadharFileName,
                      //         fileUrl: widget.customer?.aadharurl,
                      //       ),
                      //     ),
                      //     const SizedBox(width: 16),
                      //     Expanded(
                      //       child: _buildUploadArea(
                      //         label: 'Photo Upload',
                      //         description: 'Click to upload customer photo',
                      //         fileTypes: 'JPG, PNG up to 5MB',
                      //         onTap: _pickPhotoFile,
                      //         fileName: _photoFileName,
                      //         fileUrl: widget.customer?.photourl,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      // const SizedBox(height: 30),
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
                              shadowColor: const Color(
                                0xFF4318D1,
                              ).withValues(alpha: 0.2),
                            ),
                            child: Text(
                              _isEditMode
                                  ? 'Update Customer'
                                  : 'Create Customer',
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

// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
//
// import '../models/CustomerMasterModel.dart';
// import '../services/customer_apiservice.dart';
//
// class CustomerMasterEntryScreen extends StatefulWidget {
//   final CustomerMasterModel? customer;
//   const CustomerMasterEntryScreen({super.key, this.customer});
//
//   @override
//   State<CustomerMasterEntryScreen> createState() => _CustomerMasterEntryScreenState();
// }
//
// class _CustomerMasterEntryScreenState extends State<CustomerMasterEntryScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final CustomerApiService _apiService = CustomerApiService();
//
//   String? _aadharFilePath;
//   String? _photoFilePath;
//   String? _aadharFileName;
//   String? _photoFileName;
//   Uint8List? _aadharBytes;
//   Uint8List? _photoBytes;
//
//   bool _isLoading = false;
//   bool _isEditMode = false;
//
//   // Focus Nodes
//   late FocusNode _customerNameFocusNode;
//
//   final Map<String, TextEditingController> _controllers = {
//     'customerName': TextEditingController(),
//     'gstNumber': TextEditingController(),
//     'address': TextEditingController(),
//     'area': TextEditingController(),
//     'areaid': TextEditingController(),
//     'mobile1': TextEditingController(),
//     'mobile2': TextEditingController(),
//     'whatsapp': TextEditingController(),
//     'referredByName': TextEditingController(),
//     'incharge': TextEditingController(),
//     'agent': TextEditingController(),
//     'salesPerson': TextEditingController(),
//     'occupation': TextEditingController(),
//   };
//
//   @override
//   void initState() {
//     super.initState();
//     _isEditMode = widget.customer != null;
//
//     _customerNameFocusNode = FocusNode();
//
//     if (_isEditMode) {
//       _loadCustomerData();
//     }
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Future.delayed(const Duration(milliseconds: 300), () {
//         if (mounted) {
//           _customerNameFocusNode.requestFocus();
//         }
//       });
//     });
//   }
//
//   void _loadCustomerData() {
//     if (widget.customer != null) {
//       _controllers['customerName']!.text = widget.customer!.customername;
//       _controllers['gstNumber']!.text = widget.customer!.gstNo;
//       _controllers['address']!.text = widget.customer!.address;
//       _controllers['area']!.text = widget.customer!.area;
//       _controllers['areaid']!.text = widget.customer!.areaid;
//       _controllers['mobile1']!.text = widget.customer!.mobile1;
//       _controllers['mobile2']!.text = widget.customer!.mobile2;
//       _controllers['whatsapp']!.text = widget.customer!.whatsapp;
//       _controllers['referredByName']!.text = widget.customer!.refer;
//       _controllers['incharge']!.text = widget.customer!.incharge;
//       _controllers['agent']!.text = widget.customer!.agent;
//       _controllers['salesPerson']!.text = widget.customer!.salesperson;
//       _controllers['occupation']!.text = widget.customer!.occupation;
//
//       if (widget.customer!.aadharurl.isNotEmpty) {
//         setState(() {
//           _aadharFileName = widget.customer!.aadharurl.split('/').last;
//           _aadharFilePath = widget.customer!.aadharurl;
//         });
//       }
//
//       if (widget.customer!.photourl.isNotEmpty) {
//         setState(() {
//           _photoFileName = widget.customer!.photourl.split('/').last;
//           _photoFilePath = widget.customer!.photourl;
//         });
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _customerNameFocusNode.dispose();
//     _controllers.forEach((key, controller) => controller.dispose());
//     _aadharBytes = null;
//     _photoBytes = null;
//     super.dispose();
//   }
//
//
//
//   void _showFilePreview(BuildContext context, String fileName, String label) {
//     Uint8List? fileBytes;
//     if (label.contains('Aadhar')) {
//       fileBytes = _aadharBytes;
//     } else {
//       fileBytes = _photoBytes;
//     }
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Preview: $fileName'),
//         content: Container(
//           constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               if (fileBytes != null)
//                 Image.memory(
//                   fileBytes,
//                   fit: BoxFit.contain,
//                   height: 300,
//                 )
//               else
//                 const Text('File data not available for preview'),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _submitForm() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     try {
//       String result;
//
//       if (_isEditMode) {
//         result = await _apiService.updateCustomer(
//           context: context,
//           customerId: widget.customer!.id,
//           customername: _controllers['customerName']!.text,
//           mobile1: _controllers['mobile1']!.text,
//           mobile2: _controllers['mobile2']!.text,
//           whatsapp: _controllers['whatsapp']!.text,
//           address: _controllers['address']!.text,
//           area: _controllers['area']!.text,
//           areaid: _controllers['areaid']!.text,
//           gstNo: _controllers['gstNumber']!.text,
//           refer: _controllers['referredByName']!.text,
//           incharge: _controllers['incharge']!.text,
//           agent: _controllers['agent']!.text,
//           salesperson: _controllers['salesPerson']!.text,
//           occupation: _controllers['occupation']!.text,
//           aadharFile: _aadharFilePath,
//           photoFile: _photoFilePath,
//           aadharFileName: _aadharFileName,
//           photoFileName: _photoFileName,
//         );
//       } else {
//         result = await _apiService.insertCustomer(
//           context: context,
//           customername: _controllers['customerName']!.text,
//           mobile1: _controllers['mobile1']!.text,
//           mobile2: _controllers['mobile2']!.text,
//           whatsapp: _controllers['whatsapp']!.text,
//           address: _controllers['address']!.text,
//           area: _controllers['area']!.text,
//           areaid: _controllers['areaid']!.text,
//           gstNo: _controllers['gstNumber']!.text,
//           refer: _controllers['referredByName']!.text,
//           incharge: _controllers['incharge']!.text,
//           agent: _controllers['agent']!.text,
//           salesperson: _controllers['salesPerson']!.text,
//           occupation: _controllers['occupation']!.text,
//           aadharFile: _aadharFilePath,
//           photoFile: _photoFilePath,
//           aadharFileName: _aadharFileName,
//           photoFileName: _photoFileName,
//         );
//       }
//
//       if (result == "Success") {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(_isEditMode ? 'Customer updated successfully!' : 'Customer created successfully!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//
//         await Future.delayed(const Duration(seconds: 1));
//         if (mounted) {
//           Navigator.of(context).pop(true);
//         }
//       }
//     } catch (e) {
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
//
//   Widget _buildInputField({
//     required String label,
//     required String hint,
//     required TextEditingController controller,
//     FocusNode? focusNode,
//     bool isRequired = false,
//     bool isTextArea = false,
//     TextInputType keyboardType = TextInputType.text,
//     String? Function(String?)? validator,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: Color(0xFF2D3748),
//               ),
//             ),
//             if (isRequired)
//               const Text(
//                 ' *',
//                 style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w500),
//               ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         Container(
//           height: isTextArea ? 98 : 50,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: const Color(0xFFE2E8F0)),
//           ),
//           child: TextFormField(
//             controller: controller,
//             focusNode: focusNode,
//             maxLines: isTextArea ? 4 : 1,
//             keyboardType: keyboardType,
//             decoration: InputDecoration(
//               hintText: hint,
//               hintStyle: const TextStyle(fontSize: 16, color: Color(0xFF999999)),
//               contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isTextArea ? 12 : 0),
//               border: InputBorder.none,
//             ),
//             validator: validator ?? (value) {
//               if (isRequired && (value == null || value.isEmpty)) {
//                 return 'This field is required';
//               }
//               if (keyboardType == TextInputType.phone && value != null && value.isNotEmpty) {
//                 final phoneRegex = RegExp(r'^[0-9]{10}$');
//                 if (!phoneRegex.hasMatch(value)) {
//                   return 'Enter valid 10-digit mobile number';
//                 }
//               }
//               if (label.contains('GST') && value != null && value.isNotEmpty) {
//                 final gstRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
//                 if (!gstRegex.hasMatch(value)) {
//                   return 'Enter valid GST number';
//                 }
//               }
//               return null;
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildUploadArea({
//     required String label,
//     required String description,
//     required String fileTypes,
//     required VoidCallback onTap,
//     String? fileName,
//     String? fileUrl,
//   }) {
//     bool hasExistingFile = fileUrl != null && fileUrl.isNotEmpty;
//     bool hasNewFile = fileName != null && fileName.isNotEmpty;
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF2D3748)),
//         ),
//         const SizedBox(height: 8),
//         GestureDetector(
//           onTap: onTap,
//           child: Container(
//             width: double.infinity,
//             height: 132,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
//             ),
//             child: hasExistingFile || hasNewFile
//                 ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(Icons.file_present, size: 32, color: Colors.green),
//                   const SizedBox(height: 8),
//                   Text(
//                     fileName != null
//                         ? (fileName.length > 30 ? '${fileName.substring(0, 27)}...' : fileName)
//                         : (hasExistingFile ? 'Existing file' : ''),
//                     style: const TextStyle(fontSize: 14, color: Color(0xFF4A5568), fontWeight: FontWeight.w500),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 4),
//                   Text('Click to change', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
//                   const SizedBox(height: 8),
//                   if (hasExistingFile)
//                     // ElevatedButton.icon(
//                     //   onPressed: () => _viewFile(fileUrl!),
//                     //   style: ElevatedButton.styleFrom(
//                     //     backgroundColor: Colors.blue,
//                     //     foregroundColor: Colors.white,
//                     //     minimumSize: const Size(120, 36),
//                     //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                     //   ),
//                     //   icon: const Icon(Icons.remove_red_eye, size: 16),
//                     //   label: const Text('View File', style: TextStyle(fontSize: 12)),
//                     // ),
//                   if (hasNewFile && !hasExistingFile)
//                     ElevatedButton.icon(
//                       onPressed: () => _showFilePreview(context, fileName!, label),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blue,
//                         foregroundColor: Colors.white,
//                         minimumSize: const Size(120, 36),
//                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                       ),
//                       icon: const Icon(Icons.preview, size: 16),
//                       label: const Text('Preview', style: TextStyle(fontSize: 12)),
//                     ),
//                 ],
//               ),
//             )
//                 : Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   width: 32,
//                   height: 32,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[100],
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: const Icon(Icons.add, size: 24, color: Colors.grey),
//                 ),
//                 const SizedBox(height: 12),
//                 Text(description, style: const TextStyle(fontSize: 14, color: Color(0xFF4A5568))),
//                 const SizedBox(height: 4),
//                 Text(fileTypes, style: const TextStyle(fontSize: 12, color: Color(0xFFA0AEC0))),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: Text(_isEditMode ? 'Edit Customer' : 'Add Customer'),
//         backgroundColor: const Color(0xFF1E293B),
//         foregroundColor: Colors.white,
//       ),
//       body: _isLoading
//           ? const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(height: 16),
//             Text('Processing...', style: TextStyle(fontSize: 16, color: Colors.grey)),
//           ],
//         ),
//       )
//           : SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildInputField(
//                   label: 'Customer Name',
//                   hint: 'Enter customer full name',
//                   controller: _controllers['customerName']!,
//                   focusNode: _customerNameFocusNode,
//                   isRequired: true,
//                 ),
//                 const SizedBox(height: 20),
//
//                 _buildInputField(
//                   label: 'GST Number',
//                   hint: '22AAAAA0000A1Z5',
//                   controller: _controllers['gstNumber']!,
//                 ),
//                 const SizedBox(height: 20),
//
//                 _buildInputField(
//                   label: 'Address',
//                   hint: 'Enter complete address',
//                   controller: _controllers['address']!,
//                   isRequired: true,
//                   isTextArea: true,
//                 ),
//                 const SizedBox(height: 20),
//
//                 _buildInputField(
//                   label: 'Area',
//                   hint: 'Enter area/locality',
//                   controller: _controllers['area']!,
//                   isRequired: true,
//                 ),
//                 const SizedBox(height: 20),
//
//                 Row(
//                   children: [
//                     Expanded(
//                       child: _buildInputField(
//                         label: 'Mobile Number 1',
//                         hint: '9876543210',
//                         controller: _controllers['mobile1']!,
//                         isRequired: true,
//                         keyboardType: TextInputType.phone,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: _buildInputField(
//                         label: 'Mobile Number 2',
//                         hint: '9876543210',
//                         controller: _controllers['mobile2']!,
//                         keyboardType: TextInputType.phone,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//
//                 _buildInputField(
//                   label: 'WhatsApp Number',
//                   hint: '9876543210',
//                   controller: _controllers['whatsapp']!,
//                   keyboardType: TextInputType.phone,
//                 ),
//                 const SizedBox(height: 20),
//
//                 _buildInputField(
//                   label: 'Referred By Name',
//                   hint: 'Enter referrer name',
//                   controller: _controllers['referredByName']!,
//                   isRequired: true,
//                 ),
//                 const SizedBox(height: 20),
//
//                 Row(
//                   children: [
//                     Expanded(
//                       child: _buildInputField(
//                         label: 'Incharge',
//                         hint: 'Enter incharge name',
//                         controller: _controllers['incharge']!,
//                         isRequired: true,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: _buildInputField(
//                         label: 'Agent',
//                         hint: 'Enter agent name',
//                         controller: _controllers['agent']!,
//                         isRequired: true,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//
//                 Row(
//                   children: [
//                     Expanded(
//                       child: _buildInputField(
//                         label: 'Sales Person',
//                         hint: 'Enter sales person name',
//                         controller: _controllers['salesPerson']!,
//                         isRequired: true,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: _buildInputField(
//                         label: 'Occupation',
//                         hint: 'Enter occupation',
//                         controller: _controllers['occupation']!,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 30),
//
//                 // Row(
//                 //   children: [
//                 //     Expanded(
//                 //       child: _buildUploadArea(
//                 //         label: 'Aadhar Upload',
//                 //         description: 'Click to upload Aadhar document',
//                 //         fileTypes: 'JPG, PNG up to 5MB',
//                 //         onTap: _pickAadharFile,
//                 //         fileName: _aadharFileName,
//                 //         fileUrl: widget.customer?.aadharurl,
//                 //       ),
//                 //     ),
//                 //     const SizedBox(width: 16),
//                 //     Expanded(
//                 //       child: _buildUploadArea(
//                 //         label: 'Photo Upload',
//                 //         description: 'Click to upload customer photo',
//                 //         fileTypes: 'JPG, PNG up to 5MB',
//                 //         onTap: _pickPhotoFile,
//                 //         fileName: _photoFileName,
//                 //         fileUrl: widget.customer?.photourl,
//                 //       ),
//                 //     ),
//                 //   ],
//                 // ),
//                 // const SizedBox(height: 30),
//
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     OutlinedButton(
//                       onPressed: () => Navigator.of(context).pop(),
//                       style: OutlinedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//                         side: BorderSide(color: Colors.grey[300]!),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                       ),
//                       child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF4A5568))),
//                     ),
//                     const SizedBox(width: 16),
//                     ElevatedButton(
//                       onPressed: _submitForm,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF4318D1),
//                         padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                         elevation: 2,
//                         shadowColor: const Color(0xFF4318D1).withOpacity(0.2),
//                       ),
//                       child: Text(
//                         _isEditMode ? 'Update Customer' : 'Create Customer',
//                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
