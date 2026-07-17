class StateMasterModel {
  String id;
  String companyId;

  String state;

  StateMasterModel({
    required this.id,

    required this.state,
    required this.companyId,
  });

  factory StateMasterModel.fromJson(Map<String, dynamic> json) {
    return StateMasterModel(
      id: json['id']?.toString() ?? '',
      companyId: json['companyid']?.toString() ?? '',

      state: json['state']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'state': state, 'companyid': companyId};
  }
}
