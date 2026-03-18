class SizeMasterModel {
  String id;
  String companyid;
  String sizename;
  String addedby;
  String activestatus;

  SizeMasterModel({
    required this.id,
    required this.companyid,
    required this.sizename,
    required this.addedby,
    required this.activestatus,
  });

  factory SizeMasterModel.fromJson(Map<String, dynamic> json) {
    return SizeMasterModel(
      id: json['id']?.toString() ?? '',
      companyid: json['companyid']?.toString() ?? '',
      sizename: json['sizename']?.toString() ?? '',
      addedby: json['addedby']?.toString() ?? '',
      activestatus: json['activestatus']?.toString() ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyid': companyid,
      'sizename': sizename,
      'addedby': addedby,
      'activestatus': activestatus,
    };
  }
}