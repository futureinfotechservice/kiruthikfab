class DistrictMasterModel {
  String id;
  String companyId;

  String districtName;
  String state;

  DistrictMasterModel({
    required this.id,
    required this.districtName,
    required this.state,
    required this.companyId,
  });

  factory DistrictMasterModel.fromJson(Map<String, dynamic> json) {
    return DistrictMasterModel(
      id: json['id']?.toString() ?? '',
      companyId: json['companyid']?.toString() ?? '',

      districtName: json['district_name']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'district_name': districtName,
      'state': state,
      'companyid': companyId,
    };
  }
}
