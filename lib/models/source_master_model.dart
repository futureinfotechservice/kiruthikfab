class SourceMasterModel {
  final String id;
  final String companyid;
  final String sourceNo;
  final String sourceDate;
  final String sourceDateDisplay;
  final String branch;
  final String branchName;
  final String name;
  final String companyName;
  final String mobileNo;
  final String contactNo;
  final String whatsappNo;
  final String area;
  final String areaId;
  final String address;
  final String occupation;
  final String occupationId;
  final String referBy;
  final String referById;
  final String agent;
  final String agentId;
  final String sourcingMode;
  final String sourcingModeId;
  final String entryPerson;
  final String entryPersonId;
  final String backgroundNetwork;
  final String customerInterest;
  final String notes;
  final String salesPerson;
  final String salesPersonId;
  final String addedby;
  final String activestatus;
  final String createdAt;

  SourceMasterModel({
    required this.id,
    required this.companyid,
    required this.sourceNo,
    required this.sourceDate,
    required this.sourceDateDisplay,
    required this.branch,
    required this.name,
    required this.companyName,
    required this.mobileNo,
    required this.contactNo,
    required this.whatsappNo,
    required this.area,
    required this.areaId,
    required this.address,
    required this.occupation,
    required this.occupationId,
    required this.referBy,
    required this.referById,
    required this.agent,
    required this.agentId,
    required this.sourcingMode,
    required this.sourcingModeId,
    required this.entryPerson,
    required this.entryPersonId,
    required this.backgroundNetwork,
    required this.customerInterest,
    required this.notes,
    required this.salesPerson,
    required this.salesPersonId,
    required this.addedby,
    required this.activestatus,
    required this.createdAt,
    required this.branchName,
  });

  factory SourceMasterModel.fromJson(Map<String, dynamic> json) {
    return SourceMasterModel(
      id: json['id']?.toString() ?? '',
      companyid: json['companyid']?.toString() ?? '',
      sourceNo: json['source_no']?.toString() ?? '',
      sourceDate: json['source_date']?.toString() ?? '',
      sourceDateDisplay: json['source_date_display']?.toString() ?? '',
      branch: json['branch']?.toString() ?? '',
      branchName: json['branch_name']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      companyName: json['company_name']?.toString() ?? '',
      mobileNo: json['mobile_no']?.toString() ?? '',
      contactNo: json['contact_no']?.toString() ?? '',
      whatsappNo: json['whatsapp_no']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      areaId: json['area_id']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      occupation: json['occupation']?.toString() ?? '',
      occupationId: json['occupation_id']?.toString() ?? '',
      referBy: json['refer_by']?.toString() ?? '',
      referById: json['refer_by_id']?.toString() ?? '',
      agent: json['agent']?.toString() ?? '',
      agentId: json['agent_id']?.toString() ?? '',
      sourcingMode: json['sourcing_mode']?.toString() ?? '',
      sourcingModeId: json['sourcing_mode_id']?.toString() ?? '',
      entryPerson: json['entry_person']?.toString() ?? '',
      entryPersonId: json['entry_person_id']?.toString() ?? '',
      backgroundNetwork: json['background_network']?.toString() ?? '',
      customerInterest: json['customer_interest']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      salesPerson: json['sales_person']?.toString() ?? '',
      salesPersonId: json['sales_person_id']?.toString() ?? '',
      addedby: json['addedby']?.toString() ?? '',
      activestatus: json['activestatus']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyid': companyid,
      'source_no': sourceNo,
      'source_date': sourceDate,
      'branch': branch,
      'name': name,
      'company_name': companyName,
      'mobile_no': mobileNo,
      'contact_no': contactNo,
      'whatsapp_no': whatsappNo,
      'area': area,
      'area_id': areaId,
      'address': address,
      'occupation': occupation,
      'occupation_id': occupationId,
      'refer_by': referBy,
      'refer_by_id': referById,
      'agent': agent,
      'agent_id': agentId,
      'sourcing_mode': sourcingMode,
      'sourcing_mode_id': sourcingModeId,
      'entry_person': entryPerson,
      'entry_person_id': entryPersonId,
      'background_network': backgroundNetwork,
      'customer_interest': customerInterest,
      'notes': notes,
      'sales_person': salesPerson,
      'sales_person_id': salesPersonId,
      'addedby': addedby,
      'activestatus': activestatus,
      'created_at': createdAt,
    };
  }
}

class SourceResponse {
  final int page;
  final int limit;
  final int total;
  final bool hasMore;
  final List<SourceMasterModel> data;

  SourceResponse({
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
    required this.data,
  });

