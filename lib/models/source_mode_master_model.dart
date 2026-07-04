class SourceModeMasterModel {
  String id;

  String sourcingmodeName;

  SourceModeMasterModel({required this.id, required this.sourcingmodeName});

  factory SourceModeMasterModel.fromJson(Map<String, dynamic> json) {
    return SourceModeMasterModel(
      id: json['id']?.toString() ?? '',

      sourcingmodeName: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'sourcingmode_name': sourcingmodeName};
  }
}
