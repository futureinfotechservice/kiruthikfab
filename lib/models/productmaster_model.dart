class ProductMasterModel {
  String id;
  String companyid;
  String productname;
  String addedby;
  String activestatus;

  ProductMasterModel({
    required this.id,
    required this.companyid,
    required this.productname,
    required this.addedby,
    required this.activestatus,
  });

  factory ProductMasterModel.fromJson(Map<String, dynamic> json) {
    return ProductMasterModel(
      id: json['id']?.toString() ?? '',
      companyid: json['companyid']?.toString() ?? '',
      productname: json['productname']?.toString() ?? '',
      addedby: json['addedby']?.toString() ?? '',
      activestatus: json['activestatus']?.toString() ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyid': companyid,
      'productname': productname,
      'addedby': addedby,
      'activestatus': activestatus,
    };
  }
}