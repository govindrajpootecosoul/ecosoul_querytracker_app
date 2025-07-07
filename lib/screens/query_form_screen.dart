/*
import 'dart:convert';
import 'dart:io'; // ✅ For Platform check

import 'package:ecosoulquerytracker/api_config.dart';
import 'package:ecosoulquerytracker/dio_client.dart';
import 'package:ecosoulquerytracker/screens/query_form_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dio/dio.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/queryservice.dart';

class RegistrationForm extends StatefulWidget {
  final Map<String, dynamic>? existingData;

  RegistrationForm({this.existingData});

  @override
  _RegistrationFormState createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();

  String? platform;
  String? status;
  String countryCode = '+91';

  DateTime dateReceived = DateTime.now();
  DateTime? callingDate;

  final nameController = TextEditingController();
  final contactController = TextEditingController();
  final emailController = TextEditingController();
  final companyController = TextEditingController();
  final locationController = TextEditingController();
  final queryController = TextEditingController();
  final remarkController = TextEditingController();

  List<Map<String, String>> _users = [];
  String? _selectedUserId;

  final dio = Dio();
  final queryService = QueryService();

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      final data = widget.existingData!;
      platform = data['platform'];
      status = data['status'];
      nameController.text = data['name'] ?? '';
      contactController.text = data['contact']?.replaceAll('+91 ', '') ?? '';
      emailController.text = data['email'] ?? '';
      companyController.text = data['company'] ?? '';
      locationController.text = data['location'] ?? '';
      queryController.text = data['query'] ?? '';
      remarkController.text = data['remark'] ?? '';
      _selectedUserId = data['assignedTo'];
      dateReceived = DateTime.tryParse(data['dateReceived'] ?? '') ?? DateTime.now();
      callingDate = data['callingDate'] != null && data['callingDate'] != 'Not Set'
          ? DateTime.tryParse(data['callingDate'])
          : null;
    }
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      var response = await dio.get(ApiConfig.users_list);
      if (response.statusCode == 200) {
        final List<dynamic> userList = response.data['users'];
        if (!mounted) return; // ✅ Prevent setState after dispose
        setState(() {
          _users = userList.map<Map<String, String>>((user) {
            return {
              'id': user['id'].toString(),
              'name': user['name'].toString(),
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Dio Error: $e');
    }
  }

  Future<String?> updateQuery(Map<String, dynamic> data) async {
    try {
      var response = await Dio().put(
        ApiConfig.update_query,
        data: jsonEncode(data),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      print("print update response ${data}");
      if (response.statusCode == 200) {
        return "Query updated successfully";
      } else {
        print("Update error: ${response.statusMessage}");
        return response.statusMessage ?? "Failed to update";
      }
    } catch (e) {
      print("Update error: $e");
      return "Error occurred";
    }
  }

  void _selectDate(BuildContext context, bool isCallingDate) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  child: Text('Done'),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ],
            ),
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: isCallingDate
                    ? callingDate ?? DateTime.now()
                    : dateReceived,
                onDateTimeChanged: (val) {
                  setState(() {
                    if (isCallingDate) {
                      callingDate = val;
                    } else {
                      dateReceived = val;
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    contactController.dispose();
    emailController.dispose();
    companyController.dispose();
    locationController.dispose();
    queryController.dispose();
    remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = SizedBox(height: 12);
    final platformOptions = ['Website', 'Email', 'Phone', 'WhatsApp'];
    final statusOptions = ['Open', 'In Progress', 'close'];

    return Scaffold(
      body: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/loginbg.png'),
              fit: BoxFit.fill,
            ),
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration('Platform'),
                  items: platformOptions
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (val) => setState(() => platform = val),
                  validator: (val) => val == null ? 'Select Platform' : null,
                  value: platformOptions.contains(platform) ? platform : null,
                ),
                spacing,
                TextFormField(
                  controller: nameController,
                  decoration: _inputDecoration('Name'),
                  validator: (val) => val!.isEmpty ? 'Enter Name' : null,
                ),
                spacing,
                IntlPhoneField(
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  initialCountryCode: 'IN',
                  onChanged: (phone) {
                    contactController.text = phone.number;
                    countryCode = phone.countryCode;
                  },
                  onSaved: (phone) {
                    contactController.text = phone!.number;
                    countryCode = phone.countryCode;
                  },
                ),
                spacing,
                TextFormField(
                  controller: emailController,
                  decoration: _inputDecoration('Email ID'),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter Email';
                    final emailRegex =
                    RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    return emailRegex.hasMatch(val) ? null : 'Invalid Email';
                  },
                ),
                spacing,
                TextFormField(
                  controller: companyController,
                  decoration: _inputDecoration('Company Name'),
                ),
                spacing,
                TextFormField(
                  controller: locationController,
                  decoration: _inputDecoration('Location'),
                ),
                spacing,
                TextFormField(
                  controller: queryController,
                  decoration: _inputDecoration('Query'),
                  maxLines: 5,
                ),
                spacing,
                TextFormField(
                  controller: remarkController,
                  decoration: _inputDecoration('Remark'),
                  maxLines: 5,
                ),
                spacing,
                ListTile(
                  title: Text("Date Received: ${dateReceived.toLocal().toString().split(' ')[0]}"),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, false),
                ),
                spacing,
                ListTile(
                  title: Text("Calling Date: ${callingDate != null ? callingDate!.toLocal().toString().split(' ')[0] : 'Not Set'}"),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, true),
                ),
                spacing,
                _users.isEmpty
                    ? Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                  decoration: _inputDecoration('Assigned To'),
                  items: _users.map((user) {
                    return DropdownMenuItem<String>(
                      value: user['id'],
                      child: Text(user['name'] ?? 'No Name'),
                    );
                  }).toList(),
                  onChanged: (val) =>
                      setState(() => _selectedUserId = val),
                  validator: (val) =>
                  val == null ? 'Select User' : null,
                  value: _users.any((user) => user['id'] == _selectedUserId)
                      ? _selectedUserId
                      : null,
                ),
                spacing,
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration('Status'),
                  items: statusOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setState(() => status = val),
                  validator: (val) => val == null ? 'Select Status' : null,
                  value: statusOptions.contains(status) ? status : null,
                ),
                spacing,
                ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        String? registrationId = prefs.getString('userId');
                        String? userType = prefs.getString('userType');

                        Map<String, dynamic> data = {
                          if (widget.existingData == null)
                            "registrationId": registrationId,
                          if (widget.existingData != null)
                            "registrationId": widget.existingData?['registrationId'],
                          "id": widget.existingData?['id'],
                          "userType": userType,
                          "platform": platform,
                          "name": nameController.text,
                          "contact": '$countryCode ${contactController.text}',
                          "email": emailController.text,
                          "company": companyController.text,
                          "location": locationController.text,
                          "dateReceived": dateReceived.toIso8601String(),
                          "callingDate": callingDate?.toIso8601String() ?? 'Not Set',
                          "query": queryController.text,
                          "remark": remarkController.text,
                          "assignedTo": _selectedUserId,
                          "status": status,
                        };

                        String? response;
                        if (widget.existingData == null) {
                          response = await queryService.submitQuery(data);
                        } else {
                          response = await updateQuery(data);
                        }

                        final message = widget.existingData == null
                            ? "Successfully Registered"
                            : "Successfully Updated";

                        if (Platform.isAndroid || Platform.isIOS) {
                          Fluttertoast.showToast(
                            msg: message,
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }

                        // ✅ Clear form only if adding new entry
                        if (widget.existingData == null) {
                          setState(() {
                            platform = null;
                            status = null;
                            dateReceived = DateTime.now();
                            callingDate = null;
                            _selectedUserId = null;
                            countryCode = '+91';
                          });
                          nameController.clear();
                          contactController.clear();
                          emailController.clear();
                          companyController.clear();
                          locationController.clear();
                          queryController.clear();
                          remarkController.clear();
                        }
                      }
                    },

                    child: Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}








*/



