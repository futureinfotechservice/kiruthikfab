class CustomerInterestModel {
  String id;
  String companyid;
  String interest;

  CustomerInterestModel({
    required this.id,
    required this.companyid,
    required this.interest,
  });

  factory CustomerInterestModel.fromJson(Map<String, dynamic> json) {
    return CustomerInterestModel(
      id: json['id']?.toString() ?? '',
      companyid: json['companyid']?.toString() ?? '',
      interest: json['interest']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'companyid': companyid, 'interest': interest};
  }
}
