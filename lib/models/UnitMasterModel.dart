class UnitMasterModel {
  String id;
  String companyid;
  String unitname;
  String addedby;
  String activestatus;

  UnitMasterModel({
    required this.id,
    required this.companyid,
    required this.unitname,
    required this.addedby,
    required this.activestatus,
  });

  factory UnitMasterModel.fromJson(Map<String, dynamic> json) {
    return UnitMasterModel(
      id: json['id']?.toString() ?? '',
      companyid: json['companyid']?.toString() ?? '',
      unitname: json['unitname']?.toString() ?? '',
      addedby: json['addedby']?.toString() ?? '',
      activestatus: json['activestatus']?.toString() ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyid': companyid,
      'unitname': unitname,
      'addedby': addedby,
      'activestatus': activestatus,
    };
  }
}