class OrderModel {
  final String invoiceNo;
  final String date;
  final double subtotal;
  final double grandtotal;
  final int packingAmount;
  final String status;
  final String sourceNo;
  final String customerName;
  final String mobileNo;
  final String area;
  final double commissionEarned; // Added this field

  OrderModel({
    required this.invoiceNo,
    required this.date,
    required this.subtotal,
    required this.grandtotal,
    required this.packingAmount,
    required this.status,
    required this.sourceNo,
    required this.customerName,
    required this.mobileNo,
    required this.area,
    this.commissionEarned = 0.0, // Default value
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      invoiceNo: json['invoice_no'] ?? '',
      date: json['date'] ?? '',
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      grandtotal: (json['grandtotal'] ?? 0).toDouble(),
      packingAmount: json['packing_amount'] ?? 0,
      status: json['status'] ?? 'Pending',
      sourceNo: json['source_no'] ?? '',
      customerName: json['customer_name'] ?? '',
      mobileNo: json['mobile_no'] ?? '',
      area: json['area'] ?? '',
      commissionEarned: (json['commission_earned'] ?? 0).toDouble(),
    );
  }
}

class AgentReportData {
  final int agentId;
  final String agentName;
  final double commissionPercentage;
  final int totalSources;
  final int totalInvoices;
  final double totalOrderAmount;
  final double totalSubtotal;
  final double totalCommissionEarned;
  final double totalPackingCharges;
  final double averageOrderValue;
  final double averageSubtotal;
  final String performanceLevel;
  final String? firstOrderDate;
  final String? lastOrderDate;

  // final String? sourceNumbers;
  // final String? customerNames;

  AgentReportData({
    required this.agentId,
    required this.agentName,
    required this.commissionPercentage,
    required this.totalSources,
    required this.totalInvoices,
    required this.totalOrderAmount,
    required this.totalSubtotal,
    required this.totalCommissionEarned,
    required this.totalPackingCharges,
    required this.averageOrderValue,
    required this.averageSubtotal,
    required this.performanceLevel,
    this.firstOrderDate,
    this.lastOrderDate,
    // this.sourceNumbers,
    // this.customerNames,
  });

  factory AgentReportData.fromJson(Map<String, dynamic> json) {
    return AgentReportData(
      agentId: json['agent_id'] ?? 0,
      agentName: json['agent_name'] ?? '',
      commissionPercentage: (json['commission_percentage'] ?? 0).toDouble(),
      totalSources: json['total_sources'] ?? 0,
      totalInvoices: json['total_invoices'] ?? 0,
      totalOrderAmount: (json['total_order_amount'] ?? 0).toDouble(),
      totalSubtotal: (json['total_subtotal'] ?? 0).toDouble(),
      totalCommissionEarned: (json['total_commission_earned'] ?? 0).toDouble(),
      totalPackingCharges: (json['total_packing_charges'] ?? 0).toDouble(),
      averageOrderValue: (json['average_order_value'] ?? 0).toDouble(),
      averageSubtotal: (json['average_subtotal'] ?? 0).toDouble(),
      performanceLevel: json['performance_level'] ?? 'Low',
      firstOrderDate: json['first_order_date'],
      lastOrderDate: json['last_order_date'],
      // sourceNumbers: json['source_numbers'],
      // customerNames: json['customer_names'],
    );
  }
}

class AgentReferReportModel {
  final double totalOrderAmount;
  final double totalSubtotal; // Added this field
  final double totalCommission;
  final int totalInvoices;
  final int totalSources;
  final AgentReportData? topPerformer;
  final double averageOrderValue;
  final double averageSubtotal; // Added this field

  AgentReferReportModel({
    required this.totalOrderAmount,
    required this.totalSubtotal,
    required this.totalCommission,
    required this.totalInvoices,
    required this.totalSources,
    this.topPerformer,
    required this.averageOrderValue,
    required this.averageSubtotal,
  });

  factory AgentReferReportModel.fromJson(Map<String, dynamic> json) {
    return AgentReferReportModel(
      totalOrderAmount: (json['total_order_amount'] ?? 0).toDouble(),
      totalSubtotal: (json['total_subtotal'] ?? 0).toDouble(),
      totalCommission: (json['total_commission'] ?? 0).toDouble(),
      totalInvoices: json['total_invoices'] ?? 0,
      totalSources: json['total_sources'] ?? 0,
      topPerformer: json['top_performer'] != null
          ? AgentReportData.fromJson(json['top_performer'])
          : null,
      averageOrderValue: (json['average_order_value'] ?? 0).toDouble(),
      averageSubtotal: (json['average_subtotal'] ?? 0).toDouble(),
    );
  }
}
