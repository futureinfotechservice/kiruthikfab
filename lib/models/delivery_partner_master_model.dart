class DeliveryPartnerMasterModel {
  String id;
  String companyid;
  String name;
  String addedby;
  String activestatus;

  DeliveryPartnerMasterModel({
    required this.id,
    required this.companyid,
    required this.name,
    required this.addedby,
    required this.activestatus,
  });

  factory DeliveryPartnerMasterModel.fromJson(Map<String, dynamic> json) {
    return DeliveryPartnerMasterModel(
      id: json['id']?.toString() ?? '',
      companyid: json['companyid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      addedby: json['addedby']?.toString() ?? '',
      activestatus: json['activestatus']?.toString() ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyid': companyid,
      'name': name,
      'addedby': addedby,
      'activestatus': activestatus,
    };
  }
}
