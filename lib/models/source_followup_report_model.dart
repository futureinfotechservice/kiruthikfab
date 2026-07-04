import 'customer_interest_model.dart';

class SourceFollowupResponse {
  final List<SourceFollowupReportModel> data;
  final bool hasMore;
  final int total;

  SourceFollowupResponse({
    required this.data,
    required this.hasMore,
    required this.total,
  });
}

class SourceFollowupReportModel {
  final String sourceNo;
  final String sourceName;
  final String mobile;
  final String entryNo;
  final String salesPersonName;
  final String date;
  final String from;
  final String to;
  final String followupDate;
  final CustomerInterestModel interest;
  final String totalTime;
  SourceFollowupReportModel({
    required this.sourceName,
    required this.sourceNo,
    required this.entryNo,
    required this.salesPersonName,
    required this.date,
    required this.from,
    required this.to,
    required this.followupDate,
    required this.interest,
    required this.totalTime,
    required this.mobile,
  });
  factory SourceFollowupReportModel.fromJson(Map<String, dynamic> json) {
    return SourceFollowupReportModel(
      sourceNo: json['source_no']?.toString() ?? '',
      sourceName: json['source_name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      entryNo: json['entry_no']?.toString() ?? '',
      salesPersonName: json['salespersonname']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      followupDate: json['followup_date']?.toString() ?? '',
      interest: CustomerInterestModel.fromJson({
        "id": json['interestid']?.toString() ?? '',
        "companyid": json['companyid']?.toString() ?? '',
        "interest": json['interest']?.toString() ?? '',
      }),
      totalTime: json['totalTime']?.toString() ?? '',
    );
  }
}
