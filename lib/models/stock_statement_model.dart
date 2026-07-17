class StockStatementItem {
  final String id;
  final String inventoryNumber;
  final String productName;
  final String modelName;
  final String sizeName;
  final String unitName;
  final int currentStock;
  final int calculatedStock;
  final int inwardStocks;
  final int outwardStocks;
  final int openingStock;
  final String? manufacturer;
  final DateTime? lastTransactionDate;
  final DateTime? createdAt;

  StockStatementItem({
    required this.id,
    required this.inventoryNumber,
    required this.productName,
    required this.modelName,
    required this.sizeName,
    required this.unitName,
    required this.currentStock,
    required this.openingStock,
    this.manufacturer,
    this.lastTransactionDate,
    this.createdAt,
    required this.calculatedStock,
    required this.inwardStocks,
    required this.outwardStocks,
  });

  factory StockStatementItem.fromJson(Map<String, dynamic> json) {
    return StockStatementItem(
      id: json['id']?.toString() ?? '',
      inventoryNumber: json['inventoryid'] ?? '',
      productName: json['product_name'] ?? '',
      modelName: json['model_name'] ?? '',
      sizeName: json['size_name'] ?? '',
      unitName: json['unit_name'] ?? '',
      currentStock: int.tryParse(json['current_stock']?.toString() ?? '0') ?? 0,
      openingStock: int.tryParse(json['opening_stock']?.toString() ?? '0') ?? 0,
      manufacturer: json['manufacturer']?.toString(),
      lastTransactionDate: _parseDate(json['last_transaction_date']),
      createdAt: _parseDate(json['created_at']),
      calculatedStock:
          int.tryParse(json['calculated_stock']?.toString() ?? '0') ?? 0,
      inwardStocks: int.tryParse(json['inward_stocks']?.toString() ?? '0') ?? 0,
      outwardStocks:
          int.tryParse(json['outward_stocks']?.toString() ?? '0') ?? 0,
    );
  }

  static DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    try {
      return DateTime.parse(dateValue.toString());
    } catch (e) {
      return null;
    }
  }
}
