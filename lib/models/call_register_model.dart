import 'customer_interest_model.dart';

class CallRegisterResponse {
  final List<CallRegisterModel> data;
  final bool hasMore;
  final int total;

  CallRegisterResponse({
    required this.data,
    required this.hasMore,
    required this.total,
  });
}

class CallRegisterModel {
  final int id;
  final String entryNo;
  final String sourceName;
  final String callBy;
  final String date;
  final String followupDate;
  final String fromTime;
  final String toTime;
  final String feedback;
  final String notes;
  final CustomerInterestModel interest;

  CallRegisterModel({
    required this.id,
    required this.entryNo,
    required this.sourceName,
    required this.callBy,
    required this.date,
    required this.fromTime,
    required this.toTime,
    required this.feedback,
    required this.notes,
    required this.followupDate,
    required this.interest,
  });

  factory CallRegisterModel.fromJson(Map<String, dynamic> json) {
    return CallRegisterModel(
      id: int.parse(json['id'].toString()),
      entryNo: json['entry_no'],
      sourceName: json['source_name'],
      callBy: json['call_by'],
      date: json['date'],
      fromTime: json['from'],
      toTime: json['to'],
      feedback: json['feedback'],
      notes: json['notes'],
      followupDate: json['followup_date'] ?? '',
      interest: CustomerInterestModel.fromJson({
        'id': json['interestid']?.toString() ?? '',
        'companyid': json['companyid']?.toString() ?? '',
        'interest': json['interest']?.toString() ?? '',
      }),
    );
  }
}
