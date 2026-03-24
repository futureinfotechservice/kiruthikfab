class InchargeMasterModel {
  String id;
  String companyid;
  String inchargetname;
  String addedby;
  String activestatus;

  InchargeMasterModel({
    required this.id,
    required this.companyid,
    required this.inchargetname,
    required this.addedby,
    required this.activestatus,
  });

  factory InchargeMasterModel.fromJson(Map<String, dynamic> json) {
    return InchargeMasterModel(
      id: json['id']?.toString() ?? '',
      companyid: json['companyid']?.toString() ?? '',
      inchargetname: json['inchargetname']?.toString() ?? '',
      addedby: json['addedby']?.toString() ?? '',
      activestatus: json['activestatus']?.toString() ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyid': companyid,
      'inchargetname': inchargetname,
      'addedby': addedby,
      'activestatus': activestatus,
    };
  }
}