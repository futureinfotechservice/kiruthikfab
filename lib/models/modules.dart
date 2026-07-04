class LoginData {
  String id;
  String username;
  String password;
  String unique_id;
  String email;
  String user_type;
  String companyid;
  String activestatus;
  String companystatus;
  // String location_track;
  // String attendance;
  // String crm;
  // String salesorder;
  // String collection;
  // String vehiclemaintenance;
  // String roombooking;
  // String purchase;
  // String inventory;
  // String task;
  // String accounts;
  String companyname;
  String logourl;
  // String offer;
  // String general;
  // String settings;
  // String profile;

  LoginData({
    required this.id,
    required this.username,
    required this.password,
    required this.unique_id,
    required this.email,
    required this.user_type,
    required this.companyid,
    required this.companystatus,
    // required this.location_track,
    // required this.attendance,
    // required this.crm,
    // required this.offer,
    // required this.salesorder,
    // required this.collection,
    // required this.vehiclemaintenance,
    // required this.roombooking,
    // required this.purchase,
    // required this.inventory,
    // required this.task,
    // required this.accounts,
    required this.companyname,
    required this.logourl,
    // required this.general,
    // required this.settings,
    // required this.profile,
    required this.activestatus,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      id: json['id'],
      username: json['username'],
      password: json['password'],
      unique_id: json['unique_id'],
      email: json['email'],
      user_type: json['user_type'],
      companyid: json['companyid'],
      activestatus: json['activestatus'],
      companystatus: json['companystatus'],
      // attendance: json['attendance'],
      // crm: json['crm'],
      // salesorder: json['salesorder'],
      // collection: json['collection'],
      // vehiclemaintenance: json['vehiclemaintenance'],
      // roombooking: json['roombooking'],
      // purchase: json['purchase'],
      // inventory: json['inventory'],
      // task: json['task'],
      // accounts: json['accounts'],
      // offer: json['offer'],
      // location_track: json['location_track'],
      companyname: json['companyname'],
      logourl: json['logourl'],
      // general: json['general'],
      // settings: json['settings'],
      // profile: json['profile'],
    );
  }
}
