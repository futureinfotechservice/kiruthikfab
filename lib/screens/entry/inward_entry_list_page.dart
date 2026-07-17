import 'package:flutter/material.dart';
import 'package:kiruthikfab/models/inward_entry_model.dart';
import 'package:kiruthikfab/screens/entry/widgets.dart';
import 'package:kiruthikfab/services/inventory_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../indigator/main.dart';

class InwardEntriesListPage extends StatefulWidget {
  const InwardEntriesListPage({Key? key}) : super(key: key);

  @override
  State<InwardEntriesListPage> createState() => InwardEntriesListPageState();
}

class InwardEntriesListPageState extends State<InwardEntriesListPage> {
  final _inwardService = InventoryApiService();
  List<InwardEntry> _entries = [];
  bool _isLoading = true;
  String _companyId = '';

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _companyId = prefs.getString('companyid') ?? '';

    if (_companyId.isNotEmpty) {
      final entries = await _inwardService.getInwardEntries(_companyId);
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Inward Entries History'),

        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularWaveProgress())
          : _entries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Inward Entries',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add inward entries using the form',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : InwardListView(inward: _entries, isFull: true),
    );
  }
}
