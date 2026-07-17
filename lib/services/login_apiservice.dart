// lib/services/api_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kiruthikfab/models/modules.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home/home.dart';
import 'auth_service.dart';
import 'config.dart';

class ApiService {
  List<LoginData> loginlist = [];

  Future<void> login(
    BuildContext context,
    String username,
    String password,
    String mailid,
    String uniqueId,
    String platform,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/login2.php');

      // Validate inputs
      if (username.isEmpty || password.isEmpty || mailid.isEmpty) {
        _showError(context, 'Username, password, and email are required');
        return;
      }

      final requestBody = {
        'username': username.trim(),
        'password': password.trim(),
        'email': mailid.trim(),
        'platform': platform.toString().trim(),
        'unique_id': uniqueId.toString().trim(),
      };

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
              // 'Cache-Control': 'no-cache',
            },
            body: json.encode(requestBody),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Connection timeout');
            },
          );

      try {
        final data = json.decode(response.body);

        if (response.statusCode == 200 &&
            data['status'] == 'success' &&
            context.mounted) {
          // Success handling
          ApiService().userdata(
            context,
            username.trim(),
            password.trim(),
            mailid.trim(),
            uniqueId.trim(),
            platform.trim(),
          );
        } else {
          // Error handling - prefer server message or fallback
          final errorMsg = data['message'] ?? 'Login failed. Please try again.';
          if (context.mounted) _showError(context, errorMsg);
        }
      } catch (e) {
        ///print(e);
        if (context.mounted) {
          _showError(context, 'Invalid server response format');
        }
      }
    } catch (e) {
      //print(e);
      if (context.mounted) {
        _showError(context, 'Network error: ${e.toString()}');
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Future login(
  //   BuildContext context,
  //   String username,
  //   String password,
  //   String mailid,
  //   String unique_id,
  //   String platform,
  // ) async {
  //   final url = Uri.parse('$baseUrl/login1.php');
  //
  //   final response = await http.post(
  //     url,
  //     body: json.encode({
  //       'username': username,
  //       'password': password,
  //       'email': mailid,
  //       'platform': platform.toString(),
  //       'unique_id': unique_id.toString(),
  //     }),
  //     headers: {
  //       'Content-Type': 'application/json; charset=utf-8',
  //       'Accept': 'application/json',
  //     },
  //   );
  //
  //   var message = response.body.toString();
  //
  //   if (message.toString().contains('login success')) {
  //     ApiService().userdata(
  //       context,
  //       username,
  //       password,
  //       mailid,
  //       unique_id,
  //       platform,
  //     );
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(message.toString()),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  Future userdata(
    BuildContext context,
    String username,
    String password,
    String mailid,
    String uniqueId,
    String platform,
  ) async {
    loginlist.clear();
    // var url = Uri.parse('$baseUrl/user_json5.php');
    var url = Uri.parse('$baseUrl/user_json7.php');
    var data = {
      'username': username.toString(),
      'password': password.toString(),
      'email': mailid.toString(),
      // 'unique_id': unique_id.toString(),
      'platform': platform.toString(),
    }; //to load an rowid  {item is the name used in php file}
    // var response = await http.get(url);
    var response = await http.post(url, body: json.encode(data));
    final items = json.decode(response.body);

    items.forEach((api) {
      final ab = LoginData(
        id: api['id'],
        username: api['username'],
        password: api['password'],
        // unique_id: api['unique_id'],
        userType: api['user_type'],
        email: api['email_id'],
        companyId: api['companyid'],
        activeStatus: api['activestatus'],
        // location_track: api['location_track']??'',
        companyStatus: api['companystatus'],
        uniqueId: api['unique_id'] ?? '',
        // attendance: api['attendance'],
        // crm: api['crm'],
        // salesorder: api['salesorder'],
        // collection: api['collection'],
        // vehiclemaintenance: api['vehiclemaintenance'],
        // roombooking: api['roombooking'],
        // purchase: api['purchase'],
        // inventory: api['inventory'],
        // task: api['task'],
        // accounts: api['accounts'],
        companyname: api['companyname'],
        // offer: api['offer'],
        logourl: api['logourl'],

        // general: api['general'],
        // settings: api['settings'],
        // profile: api['profile'],
      );
      loginlist.add(ab);
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('id', loginlist[0].id.toString());
    prefs.setString('username', loginlist[0].username.toString());
    prefs.setString('password', loginlist[0].password.toString());
    prefs.setString('email', loginlist[0].email.toString());
    prefs.setString('user_type', loginlist[0].userType.toString());
    prefs.setString('companyid', loginlist[0].companyId.toString());
    prefs.setString('activestatus', loginlist[0].activeStatus.toString());
    prefs.setString('companyname', loginlist[0].companyname.toString());
    prefs.setString('logourl', loginlist[0].logourl.toString());

    // Save credentials for auto-login
    await AuthService.saveLoginCredentials(
      username: username,
      password: password,
      email: mailid,
      userId: loginlist[0].id.toString(),
    );
    // GoRouter.of(context).pushNamed("dashboard");

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CustomerManagementApp()),
      );
    }
  }
}