  factory SourceResponse.fromJson(Map<String, dynamic> json) {
    return SourceResponse(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 50,
      total: json['total'] ?? 0,
      hasMore: json['hasMore'] ?? false,
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => SourceMasterModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// class SourceMasterModel {
//   final String id;
//   final String companyid;
//   final String sourceNo;
//   final String sourceDate;
//   final String sourceDateDisplay;
//   final String branch;
//   final String name;
//   final String companyName;
//   final String mobileNo;
//   final String contactNo;
//   final String whatsappNo;
//   final String area;
//   final String areaId;
//   final String address;
//   final String occupation;
//   final String occupationId;
//   final String referBy;
//   final String referById;
//   final String agent;
//   final String agentId;
//   final String sourcingMode;
//   final String sourcingModeId;
//   final String entryPerson;
//   final String entryPersonId;
//   final String backgroundNetwork;
//   final String customerInterest;
//   final String notes;
//   final String salesPerson;
//   final String salesPersonId;
//   final String addedby;
//   final String activestatus;
//   final String createdAt;
//
//   SourceMasterModel({
//     required this.id,
//     required this.companyid,
//     required this.sourceNo,
//     required this.sourceDate,
//     required this.sourceDateDisplay,
//     required this.branch,
//     required this.name,
//     required this.companyName,
//     required this.mobileNo,
//     required this.contactNo,
//     required this.whatsappNo,
//     required this.area,
//     required this.areaId,
//     required this.address,
//     required this.occupation,
//     required this.occupationId,
//     required this.referBy,
//     required this.referById,
//     required this.agent,
//     required this.agentId,
//     required this.sourcingMode,
//     required this.sourcingModeId,
//     required this.entryPerson,
//     required this.entryPersonId,
//     required this.backgroundNetwork,
//     required this.customerInterest,
//     required this.notes,
//     required this.salesPerson,
//     required this.salesPersonId,
//     required this.addedby,
//     required this.activestatus,
//     required this.createdAt,
//   });
//
//   factory SourceMasterModel.fromJson(Map<String, dynamic> json) {
//     return SourceMasterModel(
//       id: json['id']?.toString() ?? '',
//       companyid: json['companyid']?.toString() ?? '',
//       sourceNo: json['source_no']?.toString() ?? '',
//       sourceDate: json['source_date']?.toString() ?? '',
//       sourceDateDisplay: json['source_date_display']?.toString() ?? '',
//       branch: json['branch']?.toString() ?? '',
//       name: json['name']?.toString() ?? '',
//       companyName: json['company_name']?.toString() ?? '',
//       mobileNo: json['mobile_no']?.toString() ?? '',
//       contactNo: json['contact_no']?.toString() ?? '',
//       whatsappNo: json['whatsapp_no']?.toString() ?? '',
//       area: json['area']?.toString() ?? '',
//       areaId: json['area_id']?.toString() ?? '',
//       address: json['address']?.toString() ?? '',
//       occupation: json['occupation']?.toString() ?? '',
//       occupationId: json['occupation_id']?.toString() ?? '',
//       referBy: json['refer_by']?.toString() ?? '',
//       referById: json['refer_by_id']?.toString() ?? '',
//       agent: json['agent']?.toString() ?? '',
//       agentId: json['agent_id']?.toString() ?? '',
//       sourcingMode: json['sourcing_mode']?.toString() ?? '',
//       sourcingModeId: json['sourcing_mode_id']?.toString() ?? '',
//       entryPerson: json['entry_person']?.toString() ?? '',
//       entryPersonId: json['entry_person_id']?.toString() ?? '',
//       backgroundNetwork: json['background_network']?.toString() ?? '',
//       customerInterest: json['customer_interest']?.toString() ?? '',
//       notes: json['notes']?.toString() ?? '',
//       salesPerson: json['sales_person']?.toString() ?? '',
//       salesPersonId: json['sales_person_id']?.toString() ?? '',
//       addedby: json['addedby']?.toString() ?? '',
//       activestatus: json['activestatus']?.toString() ?? '',
//       createdAt: json['created_at']?.toString() ?? '',
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'companyid': companyid,
//       'source_no': sourceNo,
//       'source_date': sourceDate,
//       'branch': branch,
//       'name': name,
//       'company_name': companyName,
//       'mobile_no': mobileNo,
//       'contact_no': contactNo,
//       'whatsapp_no': whatsappNo,
//       'area': area,
//       'area_id': areaId,
//       'address': address,
//       'occupation': occupation,
//       'occupation_id': occupationId,
//       'refer_by': referBy,
//       'refer_by_id': referById,
//       'agent': agent,
//       'agent_id': agentId,
//       'sourcing_mode': sourcingMode,
//       'sourcing_mode_id': sourcingModeId,
//       'entry_person': entryPerson,
//       'entry_person_id': entryPersonId,
//       'background_network': backgroundNetwork,
//       'customer_interest': customerInterest,
//       'notes': notes,
//       'sales_person': salesPerson,
//       'sales_person_id': salesPersonId,
//       'addedby': addedby,
//       'activestatus': activestatus,
//       'created_at': createdAt,
//     };
//   }
// }
