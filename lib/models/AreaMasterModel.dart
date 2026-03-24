class AreaMasterModel {
  String id;
  String companyid;
  String areaname;
  String addedby;
  String activestatus;

  AreaMasterModel({
    required this.id,
    required this.companyid,
    required this.areaname,
    required this.addedby,
    required this.activestatus,
  });

  factory AreaMasterModel.fromJson(Map<String, dynamic> json) {
    return AreaMasterModel(
      id: json['id']?.toString() ?? '',
      companyid: json['companyid']?.toString() ?? '',
      areaname: json['areaname']?.toString() ?? '',
      addedby: json['addedby']?.toString() ?? '',
      activestatus: json['activestatus']?.toString() ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyid': companyid,
      'areaname': areaname,
      'addedby': addedby,
      'activestatus': activestatus,
    };
  }
}