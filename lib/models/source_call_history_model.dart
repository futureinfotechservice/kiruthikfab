class SourceCallHistoryModel {
  final String sourceNo;
  final String sourceName;
  final String mobile;
  final String salesPersonName;
  final String entryNo;
  final String date;
  final String from;
  final String to;
  final String followupDate;
  final String interestId;
  final String feedback;
  final String notes;
  final String callById;
  final String interest;
  final String companyId;
  final String sourceDate;
  final String callBy;
  final String totalTime;

  SourceCallHistoryModel({
    required this.sourceNo,
    required this.sourceName,
    required this.mobile,
    required this.salesPersonName,
    required this.entryNo,
    required this.date,
    required this.from,
    required this.to,
    required this.followupDate,
    required this.interestId,
    required this.feedback,
    required this.notes,
    required this.callById,
    required this.interest,
    required this.companyId,
    required this.sourceDate,
    required this.callBy,
    required this.totalTime,
  });

  factory SourceCallHistoryModel.fromJson(Map<String, dynamic> json) {
    return SourceCallHistoryModel(
      sourceNo: json['source_no']?.toString() ?? ' ',
      sourceName: json['source_name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      salesPersonName: json['salespersonname']?.toString() ?? '',
      entryNo: json['entry_no']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      followupDate: json['followup_date']?.toString() ?? '',
      interestId: json['interestid']?.toString() ?? '',
      feedback: json['feedback']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      callById: json['call_by_id']?.toString() ?? '',
      interest: json['interest']?.toString() ?? '',
      companyId: json['companyid']?.toString() ?? '',
      sourceDate: json['source_date']?.toString() ?? '',
      callBy: json['call_by']?.toString() ?? '',
      totalTime: json['totalTime']?.toString() ?? '',
    );
  }

  // Map<String, dynamic> toJson() {
  //   return {'source_no': sourceNo};
  // }
}
