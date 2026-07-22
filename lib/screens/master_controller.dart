// controllers/master_controller.dart
import 'package:flutter/material.dart';

import '../models/master_items.dart';

class MasterController extends ChangeNotifier {
  final String title;
  final List<MasterItem> _items = [];
  List<MasterItem> _filteredItems = [];
  MasterItem? _editingItem;
  bool _isLoading = false;
  bool _isListLoading = false;
  bool _isEditMode = false;
  String _searchQuery = '';

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController? descriptionController;

  MasterController({required this.title, this.descriptionController});

  // Getters
  List<MasterItem> get items => _items;
  List<MasterItem> get filteredItems => _filteredItems;
  MasterItem? get editingItem => _editingItem;
  bool get isLoading => _isLoading;
  bool get isListLoading => _isListLoading;
  bool get isEditMode => _isEditMode;
  String get searchQuery => _searchQuery;

  // Setters
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  set isListLoading(bool value) {
    _isListLoading = value;
    notifyListeners();
  }

  // Initialize with data
  void initializeItems(List<MasterItem> items) {
    _items.clear();
    _items.addAll(items);
    _applyFilter();
    notifyListeners();
  }

  // Search
  void updateSearch(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredItems = List.from(_items);
    } else {
      _filteredItems = _items
          .where(
            (item) =>
                item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (item.description?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    }
  }

  // CRUD Operations
  void startCreate() {
    _editingItem = null;
    _isEditMode = false;
    nameController.clear();
    descriptionController?.clear();
    notifyListeners();
  }

  void startEdit(MasterItem item) {
    _editingItem = item;
    _isEditMode = true;
    nameController.text = item.name;
    descriptionController?.text = item.description ?? '';
    notifyListeners();
  }

  void cancelEdit() {
    _editingItem = null;
    _isEditMode = false;
    nameController.clear();
    descriptionController?.clear();
    notifyListeners();
  }

  void addItem(MasterItem item) {
    _items.add(item);
    _applyFilter();
    notifyListeners();
  }

  void updateItem(MasterItem item) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
      _applyFilter();
      notifyListeners();
    }
  }

  void deleteItem(String id) {
    _items.removeWhere((item) => item.id == id);
    _applyFilter();
    notifyListeners();
  }

  // Form validation
  bool validateForm() {
    if (nameController.text.trim().isEmpty) {
      return false;
    }
    if (nameController.text.trim().length < 2) {
      return false;
    }
    return true;
  }

  MasterItem getFormData() {
    return MasterItem(
      id: _editingItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameController.text.trim(),
      description: descriptionController?.text.trim(),
      createdAt: _editingItem?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController?.dispose();
    super.dispose();
  }
}
