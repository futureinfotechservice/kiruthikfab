class DashboardModel {
  final String source;
  final String called;
  final String notCalled;
  final String kyc;
  final String value;

  DashboardModel({
    required this.source,
    required this.called,
    required this.notCalled,
    required this.kyc,
    required this.value,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      source: (json['source'] ?? '0').toString(),
      called: (json['called'] ?? '0').toString(),
      notCalled: (json['notCalled'] ?? '0').toString(),
      kyc: (json['kyc'] ?? '0').toString(),
      value: (json['value'] ?? '0').toString(),
    );
  }
}

class SalesModel {
  final String id;
  final String name;
  final String totalCalls;
  final String approach;
  final String kycFilled;
  final String totalTime;
  final double efficiency;

  SalesModel({
    required this.id,
    required this.name,
    required this.totalCalls,
    required this.approach,
    required this.kycFilled,
    required this.totalTime,
    required this.efficiency,
  });

  factory SalesModel.fromJson(Map<String, dynamic> json) {
    return SalesModel(
      id: json['id'].toString(),
      name: json['name'].toString(),
      totalCalls: json['totalCalls'].toString(),
      approach: json['approach'].toString(),
      kycFilled: json['kycFilled'].toString(),
      totalTime: json['totalTime'].toString(),
      efficiency: double.parse(json['efficiency'].toString()),
    );
  }
}

class CallDashboardModel {
  final String entryNo;
  final String sourceId;
  final String callById;
  final String date;
  final String sourceName;
  final String callByName;
  final String mobile;

  CallDashboardModel({
    required this.entryNo,
    required this.sourceId,
    required this.callById,
    required this.date,
    required this.sourceName,
    required this.callByName,
    required this.mobile,
  });

  factory CallDashboardModel.fromJson(Map<String, dynamic> json) {
    return CallDashboardModel(
      entryNo: json['entry_no'].toString(),
      sourceId: json['source_id'].toString(),
      sourceName: json['source_name'].toString(),
      callById: json['call_by_id'].toString(),
      callByName: json['call_by_name'].toString(),

      date: json['date'].toString(),
      mobile: json['mobile'].toString(),
    );
  }
}

class DeliveryDashboardModel {
  final String headId;
  final String entryNo;
  final String invoiceNo;
  final String status;
  final String date;
  final String customerId;
  final String customerName;
  final String address;

  DeliveryDashboardModel({
    required this.headId,
    required this.entryNo,
    required this.invoiceNo,
    required this.status,
    required this.date,
    required this.customerId,
    required this.customerName,
    required this.address,
  });

  factory DeliveryDashboardModel.fromJson(Map<String, dynamic> json) {
    return DeliveryDashboardModel(
      headId: json['headid'].toString(),
      entryNo: json['entry_no'].toString(),
      invoiceNo: json['invoiceno'].toString(),
      status: json['status'] ?? "Pending",
      date: json['date'].toString(),
      customerId: json['customer_id'].toString(),
      customerName: json['customer_name'].toString(),
      address: json['address'] ?? "-",
    );
  }
}
