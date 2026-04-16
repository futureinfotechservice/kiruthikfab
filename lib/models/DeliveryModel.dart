class DeliveryRecord {
  final String headId;
  final String invoiceNo;
  final String entryNo;
  final String companyId;
  final String detailId;
  final String checklist;
  final String isChecked;
  final String date;
  final String status;
  final bool isAllChecked;

  DeliveryRecord({
    required this.headId,
    required this.invoiceNo,
    required this.entryNo,
    required this.companyId,
    required this.detailId,
    required this.checklist,
    required this.isChecked,
    required this.date,
    required this.status,
    this.isAllChecked = false,
  });

  factory DeliveryRecord.fromJson(Map<String, dynamic> json) {
    return DeliveryRecord(
      headId: json['headid']?.toString() ?? '',
      invoiceNo: json['invoiceno']?.toString() ?? '',
      entryNo: json['entry_no']?.toString() ?? '',
      companyId: json['companyid']?.toString() ?? '',
      detailId: json['detailid']?.toString() ?? '',
      checklist: json['checklist']?.toString() ?? '',
      isChecked: json['isChecked']?.toString() ?? '0',
      date: json['date']?.toString() ?? '',
      status: json['invoice_status']?.toString() ?? 'Pending',
    );
  }

  static List<DeliveryRecordGroup> groupRecords(List<DeliveryRecord> records) {
    final Map<String, List<DeliveryRecord>> grouped = {};

    for (var record in records) {
      final key = record.headId;
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(record);
    }

    return grouped.entries.map((entry) {
      final records = entry.value;

      final allChecked = records.every((r) => r.isChecked == "1");

      return DeliveryRecordGroup(
        headId: entry.key,
        invoiceNo: records.first.invoiceNo,
        entryNo: records.first.entryNo,
        date: records.first.date,
        status: records.first.status,
        records: records,
        isAllChecked: allChecked,
      );
    }).toList();
  }
}

class DeliveryRecordGroup {
  final String headId;
  final String invoiceNo;
  final String entryNo;
  final String date;
  final String status;
  final List<DeliveryRecord> records;
  final bool isAllChecked;

  DeliveryRecordGroup({
    required this.headId,
    required this.invoiceNo,
    required this.entryNo,
    required this.date,
    required this.status,
    required this.records,
    required this.isAllChecked,
  });
}
