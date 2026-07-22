class AgentMasterModel {
  String id;
  String companyId;
  String agentName;
  String percentage;
  String addedBy;
  String activeStatus;

  AgentMasterModel({
    required this.id,
    required this.companyId,
    required this.agentName,
    required this.percentage,
    required this.addedBy,
    required this.activeStatus,
  });

  factory AgentMasterModel.fromJson(Map<String, dynamic> json) {
    return AgentMasterModel(
      id: json['id']?.toString() ?? '',
      companyId: json['companyid']?.toString() ?? '',
      agentName: json['agentname']?.toString() ?? '',
      percentage: json['percentage']?.toString() ?? '',
      addedBy: json['addedby']?.toString() ?? '',
      activeStatus: json['activestatus']?.toString() ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyid': companyId,
      'agentname': agentName,
      'percentage': percentage,
      'addedby': addedBy,
      'activestatus': activeStatus,
    };
  }
}
