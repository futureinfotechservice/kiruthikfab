class ModelMasterModel {
  String id;
  String companyid;
  String modelname;
  String addedby;
  String activestatus;

  ModelMasterModel({
    required this.id,
    required this.companyid,
    required this.modelname,
    required this.addedby,
    required this.activestatus,
  });

  factory ModelMasterModel.fromJson(Map<String, dynamic> json) {
    return ModelMasterModel(
      id: json['id']?.toString() ?? '',
      companyid: json['companyid']?.toString() ?? '',
      modelname: json['modelname']?.toString() ?? '',
      addedby: json['addedby']?.toString() ?? '',
      activestatus: json['activestatus']?.toString() ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyid': companyid,
      'modelname': modelname,
      'addedby': addedby,
      'activestatus': activestatus,
    };
  }
}