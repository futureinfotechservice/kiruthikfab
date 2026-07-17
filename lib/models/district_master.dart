class DistrictMasterModel {
  String id;
  String companyId;
  String districtName;
  String state;
  String displayName;

  DistrictMasterModel({
    required this.id,
    required this.companyId,
    required this.districtName,
    required this.state,
    required this.displayName,
  });

  factory DistrictMasterModel.fromJson(Map<String, dynamic> json) {
    return DistrictMasterModel(
      id: json['id']?.toString() ?? '',
      companyId: json['companyid']?.toString() ?? '',
      districtName: json['district_name']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      displayName:
          json['display_name']?.toString() ??
          json['district_name']?.toString() ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyid': companyId,
      'district_name': districtName,
      'state': state,
      'display_name': displayName,
    };
  }
}
