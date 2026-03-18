import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/modelmaster_model.dart';
import '../services/model_apiservice.dart';

class ModelMasterScreen extends StatefulWidget {
  const ModelMasterScreen({super.key});

  @override
  State<ModelMasterScreen> createState() => _ModelMasterScreenState();
}

class _ModelMasterScreenState extends State<ModelMasterScreen> {
  final _formKey = GlobalKey<FormState>();
  final ModelApiService _apiService = ModelApiService();
  final TextEditingController _modelNameController = TextEditingController();

  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isListLoading = true;

  // Store the model being edited
  ModelMasterModel? _editingModel;

  List<ModelMasterModel> _models = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  @override
  void dispose() {
    _modelNameController.dispose();
    super.dispose();
  }

  Future<void> _loadModels() async {
    if (!mounted) return;

    setState(() {
      _isListLoading = true;
    });

    try {
      final models = await _apiService.fetchModels(context);
      if (mounted) {
        setState(() {
          _models = models;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading models: $e"),
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

      if (_isEditMode && _editingModel != null) {
        // Update existing model
        result = await _apiService.updateModel(
          context: context,
          modelId: _editingModel!.id,
          modelname: _modelNameController.text,
        );
      } else {
        // Insert new model
        result = await _apiService.insertModel(
          context: context,
          modelname: _modelNameController.text,
        );
      }

      if (result == "Success") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEditMode
                    ? 'Model updated successfully!'
                    : 'Model created successfully!'
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form and reload list
        _cancelEdit();
        await _loadModels();
      }
    } catch (e) {
      print("Submit Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteModel(String modelId, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this model?'),
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
      final result = await _apiService.deleteModel(context, modelId);
      if (result == "Success" && mounted) {
        setState(() {
          _models.removeAt(index);
          // If we were editing this model, cancel edit mode
          if (_editingModel?.id == modelId) {
            _cancelEdit();
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Model deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _editModel(ModelMasterModel model) {
    setState(() {
      _isEditMode = true;
      _editingModel = model;
      _modelNameController.text = model.modelname;
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
      _editingModel = null;
      _modelNameController.clear();
    });
  }

  List<ModelMasterModel> get _filteredModels {
    if (_searchQuery.isEmpty) return _models;
    return _models.where((model) {
      return model.modelname.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Model Master'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadModels,
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
            Text('Processing...', style: TextStyle(fontSize: 16, color: Colors.grey)),
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

                  // Model List Header
                  _buildListHeader(isWeb),

                  const SizedBox(height: 16),

                  // Model List
                  if (_isListLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_filteredModels.isEmpty)
                    _buildEmptyState()
                  else
                    isWeb
                        ? _buildWebTable()
                        : _buildMobileList(),
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
            _isEditMode ? 'Edit Model' : 'Add New Model',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isEditMode
                ? 'Updating: ${_editingModel?.modelname ?? ''}'
                : 'Create a new model record',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
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
            color: Colors.black.withOpacity(0.05),
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
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Model Name',
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
                          controller: _modelNameController,
                          decoration: InputDecoration(
                            hintText: 'Enter model name',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            border: InputBorder.none,
                            suffixIcon: _isEditMode
                                ? IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: _cancelEdit,
                              tooltip: 'Cancel Edit',
                            )
                                : null,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Model name is required';
                            }
                            if (value.length < 2) {
                              return 'Model name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (isWeb) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
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
                        _isEditMode ? 'Update Model' : 'Create Model',
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
          'Model List',
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
              hintText: 'Search models...',
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
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No matching models found'
                  : 'No models yet',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
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
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 1,
                  child: Text(
                    'S.No',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'Model Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Actions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
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
            itemCount: _filteredModels.length,
            itemBuilder: (context, index) {
              final model = _filteredModels[index];
              final bool isEditing = _editingModel?.id == model.id;

              return Container(
                decoration: BoxDecoration(
                  color: isEditing ? Colors.blue.shade50 : null,
                  border: index < _filteredModels.length - 1
                      ? const Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0)),
                  )
                      : null,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: isEditing ? FontWeight.bold : FontWeight.normal,
                          color: isEditing ? Colors.blue : Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        model.modelname,
                        style: TextStyle(
                          fontWeight: isEditing ? FontWeight.bold : FontWeight.normal,
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
                            onPressed: isEditing ? null : () => _editModel(model),
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
                            onPressed: () => _deleteModel(model.id, index),
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
      itemCount: _filteredModels.length,
      itemBuilder: (context, index) {
        final model = _filteredModels[index];
        final bool isEditing = _editingModel?.id == model.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isEditing ? Colors.blue.shade50 : Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              model.modelname,
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
                  onPressed: isEditing ? null : () => _editModel(model),
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
                  onPressed: () => _deleteModel(model.id, index),
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                    size: 22,
                  ),
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