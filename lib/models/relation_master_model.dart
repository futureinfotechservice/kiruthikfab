class RelationMasterModel {
  String id;
  String companyid;
  String relation;
  String addedby;
  String activestatus;

  RelationMasterModel({
    required this.id,
    required this.companyid,
    required this.relation,
    required this.addedby,
    required this.activestatus,
  });

  factory RelationMasterModel.fromJson(Map<String, dynamic> json) {
    return RelationMasterModel(
      id: json['id']?.toString() ?? '',
      companyid: json['companyid']?.toString() ?? '',
      relation: json['relation']?.toString() ?? '',
      addedby: json['addedby']?.toString() ?? '',
      activestatus: json['activestatus']?.toString() ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyid': companyid,
      'Relationname': relation,
      'addedby': addedby,
      'activestatus': activestatus,
    };
  }
}
