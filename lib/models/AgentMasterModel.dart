class AgentMasterModel {
  String id;
  String companyid;
  String agentname;
  String addedby;
  String activestatus;

  AgentMasterModel({
    required this.id,
    required this.companyid,
    required this.agentname,
    required this.addedby,
    required this.activestatus,
  });

  factory AgentMasterModel.fromJson(Map<String, dynamic> json) {
    return AgentMasterModel(
      id: json['id']?.toString() ?? '',
      companyid: json['companyid']?.toString() ?? '',
      agentname: json['agentname']?.toString() ?? '',
      addedby: json['addedby']?.toString() ?? '',
      activestatus: json['activestatus']?.toString() ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyid': companyid,
      'agentname': agentname,
      'addedby': addedby,
      'activestatus': activestatus,
    };
  }
}