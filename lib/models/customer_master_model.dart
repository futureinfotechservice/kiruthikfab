class CustomerMasterModel {
  String id;
  String companyid;
  String customername;
  String gstNo;
  String address;
  String area;
  String areaId;  // New field
  String areaid;
  String mobile1;
  String mobile2;
  String whatsapp;
  String refer;
  String referId;  // New field
  String incharge;
  String inchargeId;  // New field
  String agent;
  String agentId;  // New field
  String salesperson;
  String salespersonId;  // New field
  String occupation;
  String occupationId;  // New field
  String aadharurl;
  String photourl;
  String addedby;
  String activestatus;
  String createdAt;

  CustomerMasterModel({
    required this.id,
    required this.companyid,
    required this.customername,
    required this.gstNo,
    required this.address,
    required this.area,
    required this.areaId,
    required this.areaid,
    required this.mobile1,
    required this.mobile2,
    required this.whatsapp,
    required this.refer,
    required this.referId,
    required this.incharge,
    required this.inchargeId,
    required this.agent,
    required this.agentId,
    required this.salesperson,
    required this.salespersonId,
    required this.occupation,
    required this.occupationId,
    required this.aadharurl,
    required this.photourl,
    required this.addedby,
    required this.activestatus,
    required this.createdAt,
  });

  factory CustomerMasterModel.fromJson(Map<String, dynamic> json) {
    return CustomerMasterModel(
      id: json['id']?.toString() ?? '',
      companyid: json['companyid']?.toString() ?? '',
      customername: json['customername'] ?? '',
      gstNo: json['gst_no'] ?? '',
      address: json['address'] ?? '',
      area: json['area'] ?? '',
      areaId: json['area_id']?.toString() ?? '',
      areaid: json['areaid']?.toString() ?? '',
      mobile1: json['mobile1'] ?? '',
      mobile2: json['mobile2'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
      refer: json['refer'] ?? '',
      referId: json['refer_id']?.toString() ?? '',
      incharge: json['incharge'] ?? '',
      inchargeId: json['incharge_id']?.toString() ?? '',
      agent: json['agent'] ?? '',
      agentId: json['agent_id']?.toString() ?? '',
      salesperson: json['salesperson'] ?? '',
      salespersonId: json['salesperson_id']?.toString() ?? '',
      occupation: json['occupation'] ?? '',
      occupationId: json['occupation_id']?.toString() ?? '',
      aadharurl: json['aadharurl'] ?? '',
      photourl: json['photourl'] ?? '',
      addedby: json['addedby']?.toString() ?? '',
      activestatus: json['activestatus']?.toString() ?? '',
      createdAt: json['created_at'] ?? '',
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
      'area_id': areaId,
      'areaid': areaid,
      'mobile1': mobile1,
      'mobile2': mobile2,
      'whatsapp': whatsapp,
      'refer': refer,
      'refer_id': referId,
      'incharge': incharge,
      'incharge_id': inchargeId,
      'agent': agent,
      'agent_id': agentId,
      'salesperson': salesperson,
      'salesperson_id': salespersonId,
      'occupation': occupation,
      'occupation_id': occupationId,
      'aadharurl': aadharurl,
      'photourl': photourl,
      'addedby': addedby,
      'activestatus': activestatus,
      'created_at': createdAt,
    };
  }
}