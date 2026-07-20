class OccupationMasterModel {
  String id;
  String companyid;
  String occupationname;
  String addedby;
  String activestatus;

  OccupationMasterModel({
    required this.id,
    required this.companyid,
    required this.occupationname,
    required this.addedby,
    required this.activestatus,
  });

  factory OccupationMasterModel.fromJson(Map<String, dynamic> json) {
    return OccupationMasterModel(
      id: json['id']?.toString() ?? '',
      companyid: json['companyid']?.toString() ?? '',
      occupationname: json['occupationname']?.toString() ?? '',
      addedby: json['addedby']?.toString() ?? '',
      activestatus: json['activestatus']?.toString() ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyid': companyid,
      'occupationname': occupationname,
      'addedby': addedby,
      'activestatus': activestatus,
    };
  }
}