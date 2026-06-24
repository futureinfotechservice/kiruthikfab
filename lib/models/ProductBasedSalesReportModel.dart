class ProductBasedSalesReportModel {
  final String salesDate;
  final String sourceName;
  final String products;
  final String salesPerson;
  final String qty;
  final String total;
  ProductBasedSalesReportModel({
    required this.salesDate,
    required this.sourceName,
    required this.products,
    required this.salesPerson,
    required this.qty,
    required this.total,
  });
  factory ProductBasedSalesReportModel.fromJson(Map<String, dynamic> json) {
    return ProductBasedSalesReportModel(
      salesDate: json['date']?.toString() ?? '',
      sourceName: json['sourceName']?.toString() ?? '',
      products: json['products']?.toString() ?? '',
      salesPerson: json['salespersonname']?.toString() ?? '',
      qty: json['total_items']?.toString() ?? '',
      total: json['total']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': salesDate,
      'sourceName': sourceName,
      'products': products,
      'salespersonname': salesPerson,
      'total_items': qty,
      'total': total,
    };
  }
}
