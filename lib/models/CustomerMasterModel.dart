class CustomerMasterModel {
  String id;
  String companyid;
  String customername;
  String gstNo;
  String address;
  String area;
  String areaid;
  String mobile1;
  String mobile2;
  String whatsapp;
  String refer;
  String incharge;
  String agent;
  String salesperson;
  String occupation;
  String aadharurl;
  String photourl;
  String activestatus;

  CustomerMasterModel({
    required this.id,
    required this.companyid,
    required this.customername,
    required this.gstNo,
    required this.address,
    required this.area,
    required this.areaid,
    required this.mobile1,
    required this.mobile2,
    required this.whatsapp,
    required this.refer,
    required this.incharge,
    required this.agent,
    required this.salesperson,
    required this.occupation,
    required this.aadharurl,
    required this.photourl,
    required this.activestatus,
  });

  factory CustomerMasterModel.fromJson(Map<String, dynamic> json) {
    return CustomerMasterModel(
      id: json['id']?.toString() ?? '',
      companyid: json['companyid']?.toString() ?? '',
      customername: json['customername']?.toString() ?? '',
      gstNo: json['gst_no']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      areaid: json['areaid']?.toString() ?? '',
      mobile1: json['mobile1']?.toString() ?? '',
      mobile2: json['mobile2']?.toString() ?? '',
      whatsapp: json['whatsapp']?.toString() ?? '',
      refer: json['refer']?.toString() ?? '',
      incharge: json['incharge']?.toString() ?? '',
      agent: json['agent']?.toString() ?? '',
      salesperson: json['salesperson']?.toString() ?? '',
      occupation: json['occupation']?.toString() ?? '',
      aadharurl: json['aadharurl']?.toString() ?? '',
      photourl: json['photourl']?.toString() ?? '',
      activestatus: json['activestatus']?.toString() ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyid': companyid,
      'customername': customername,
      'gst_no': gstNo,
      'address': address,
      'area': area,
      'areaid': areaid,
      'mobile1': mobile1,
      'mobile2': mobile2,
      'whatsapp': whatsapp,
      'refer': refer,
      'incharge': incharge,
      'agent': agent,
      'salesperson': salesperson,
      'occupation': occupation,
      'aadharurl': aadharurl,
      'photourl': photourl,
      'activestatus': activestatus,
    };
  }
}