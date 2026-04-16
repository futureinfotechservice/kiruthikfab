class KYCMasterModel {
  final String id;
  final String companyid;
  final String customerId;
  final String customerName;
  final String totalAmount;
  final String addedby;
  final String createdAt;
  final String updatedAt;
  final List<KYCChildModel> children;

  KYCMasterModel({
    required this.id,
    required this.companyid,
    required this.customerId,
    required this.customerName,
    required this.totalAmount,
    required this.addedby,
    required this.createdAt,
    required this.updatedAt,
    required this.children,
  });

  factory KYCMasterModel.fromJson(Map<String, dynamic> json) {
    List<KYCChildModel> children = [];
    if (json['family_members'] != null) {
      children = (json['family_members'] as List)
          .map((child) => KYCChildModel.fromJson(child))
          .toList();
    }

    return KYCMasterModel(
      id: json['id']?.toString() ?? '',
      companyid: json['companyid']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      totalAmount: json['total_amount']?.toString() ?? '0',
      addedby: json['addedby']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      children: children,
    );
  }
}

class KYCChildModel {
  final String id;
  final String kycId;
  final String memberName;
  final String gender;
  final String age;
  final String relation;
  final String occupation;
  final String occupationId;
  final String memberTotal;
  final String sortOrder;
  final List<KYCProductModel> products;

  KYCChildModel({
    required this.id,
    required this.kycId,
    required this.memberName,
    required this.gender,
    required this.age,
    required this.relation,
    required this.occupation,
    required this.occupationId,
    required this.memberTotal,
    required this.sortOrder,
    required this.products,
  });

  factory KYCChildModel.fromJson(Map<String, dynamic> json) {
    List<KYCProductModel> products = [];
    if (json['products'] != null) {
      products = (json['products'] as List)
          .map((product) => KYCProductModel.fromJson(product))
          .toList();
    }

    return KYCChildModel(
      id: json['id']?.toString() ?? '',
      kycId: json['kyc_id']?.toString() ?? '',
      memberName: json['member_name']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      age: json['age']?.toString() ?? '',
      relation: json['relation']?.toString() ?? '',
      occupation: json['occupation']?.toString() ?? '',
      occupationId: json['occupation_id']?.toString() ?? '',
      memberTotal: json['member_total']?.toString() ?? '0',
      sortOrder: json['sort_order']?.toString() ?? '0',
      products: products,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kyc_id': kycId,
      'name': memberName,
      'gender': gender,
      'age': age,
      'relation': relation,
      'occupation': occupation,
      'occupation_id': occupationId,
      'member_total': memberTotal,
      'sort_order': sortOrder,
      'products': products.map((p) => p.toJson()).toList(),
    };
  }
}

class KYCProductModel {
  final String id;
  final String kycId;
  final String familyMemberId;
  final String productId;
  final String productName;
  final String size;
  final String quantity;
  final String price;
  final String totalAmount;
  final String sortOrder;

  KYCProductModel({
    required this.id,
    required this.kycId,
    required this.familyMemberId,
    required this.productId,
    required this.productName,
    required this.size,
    required this.quantity,
    required this.price,
    required this.totalAmount,
    required this.sortOrder,
  });

  factory KYCProductModel.fromJson(Map<String, dynamic> json) {
    return KYCProductModel(
      id: json['id']?.toString() ?? '',
      kycId: json['kyc_id']?.toString() ?? '',
      familyMemberId: json['family_member_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      quantity: json['quantity']?.toString() ?? '0',
      price: json['price']?.toString() ?? '0',
      totalAmount: json['total_amount']?.toString() ?? '0',
      sortOrder: json['sort_order']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'size': size,
      'quantity': quantity,
      'price': price,
      'total': totalAmount,
    };
  }
}