class CallRegisterModel {
  final int id;
  final String entryNo;
  final String sourceName;
  final String callBy;
  final String date;
  final String fromTime;
  final String toTime;
  final String feedback;
  final String notes;

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
    );
  }
}