// 🟢 registration_form.dart
import 'dart:convert';
import 'dart:io';

import 'package:ecosoulquerytracker/api_config.dart';
import 'package:ecosoulquerytracker/dio_client.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dio/dio.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/queryservice.dart';

class RegistrationForm extends StatefulWidget {
  final Map<String, dynamic>? existingData;

  RegistrationForm({this.existingData});

  @override
  _RegistrationFormState createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();

  String? platform;
  String? status;
  String countryCode = '+91';

  DateTime dateReceived = DateTime.now();
  DateTime? callingDate;

  final nameController = TextEditingController();
  final contactController = TextEditingController();
  final emailController = TextEditingController();
  final companyController = TextEditingController();
  final locationController = TextEditingController();
  final queryController = TextEditingController();
  final remarkController = TextEditingController();

  List<Map<String, String>> _users = [];
  String? _selectedUserId;

  final dio = Dio();
  final queryService = QueryService();

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      final data = widget.existingData!;
      platform = data['platform'];
      status = data['status'];
      nameController.text = data['name'] ?? '';
      contactController.text = data['contact']?.replaceAll('+91 ', '') ?? '';
      emailController.text = data['email'] ?? '';
      companyController.text = data['company'] ?? '';
      locationController.text = data['location'] ?? '';
      queryController.text = data['query'] ?? '';
      remarkController.text = data['remark'] ?? '';
      _selectedUserId = data['assignedTo'];
      dateReceived = DateTime.tryParse(data['dateReceived'] ?? '') ?? DateTime.now();
      callingDate = data['callingDate'] != null && data['callingDate'] != 'Not Set'
          ? DateTime.tryParse(data['callingDate'])
          : null;
    }
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      var response = await dio.get(ApiConfig.users_list);
      if (response.statusCode == 200) {
        final List<dynamic> userList = response.data['users'];
        if (!mounted) return;
        setState(() {
          _users = userList.map<Map<String, String>>((user) {
            return {
              'id': user['id'].toString(),
              'name': user['name'].toString(),
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Dio Error: $e');
    }
  }

  Future<String?> updateQuery(Map<String, dynamic> data) async {
    try {
      var response = await Dio().put(
        ApiConfig.update_query,
        data: jsonEncode(data),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (response.statusCode == 200) {
        return "Query updated successfully";
      } else {
        return response.statusMessage ?? "Failed to update";
      }
    } catch (e) {
      print("Update error: $e");
      return "Error occurred";
    }
  }

  void _selectDate(BuildContext context, bool isCallingDate) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  child: Text('Done'),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ],
            ),
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: isCallingDate
                    ? callingDate ?? DateTime.now()
                    : dateReceived,
                onDateTimeChanged: (val) {
                  setState(() {
                    if (isCallingDate) {
                      callingDate = val;
                    } else {
                      dateReceived = val;
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    contactController.dispose();
    emailController.dispose();
    companyController.dispose();
    locationController.dispose();
    queryController.dispose();
    remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = SizedBox(height: 12);
    final platformOptions = ['Website', 'Email', 'Phone', 'WhatsApp'];
    final statusOptions = ['Open', 'In Progress', 'close'];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingData == null ? 'Add Query' : 'Edit Query'),
      ),
      body: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/loginbg.png'),
              fit: BoxFit.fill,
            ),
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration('Platform'),
                  items: platformOptions
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (val) => setState(() => platform = val),
                  validator: (val) => val == null ? 'Select Platform' : null,
                  value: platformOptions.contains(platform) ? platform : null,
                ),
                spacing,
                TextFormField(
                  controller: nameController,
                  decoration: _inputDecoration('Name'),
                  validator: (val) => val!.isEmpty ? 'Enter Name' : null,
                ),
                spacing,
                IntlPhoneField(
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  initialCountryCode: 'IN',
                  onChanged: (phone) {
                    contactController.text = phone.number;
                    countryCode = phone.countryCode;
                  },
                  onSaved: (phone) {
                    contactController.text = phone!.number;
                    countryCode = phone.countryCode;
                  },
                ),
                spacing,
                TextFormField(
                  controller: emailController,
                  decoration: _inputDecoration('Email ID'),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter Email';
                    final emailRegex =
                    RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    return emailRegex.hasMatch(val) ? null : 'Invalid Email';
                  },
                ),
                spacing,
                TextFormField(
                  controller: companyController,
                  decoration: _inputDecoration('Company Name'),
                ),
                spacing,
                TextFormField(
                  controller: locationController,
                  decoration: _inputDecoration('Location'),
                ),
                spacing,
                TextFormField(
                  controller: queryController,
                  decoration: _inputDecoration('Query'),
                  maxLines: 5,
                ),
                spacing,
                TextFormField(
                  controller: remarkController,
                  decoration: _inputDecoration('Remark'),
                  maxLines: 5,
                ),
                spacing,
                ListTile(
                  title: Text("Date Received: ${dateReceived.toLocal().toString().split(' ')[0]}"),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, false),
                ),
                spacing,
                ListTile(
                  title: Text("Calling Date: ${callingDate != null ? callingDate!.toLocal().toString().split(' ')[0] : 'Not Set'}"),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, true),
                ),
                spacing,
                _users.isEmpty
                    ? Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                  decoration: _inputDecoration('Assigned To'),
                  items: _users.map((user) {
                    return DropdownMenuItem<String>(
                      value: user['id'],
                      child: Text(user['name'] ?? 'No Name'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedUserId = val),
                  validator: (val) => val == null ? 'Select User' : null,
                  value: _users.any((user) => user['id'] == _selectedUserId)
                      ? _selectedUserId
                      : null,
                ),
                spacing,
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration('Status'),
                  items: statusOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setState(() => status = val),
                  validator: (val) => val == null ? 'Select Status' : null,
                  value: statusOptions.contains(status) ? status : null,
                ),
                spacing,
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      String? registrationId = prefs.getString('userId');
                      String? userType = prefs.getString('userType');

                      Map<String, dynamic> data = {
                        if (widget.existingData == null)
                          "registrationId": registrationId,
                        if (widget.existingData != null)
                          "registrationId": widget.existingData?['registrationId'],
                        "id": widget.existingData?['id'],
                        "userType": userType,
                        "platform": platform,
                        "name": nameController.text,
                        "contact": '$countryCode ${contactController.text}',
                        "email": emailController.text,
                        "company": companyController.text,
                        "location": locationController.text,
                        "dateReceived": dateReceived.toIso8601String(),
                        "callingDate": callingDate?.toIso8601String() ?? 'Not Set',
                        "query": queryController.text,
                        "remark": remarkController.text,
                        "assignedTo": _selectedUserId,
                        "status": status,
                      };

                      String? response;
                      if (widget.existingData == null) {
                        response = await queryService.submitQuery(data);
                      } else {
                        response = await updateQuery(data);
                      }

                      final message = widget.existingData == null
                          ? "Successfully Registered"
                          : "Successfully Updated";

                      if (Platform.isAndroid || Platform.isIOS) {
                        Fluttertoast.showToast(
                          msg: message,
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }

                      Navigator.pop(context, true); // ✅ Go back with result
                    }
                  },
                  child: Text(widget.existingData == null ? 'Submit' : 'Update'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
