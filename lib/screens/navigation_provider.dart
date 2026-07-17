import 'package:flutter/foundation.dart' show ChangeNotifier;

class NavigationProvider with ChangeNotifier {
  int _selectedIndex = 0;
  int _masterSubIndex = 0;
  int _entrySubIndex = 0;
  int _reportSubIndex = 0;
  String _inventoryNo = '';

  int get selectedIndex => _selectedIndex;

  int get masterSubIndex => _masterSubIndex;

  int get entrySubIndex => _entrySubIndex;

  int get reportSubIndex => _reportSubIndex;

  String get inventoryNo => _inventoryNo;

  void updateInventory({required String inventoryNo}) {
    _inventoryNo = inventoryNo;
    notifyListeners();
  }

  void updateIndex({
    required int selectedIndex,
    int? masterSubIndex,
    int? entrySubIndex,
    int? reportSubIndex,
  }) {
    _selectedIndex = selectedIndex;
    if (masterSubIndex != null) _masterSubIndex = masterSubIndex;
    if (entrySubIndex != null) _entrySubIndex = entrySubIndex;
    if (reportSubIndex != null) _reportSubIndex = reportSubIndex;

    notifyListeners();
  }

  // Helper methods for easy navigation
  void goToMaster({int subIndex = 0}) {
    updateIndex(selectedIndex: 1, masterSubIndex: subIndex);
  }

  void goToEntry({int subIndex = 0}) {
    updateIndex(selectedIndex: 2, entrySubIndex: subIndex);
  }

  void goToReport({int subIndex = 0}) {
    updateIndex(selectedIndex: 3, reportSubIndex: subIndex);
  }
}
