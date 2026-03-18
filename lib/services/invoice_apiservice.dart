import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

// Models
class Customer {
  final String id;
  final String customerName;
  final String gstNo;
  final String address;
  final String area;
  final String areaId;
  final String mobile1;
  final String mobile2;
  final String whatsapp;
  final String refer;
  final String incharge;
  final String agent;
  final String salesperson;
  final String occupation;
  final String aadharUrl;
  final String photoUrl;
  final String addedby;
  final String activestatus;
  final String createdAt;

  Customer({
    required this.id,
    required this.customerName,
    required this.gstNo,
    required this.address,
    required this.area,
    required this.areaId,
    required this.mobile1,
    required this.mobile2,
    required this.whatsapp,
    required this.refer,
    required this.incharge,
    required this.agent,
    required this.salesperson,
    required this.occupation,
    required this.aadharUrl,
    required this.photoUrl,
    required this.addedby,
    required this.activestatus,
    required this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString() ?? '',
      customerName: json['customername'] ?? '',
      gstNo: json['gst_no'] ?? '',
      address: json['address'] ?? '',
      area: json['area'] ?? '',
      areaId: json['areaid']?.toString() ?? '',
      mobile1: json['mobile1'] ?? '',
      mobile2: json['mobile2'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
      refer: json['refer'] ?? '',
      incharge: json['incharge'] ?? '',
      agent: json['agent'] ?? '',
      salesperson: json['salesperson'] ?? '',
      occupation: json['occupation'] ?? '',
      aadharUrl: json['aadharurl'] ?? '',
      photoUrl: json['photourl'] ?? '',
      addedby: json['addedby'] ?? '',
      activestatus: json['activestatus'] ?? '1',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class Product {
  final String id;
  final String productName;
  final String addedby;
  final String activestatus;
  final String createdAt;

  Product({
    required this.id,
    required this.productName,
    required this.addedby,
    required this.activestatus,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      productName: json['productname'] ?? '',
      addedby: json['addedby'] ?? '',
      activestatus: json['activestatus'] ?? '1',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class Model {
  final String id;
  final String modelName;
  final String addedby;
  final String activestatus;
  final String createdAt;

  Model({
    required this.id,
    required this.modelName,
    required this.addedby,
    required this.activestatus,
    required this.createdAt,
  });

  factory Model.fromJson(Map<String, dynamic> json) {
    return Model(
      id: json['id']?.toString() ?? '',
      modelName: json['modelname'] ?? '',
      addedby: json['addedby'] ?? '',
      activestatus: json['activestatus'] ?? '1',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class Size {
  final String id;
  final String sizeName;
  final String addedby;
  final String activestatus;
  final String createdAt;

  Size({
    required this.id,
    required this.sizeName,
    required this.addedby,
    required this.activestatus,
    required this.createdAt,
  });

  factory Size.fromJson(Map<String, dynamic> json) {
    return Size(
      id: json['id']?.toString() ?? '',
      sizeName: json['sizename'] ?? '',
      addedby: json['addedby'] ?? '',
      activestatus: json['activestatus'] ?? '1',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class Unit {
  final String id;
  final String unitName;
  final String addedby;
  final String activestatus;
  final String createdAt;

  Unit({
    required this.id,
    required this.unitName,
    required this.addedby,
    required this.activestatus,
    required this.createdAt,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id']?.toString() ?? '',
      unitName: json['unitname'] ?? '',
      addedby: json['addedby'] ?? '',
      activestatus: json['activestatus'] ?? '1',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class InvoiceModel {
  final String id;
  final String invoiceNo;
  final String customerId;
  final String customerName;
  final String date;
  final String remarks;
  final String taxPercentage;
  final String subtotal;
  final String grandTotal;
  final String status;
  final String addedby;
  final String createdAt;

  InvoiceModel({
    required this.id,
    required this.invoiceNo,
    required this.customerId,
    required this.customerName,
    required this.date,
    required this.remarks,
    required this.taxPercentage,
    required this.subtotal,
    required this.grandTotal,
    required this.status,
    required this.addedby,
    required this.createdAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id']?.toString() ?? '',
      invoiceNo: json['invoiceno'] ?? json['orderno'] ?? '',
      customerId: json['customerid']?.toString() ?? '',
      customerName: json['customername'] ?? '',
      date: json['date'] ?? '',
      remarks: json['remarks'] ?? '',
      taxPercentage: json['taxpercentage']?.toString() ?? '0',
      subtotal: json['subtotal']?.toString() ?? '0',
      grandTotal: json['grandtotal']?.toString() ?? '0',
      status: json['status'] ?? 'Draft',
      addedby: json['addedby'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class InvoiceApiService {
  // Get next invoice number
  Future<String> getNextInvoiceNumber(BuildContext context, String companyid) async {
    try {
      final url = Uri.parse('$baseUrl/get_next_invoice_no.php');
      final response = await http.post(
        url,
        body: json.encode({'companyid': companyid}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['nextno']?.toString() ?? '1';
      }
      return '1';
    } catch (e) {
      print('Error getting next invoice number: $e');
      return '1';
    }
  }

  // Get customers
  Future<List<Customer>> getCustomers(BuildContext context) async {
    List<Customer> list = [];
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final companyid = prefs.getString('companyid') ?? '';

      final url = Uri.parse('$baseUrl/customer_list.php');
      final response = await http.post(
        url,
        body: json.encode({'companyid': companyid}),
      );

      if (response.statusCode == 200) {
        final items = json.decode(response.body);
        for (var item in items) {
          list.add(Customer.fromJson(item));
        }
      }
    } catch (e) {
      print('Error loading customers: $e');
    }
    return list;
  }

  // Get products
  Future<List<Product>> getProducts(BuildContext context) async {
    List<Product> list = [];
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final companyid = prefs.getString('companyid') ?? '';

      final url = Uri.parse('$baseUrl/product_list.php');
      final response = await http.post(
        url,
        body: json.encode({'companyid': companyid}),
      );

      if (response.statusCode == 200) {
        final items = json.decode(response.body);
        for (var item in items) {
          list.add(Product.fromJson(item));
        }
      }
    } catch (e) {
      print('Error loading products: $e');
    }
    return list;
  }

  // Get models
  Future<List<Model>> getModels(BuildContext context) async {
    List<Model> list = [];
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final companyid = prefs.getString('companyid') ?? '';

      final url = Uri.parse('$baseUrl/model_list.php');
      final response = await http.post(
        url,
        body: json.encode({'companyid': companyid}),
      );

      if (response.statusCode == 200) {
        final items = json.decode(response.body);
        for (var item in items) {
          list.add(Model.fromJson(item));
        }
      }
    } catch (e) {
      print('Error loading models: $e');
    }
    return list;
  }

  // Get sizes
  Future<List<Size>> getSizes(BuildContext context) async {
    List<Size> list = [];
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final companyid = prefs.getString('companyid') ?? '';

      final url = Uri.parse('$baseUrl/size_list.php');
      final response = await http.post(
        url,
        body: json.encode({'companyid': companyid}),
      );

      if (response.statusCode == 200) {
        final items = json.decode(response.body);
        for (var item in items) {
          list.add(Size.fromJson(item));
        }
      }
    } catch (e) {
      print('Error loading sizes: $e');
    }
    return list;
  }

  // Get units
  Future<List<Unit>> getUnits(BuildContext context) async {
    List<Unit> list = [];
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final companyid = prefs.getString('companyid') ?? '';

      final url = Uri.parse('$baseUrl/unit_list.php');
      final response = await http.post(
        url,
        body: json.encode({'companyid': companyid}),
      );

      if (response.statusCode == 200) {
        final items = json.decode(response.body);
        for (var item in items) {
          list.add(Unit.fromJson(item));
        }
      }
    } catch (e) {
      print('Error loading units: $e');
    }
    return list;
  }

  // Save invoice
  Future<String> saveInvoice(
      BuildContext context,
      String invoiceNo,
      String customerId,
      String date,
      List<Map<String, dynamic>> items,
      String remarks,
      String taxPercentage,
      String subtotal,
      String grandTotal,
      ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final companyid = prefs.getString('companyid') ?? '';
      final addedby = prefs.getString('id') ?? '';

      final url = Uri.parse("$baseUrl/save_invoice.php");

      var data = {
        "invoiceno": invoiceNo,
        "companyid": companyid,
        "customerid": customerId,
        "date": date,
        "items": items,
        "remarks": remarks,
        "taxpercentage": taxPercentage,
        "subtotal": subtotal.replaceAll('₹', ''),
        "grandtotal": grandTotal.replaceAll('₹', ''),
        "addedby": addedby,
        "status": "Draft",
      };

      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(data),
      );

      var message = json.decode(response.body);
      print('Save response: $message');

      if (message['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        return "Success";
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message['message'] ?? 'Failed to save invoice'),
            backgroundColor: Colors.red,
          ),
        );
        return "Failed";
      }
    } catch (e) {
      print('Error saving invoice: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return "Failed";
    }
  }

  // Update invoice
  Future<String> updateInvoice(
      BuildContext context,
      String invoiceId,
      String invoiceNo,
      String customerId,
      String date,
      List<Map<String, dynamic>> items,
      String remarks,
      String taxPercentage,
      String subtotal,
      String grandTotal,
      ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final companyid = prefs.getString('companyid') ?? '';

      final url = Uri.parse("$baseUrl/update_invoice.php");

      var data = {
        "invoiceid": invoiceId,
        "invoiceno": invoiceNo,
        "companyid": companyid,
        "customerid": customerId,
        "date": date,
        "items": items,
        "remarks": remarks,
        "taxpercentage": taxPercentage,
        "subtotal": subtotal.replaceAll('₹', ''),
        "grandtotal": grandTotal.replaceAll('₹', ''),
      };

      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(data),
      );

      var message = json.decode(response.body);
      print('Update response: $message');

      if (message['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        return "Success";
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message['message'] ?? 'Failed to update invoice'),
            backgroundColor: Colors.red,
          ),
        );
        return "Failed";
      }
    } catch (e) {
      print('Error updating invoice: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return "Failed";
    }
  }

  // Get invoice list
  Future<List<InvoiceModel>> getInvoiceList(BuildContext context) async {
    List<InvoiceModel> list = [];
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final companyid = prefs.getString('companyid') ?? '';

      final url = Uri.parse('$baseUrl/invoice_list.php');
      final response = await http.post(
        url,
        body: json.encode({'companyid': companyid}),
      );

      if (response.statusCode == 200) {
        final items = json.decode(response.body);
        for (var item in items) {
          list.add(InvoiceModel.fromJson(item));
        }
      }
    } catch (e) {
      print('Error loading invoices: $e');
    }
    return list;
  }

  // Get invoice details
  Future<List<Map<String, dynamic>>> getInvoiceDetails(
      BuildContext context,
      String invoiceId,
      ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final companyid = prefs.getString('companyid') ?? '';

      final response = await http.post(
        Uri.parse('$baseUrl/get_invoice_details.php'),
        body: json.encode({
          'companyid': companyid,
          'invoiceid': invoiceId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      print('Error loading invoice details: $e');
      return [];
    }
  }

  // Delete invoice
  Future<String> deleteInvoice(BuildContext context, String invoiceId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final companyid = prefs.getString('companyid') ?? '';

      final url = Uri.parse('$baseUrl/delete_invoice.php');
      var data = {
        'invoiceid': invoiceId,
        'companyid': companyid,
      };

      var response = await http.post(url, body: json.encode(data));
      var message = json.decode(response.body);

      if (message['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        return "Success";
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message['message'] ?? 'Failed to delete'),
            backgroundColor: Colors.red,
          ),
        );
        return "Failed";
      }
    } catch (e) {
      print('Error deleting invoice: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return "Failed";
    }
  }

  // Update invoice status
  Future<String> updateInvoiceStatus(
      BuildContext context,
      String invoiceId,
      String status,
      ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final companyid = prefs.getString('companyid') ?? '';

      var url = Uri.parse('$baseUrl/update_invoice_status.php');
      var data = {
        'companyid': companyid,
        'invoiceid': invoiceId,
        'status': status,
      };

      var response = await http.post(
        url,
        body: json.encode(data),
        headers: {"Content-Type": "application/json"},
      );

      var message = json.decode(response.body);

      if (response.statusCode == 200 && message['success'] == true) {
        return "Success";
      } else {
        throw Exception(message['message'] ?? 'Failed to update status');
      }
    } catch (e) {
      print('Error updating status: $e');
      throw Exception('Error updating status: $e');
    }
  }
}

// Singleton instance
InvoiceApiService invoiceApiService() => InvoiceApiService();