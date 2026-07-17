class StockLedgerData {
  final InventoryInfo? inventoryInfo;
  final List<StockLedgerTransaction> transactions;
  final PaginationInfo? pagination;
  final SummaryInfo? summary;

  StockLedgerData({
    this.inventoryInfo,
    required this.transactions,
    this.pagination,
    this.summary,
  });
}

class InventoryInfo {
  final String id;
  final String inventoryNumber;
  final String productName;
  final String modelName;
  final String sizeName;
  final String unitName;
  final int openingStock;
  final int currentStock;
  final int totalInward;
  final int totalOutward;
  final int calculatedStock;

  InventoryInfo({
    required this.id,
    required this.inventoryNumber,
    required this.productName,
    required this.modelName,
    required this.sizeName,
    required this.unitName,
    required this.openingStock,
    required this.currentStock,
    required this.totalInward,
    required this.totalOutward,
    required this.calculatedStock,
  });

  factory InventoryInfo.fromJson(Map<String, dynamic> json) {
    return InventoryInfo(
      id: json['id']?.toString() ?? '',
      inventoryNumber: json['inventory_number'] ?? '',
      productName: json['product_name'] ?? '',
      modelName: json['model_name'] ?? '',
      sizeName: json['size_name'] ?? '',
      unitName: json['unit_name'] ?? '',
      openingStock: int.tryParse(json['opening_stock']?.toString() ?? '0') ?? 0,
      currentStock: int.tryParse(json['current_stock']?.toString() ?? '0') ?? 0,
      totalInward: int.tryParse(json['total_inward']?.toString() ?? '0') ?? 0,
      totalOutward: int.tryParse(json['total_outward']?.toString() ?? '0') ?? 0,
      calculatedStock:
          int.tryParse(json['calculated_stock']?.toString() ?? '0') ?? 0,
    );
  }
}

class StockLedgerTransaction {
  final String id;
  final String transactionType;
  final String entryType;
  final int quantity;
  final double amount;
  final double rate;
  final DateTime date;
  final String formattedDate;
  final String? manufacturer;
  final String? addedBy;
  final int stockIn;
  final int stockOut;
  final int openingStock;
  final int closingStock;
  final int calculatedBalance;
  final String? referenceNumber;
  final String? invoiceDetailsId;
  final String inventoryNumber;
  final String productName;
  final String modelName;
  final String sizeName;
  final String unitName;

  StockLedgerTransaction({
    required this.id,
    required this.transactionType,
    required this.entryType,
    required this.quantity,
    required this.amount,
    required this.rate,
    required this.date,
    required this.formattedDate,
    this.manufacturer,
    this.addedBy,
    required this.stockIn,
    required this.stockOut,
    required this.openingStock,
    required this.closingStock,
    required this.calculatedBalance,
    this.referenceNumber,
    this.invoiceDetailsId,
    required this.inventoryNumber,
    required this.productName,
    required this.modelName,
    required this.sizeName,
    required this.unitName,
  });

  factory StockLedgerTransaction.fromJson(Map<String, dynamic> json) {
    return StockLedgerTransaction(
      id: json['id']?.toString() ?? '',
      transactionType: json['transaction_type'] ?? '',
      entryType: json['entry_type'] ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      rate: double.tryParse(json['rate']?.toString() ?? '0') ?? 0,
      date: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      formattedDate: json['formatted_date'] ?? '',
      manufacturer: json['manufacturer'],
      addedBy: json['addedby'],
      stockIn: int.tryParse(json['stock_in']?.toString() ?? '0') ?? 0,
      stockOut: int.tryParse(json['stock_out']?.toString() ?? '0') ?? 0,
      openingStock: int.tryParse(json['opening_stock']?.toString() ?? '0') ?? 0,
      closingStock: int.tryParse(json['closing_stock']?.toString() ?? '0') ?? 0,
      calculatedBalance:
          int.tryParse(json['calculated_balance']?.toString() ?? '0') ?? 0,
      referenceNumber: json['reference_number'],
      invoiceDetailsId: json['invoice_details_id']?.toString(),
      inventoryNumber: json['inventory_number'] ?? '',
      productName: json['product_name'] ?? '',
      modelName: json['model_name'] ?? '',
      sizeName: json['size_name'] ?? '',
      unitName: json['unit_name'] ?? '',
    );
  }
}

class PaginationInfo {
  final int total;
  final int offset;
  final int limit;
  final bool hasMore;

  PaginationInfo({
    required this.total,
    required this.offset,
    required this.limit,
    required this.hasMore,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      total: json['total'] ?? 0,
      offset: json['offset'] ?? 0,
      limit: json['limit'] ?? 20,
      hasMore: json['has_more'] ?? false,
    );
  }
}

class SummaryInfo {
  final int totalInwardQuantity;
  final int totalOutwardQuantity;
  final double totalInwardAmount;
  final double totalOutwardAmount;

  SummaryInfo({
    required this.totalInwardQuantity,
    required this.totalOutwardQuantity,
    required this.totalInwardAmount,
    required this.totalOutwardAmount,
  });

  factory SummaryInfo.fromJson(Map<String, dynamic> json) {
    return SummaryInfo(
      totalInwardQuantity: json['total_inward_quantity'] ?? 0,
      totalOutwardQuantity: json['total_outward_quantity'] ?? 0,
      totalInwardAmount:
          double.tryParse(json['total_inward_amount']?.toString() ?? '0') ?? 0,
      totalOutwardAmount:
          double.tryParse(json['total_outward_amount']?.toString() ?? '0') ?? 0,
    );
  }
}

class InventoryListItem {
  final String id;
  final String inventoryNumber;
  final String productName;
  final String modelName;
  final String sizeName;
  final String unitName;
  final int openingStock;
  final int currentStock;
  final int calculatedStock;
  final int totalInward;
  final int totalOutward;
  final String stockStatus;
  final String? manufacturer;
  final DateTime? lastTransactionDate;
  final DateTime? createdAt;

  InventoryListItem({
    required this.id,
    required this.inventoryNumber,
    required this.productName,
    required this.modelName,
    required this.sizeName,
    required this.unitName,
    required this.openingStock,
    required this.currentStock,
    required this.calculatedStock,
    required this.totalInward,
    required this.totalOutward,
    required this.stockStatus,
    this.manufacturer,
    this.lastTransactionDate,
    this.createdAt,
  });

  factory InventoryListItem.fromJson(Map<String, dynamic> json) {
    return InventoryListItem(
      id: json['id']?.toString() ?? '',
      inventoryNumber: json['inventoryid'] ?? '',
      productName: json['product_name'] ?? '',
      modelName: json['model_name'] ?? '',
      sizeName: json['size_name'] ?? '',
      unitName: json['unit_name'] ?? '',
      openingStock: int.tryParse(json['opening_stock']?.toString() ?? '0') ?? 0,
      currentStock: int.tryParse(json['current_stock']?.toString() ?? '0') ?? 0,
      calculatedStock:
          int.tryParse(json['calculated_stock']?.toString() ?? '0') ?? 0,
      totalInward: int.tryParse(json['total_inward']?.toString() ?? '0') ?? 0,
      totalOutward: int.tryParse(json['total_outward']?.toString() ?? '0') ?? 0,
      stockStatus: json['stock_status'] ?? 'instock',
      manufacturer: json['manufacturer'],
      lastTransactionDate: json['last_transaction_date'] != null
          ? DateTime.parse(json['last_transaction_date'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }
}
