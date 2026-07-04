class AgentMasterModel {
  String id;
  String companyId;
  String agentName;
  String addedBy;
  String activeStatus;

  AgentMasterModel({
    required this.id,
    required this.companyId,
    required this.agentName,
    required this.addedBy,
    required this.activeStatus,
  });

  factory AgentMasterModel.fromJson(Map<String, dynamic> json) {
    return AgentMasterModel(
      id: json['id']?.toString() ?? '',
      companyId: json['companyid']?.toString() ?? '',
      agentName: json['agentname']?.toString() ?? '',
      addedBy: json['addedby']?.toString() ?? '',
      activeStatus: json['activestatus']?.toString() ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyid': companyId,
      'agentname': agentName,
      'addedby': addedBy,
      'activestatus': activeStatus,
    };
  }
}
