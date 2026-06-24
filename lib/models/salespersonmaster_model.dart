class SalesPersonMasterModel {
  String id;
  String companyid;
  String salespersonname;
  String addedby;
  String activestatus;
  final String type;

  SalesPersonMasterModel({
    required this.id,
    required this.companyid,
    required this.salespersonname,
    required this.addedby,
    required this.activestatus,
    required this.type,
  });

  factory SalesPersonMasterModel.fromJson(Map<String, dynamic> json) {
    return SalesPersonMasterModel(
      id: json['id']?.toString() ?? '',
      companyid: json['companyid']?.toString() ?? '',
      salespersonname: json['salespersonname']?.toString() ?? '',
      addedby: json['addedby']?.toString() ?? '',
      activestatus: json['activestatus']?.toString() ?? '1',
      type: json['type']?.toString() ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyid': companyid,
      'salespersonname': salespersonname,
      'addedby': addedby,
      'activestatus': activestatus,
      'type': type,
    };
  }
}
