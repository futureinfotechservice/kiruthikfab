class InwardEntry {
  final String id;
  final String companyId;
  final String inventoryId;
  final String inventoryNumber;
  final String stock;
  final String amount;
  final String addedBy;
  final String manufacturer;
  final String createdAt;
  final String productName;
  final String modelName;
  final String sizeName;
  final String unitName;

  InwardEntry({
    this.id = '',
    required this.companyId,
    required this.inventoryId,
    required this.stock,
    required this.amount,
    required this.addedBy,
    required this.manufacturer,
    this.createdAt = '',
    required this.productName,
    required this.modelName,
    required this.sizeName,
    required this.unitName,
    required this.inventoryNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'companyid': companyId,
      'inventoryid': inventoryId,
      'stock': stock,
      'amount': amount,
      'addedby': addedBy,
      'manufacturer': manufacturer,
    };
  }

  factory InwardEntry.fromJson(Map<String, dynamic> json) {
    return InwardEntry(
      id: json['id']?.toString() ?? '',
      companyId: json['companyid'] ?? '',
      inventoryId: json['inventoryid'] ?? '',
      inventoryNumber: json['inventoryNumber'] ?? '',
      stock: json['stock']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '',
      addedBy: json['addedby'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      createdAt: json['created_at'] ?? '',
      productName: json['productname'] ?? '',
      modelName: json['modelname'] ?? '',
      sizeName: json['sizename'] ?? '',
      unitName: json['unitname'] ?? '',
    );
  }
}
