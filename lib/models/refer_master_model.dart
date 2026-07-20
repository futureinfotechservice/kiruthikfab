class ReferMasterModel {
  String id;
  String companyid;
  String refername;
  String addedby;
  String activestatus;

  ReferMasterModel({
    required this.id,
    required this.companyid,
    required this.refername,
    required this.addedby,
    required this.activestatus,
  });

  factory ReferMasterModel.fromJson(Map<String, dynamic> json) {
    return ReferMasterModel(
      id: json['id']?.toString() ?? '',
      companyid: json['companyid']?.toString() ?? '',
      refername: json['refername']?.toString() ?? '',
      addedby: json['addedby']?.toString() ?? '',
      activestatus: json['activestatus']?.toString() ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyid': companyid,
      'refername': refername,
      'addedby': addedby,
      'activestatus': activestatus,
    };
  }
}