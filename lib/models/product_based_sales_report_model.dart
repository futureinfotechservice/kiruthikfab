class ProductBasedSalesReportResponse {
  final bool status;
  final String message;
  final List<ProductBasedSalesReportModel> data;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;

  ProductBasedSalesReportResponse({
    required this.status,
    required this.message,
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });

  factory ProductBasedSalesReportResponse.fromJson(Map<String, dynamic> json) {
    return ProductBasedSalesReportResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List? ?? [])
          .map((e) => ProductBasedSalesReportModel.fromJson(e))
          .toList(),
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 100,
      total: json['total'] ?? 0,
      hasMore: json['hasMore'] ?? false,
    );
  }
}

class ProductBasedSalesReportModel {
  final String salesDate;
  final String invoiceNo;
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
    required this.invoiceNo,
  });

  factory ProductBasedSalesReportModel.fromJson(Map<String, dynamic> json) {
    return ProductBasedSalesReportModel(
      salesDate: json['date']?.toString() ?? '',
      sourceName: json['sourceName']?.toString() ?? '',
      products: json['products']?.toString() ?? '',
      salesPerson: json['salespersonname']?.toString() ?? '',
      qty: json['total_items']?.toString() ?? '',
      total: json['total']?.toString() ?? '',
      invoiceNo: json['invoiceno']?.toString() ?? '',
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
      'invoiceno': invoiceNo,
    };
  }
}
