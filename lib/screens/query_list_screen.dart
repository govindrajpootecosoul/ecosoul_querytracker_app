import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:dio/dio.dart';
import 'package:ecosoulquerytracker/api_config.dart';
import 'package:ecosoulquerytracker/screens/query_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:universal_html/html.dart' as html;
import '../services/queryservice.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


class QueryListScreen extends StatefulWidget {
  @override
  _QueryListScreenState createState() => _QueryListScreenState();
}

class _QueryListScreenState extends State<QueryListScreen> {
  final queryService = QueryService();
  List<dynamic> queryList = [];
  bool isLoading = true;

  String? selectedSearch;
  String? selectedStatus;
  String? selectedCustomer;
  String? selectedAssignedTo;

  TextEditingController searchController = TextEditingController();

  List<String> statusOptions = ['open', 'closed', 'inprogress'];
  List<String> customerNames = [];
  List<Map<String, String>> _users = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
    fetchCustomerNames();
    loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchUsers() async {
    try {
      var response = await Dio().get(ApiConfig.users_list);
      if (response.statusCode == 200) {
        final List<dynamic> userList = response.data['users'];
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

  Future<void> fetchCustomerNames() async {
    try {
      var response = await Dio().get(ApiConfig.users_name_list);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> names = response.data;
        setState(() {
          customerNames = names.map((name) => name.toString()).toList();
        });
      }
    } catch (e) {
      print("Error fetching customer names: $e");
    }
  }

  void loadData() async {
    setState(() => isLoading = true);

    String baseUrl = ApiConfig.all_query_list;
    String id = '72a99416-5859-49c7-8b59-928ccbae038c';
    String userType = 'superadmin';

    Map<String, String> queryParams = {
      'id': id,
      'userType': userType,
    };

    if (selectedSearch?.isNotEmpty == true) queryParams['search'] = selectedSearch!;
    if (selectedStatus?.isNotEmpty == true) queryParams['status'] = selectedStatus!;
    if (selectedCustomer?.isNotEmpty == true) queryParams['name'] = selectedCustomer!;
    if (selectedAssignedTo?.isNotEmpty == true) {
      final user = _users.firstWhere((u) => u['name'] == selectedAssignedTo, orElse: () => {});
      if (user.isNotEmpty) queryParams['assignedTo'] = user['id']!;
    }

    String queryString = Uri(queryParameters: queryParams).query;

    try {
      var response = await Dio().get('$baseUrl?$queryString');
      setState(() {
        queryList = response.statusCode == 200 ? response.data : [];
        isLoading = false;
      });
    } catch (e) {
      print("Error loading data: $e");
      setState(() {
        queryList = [];
        isLoading = false;
      });
    }
  }

// Only changed parts are shown here:



  Future<void> exportToCSV() async {
    final List<List<dynamic>> rows = [
      [
        'Customer Name', 'Contact Number', 'Email ID', 'Company Name',
        'Location', 'Query', 'Status', 'Date & Time Added',
        'Query Resolved Date', 'Query Assigned To', 'Remark',
        'My Response', 'SLA', 'Alert Type',
      ],
      ...queryList.map((q) => [
        q['Customer Name'] ?? '', q['Contact Number'] ?? '', q['Email ID'] ?? '',
        q['Company Name'] ?? '', q['Location'] ?? '', q['Query'] ?? '',
        q['Status'] ?? '', q['Date & Time Added'] ?? '', q['Query Resolved Date'] ?? '',
        q['Query Assigned To'] ?? '', q['Remark'] ?? '', q['My Response'] ?? '',
        q['SLA'] ?? '', q['Alert Type'] ?? '',
      ]),
    ];

    final csvData = const ListToCsvConverter().convert(rows);

    try {
      if (kIsWeb) {
        final blob = html.Blob([csvData]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "query_export_${DateTime.now().millisecondsSinceEpoch}.csv")
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Storage permission denied")));
          return;
        }

        final directory = Directory('/storage/emulated/0/Download/QueryExports');
        if (!(await directory.exists())) {
          await directory.create(recursive: true);
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${directory.path}/query_export_$timestamp.csv');
        await file.writeAsString(csvData);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("CSV exported to ${file.path}")));

        OpenFile.open(file.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to export CSV: $e")));
    }
  }

  Future<void> exportToPDF() async {
    final PdfDocument pdf = PdfDocument();
    final PdfGrid grid = PdfGrid();

    grid.columns.add(count: 14);
    grid.headers.add(1);

    final PdfGridRow header = grid.headers[0];
    List<String> headers = [
      'Customer Name', 'Contact Number', 'Email ID', 'Company Name',
      'Location', 'Query', 'Status', 'Date & Time Added',
      'Query Resolved Date', 'Query Assigned To', 'Remark',
      'My Response', 'SLA', 'Alert Type',
    ];

    for (int i = 0; i < headers.length; i++) {
      header.cells[i].value = headers[i];
    }

    for (var q in queryList) {
      final PdfGridRow row = grid.rows.add();
      row.cells[0].value = q['Customer Name'] ?? '';
      row.cells[1].value = q['Contact Number'] ?? '';
      row.cells[2].value = q['Email ID'] ?? '';
      row.cells[3].value = q['Company Name'] ?? '';
      row.cells[4].value = q['Location'] ?? '';
      row.cells[5].value = q['Query'] ?? '';
      row.cells[6].value = q['Status'] ?? '';
      row.cells[7].value = q['Date & Time Added'] ?? '';
      row.cells[8].value = q['Query Resolved Date'] ?? '';
      row.cells[9].value = q['Query Assigned To'] ?? '';
      row.cells[10].value = q['Remark'] ?? '';
      row.cells[11].value = q['My Response'] ?? '';
      row.cells[12].value = q['SLA'] ?? '';
      row.cells[13].value = q['Alert Type'] ?? '';
    }

    final PdfPage page = pdf.pages.add();
    grid.draw(page: page);

    final List<int> bytes = await pdf.save();
    pdf.dispose();

    try {
      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "query_export_${DateTime.now().millisecondsSinceEpoch}.pdf")
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Storage permission denied")));
          return;
        }

        final directory = Directory('/storage/emulated/0/Download/QueryExports');
        if (!(await directory.exists())) {
          await directory.create(recursive: true);
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${directory.path}/query_export_$timestamp.pdf');
        await file.writeAsBytes(bytes, flush: true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF exported to ${file.path}")));
        OpenFile.open(file.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to export PDF: $e")));
    }
  }



  // void onEdit(Map<String, dynamic> query) async {
  //   final result = await Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => RegistrationForm(existingData: query),
  //     ),
  //   );
  //   if (result == true) loadData();
  // }

  void onEdit(Map<String, dynamic> query) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrationForm(existingData: query),
      ),
    );

    // ✅ अगर update success हुआ हो तो list reload करो
    if (result == true) loadData();
  }


  void onDelete(Map<String, dynamic> query) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Delete"),
        content: Text("Are you sure you want to delete this query?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete")),
        ],
      ),
    );

    if (confirmed == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');
      String? userType = prefs.getString('userType');
      try {
        var headers = {'Content-Type': 'application/json'};
        var data = jsonEncode({

          "id": userId,
          "userType": query['userType'],
          "registrationId": query['registrationId']
        });

        var dio = Dio();
        var response = await dio.request(
          ApiConfig.delete_query,
          options: Options(method: 'DELETE', headers: headers),
          data: data,
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Deleted successfully")));
          loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete failed")));
        }
      } catch (e) {
        print("Error deleting: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("An error occurred")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> assignedTo = _users.map((user) => user['name']!).toList();


    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              width: 300,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/dropdownbg.png'),
                  fit: BoxFit.fill,
                ),
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Input
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Search', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(
                          height: 30,
                          child: TextField(
                            controller: searchController,
                            onSubmitted: (value) {
                              setState(() {
                                selectedSearch = value;
                              });
                              loadData();
                            },
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Search...',
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  _buildDropdown('Status', statusOptions, selectedStatus, (value) {
                    setState(() => selectedStatus = value);
                    loadData();
                  }),
                  SizedBox(height: 10),
                  _buildDropdown('Customer Name', customerNames, selectedCustomer, (value) {
                    setState(() => selectedCustomer = value);
                    loadData();
                  }),
                  SizedBox(height: 10),
                  _buildDropdown('Query Assigned To', assignedTo, selectedAssignedTo, (value) {
                    setState(() => selectedAssignedTo = value);
                    loadData();
                  }),
                  SizedBox(height: 10),
                  ElevatedButton(onPressed: exportToCSV, child: Text("Export CSV")),
                  // SizedBox(height: 10),
                  // ElevatedButton(onPressed: exportToPDF, child: Text("Export PDF")),
                ],
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : queryList.isEmpty
                ? Center(child: Text("No queries found"))
                : LayoutBuilder(
              builder: (context, constraints) {
                double screenWidth = constraints.maxWidth;
                double screenHeight = constraints.maxHeight;

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: screenWidth,
                        minHeight: screenHeight,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/loginbg.png'),
                            fit: BoxFit.fill,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.all(16),
                        child: DataTable(
                          headingRowColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.blue.shade100),
                          columnSpacing: 20,
                          columns: [
                           // DataColumn(label: Text('Query Assigned To')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Contact')),
                            DataColumn(label: Text('Email')),
                           // DataColumn(label: Text('Company')),
                            DataColumn(label: Text('Location')),
                            DataColumn(label: Text('Date Received')),
                            DataColumn(label: Text('Query')),
                            //  DataColumn(label: Text('Calling Date')),

                            // DataColumn(label: Text('Remark')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),

                 /*           DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Contact')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Company')),
                            DataColumn(label: Text('Location')),
                            DataColumn(label: Text('Date Received')),
                          //  DataColumn(label: Text('Calling Date')),
                            DataColumn(label: Text('Query')),
                           // DataColumn(label: Text('Remark')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),*/
                          ],
                          rows: queryList.map((query) {
                            return DataRow(
                              cells: [
                              //  DataCell(Text(query['Query Assigned To'] ?? '')),
                                DataCell(Text(query['Customer Name'] ?? '')),
                                DataCell(Text(query['Contact Number'] ?? '')),
                                DataCell(Text(query['Email ID'] ?? '')),
                               // DataCell(Text(query['Company Name'] ?? '')),
                                //DataCell(Text(query['Location'] ?? '')),
                                DataCell(Text(
                                  (query['Location'] ?? '').toString().length > 25
                                      ? '${query['Location'].toString().substring(0, 25)}...'
                                      : query['Location'] ?? '',
                                )),
                                DataCell(Text(query['Date & Time Added'] ?? '')),
                              //  DataCell(Text(query['callingDate'] ?? '')),
                                DataCell(Text(
                                  (query['Query'] ?? '').toString().length > 25
                                      ? '${query['Query'].toString().substring(0, 25)}...'
                                      : query['Query'] ?? '',
                                )),
                                // DataCell(Text(
                                //   (query['remark'] ?? '').toString().length > 25
                                //       ? '${query['remark'].toString().substring(0, 25)}...'
                                //       : query['remark'] ?? '',
                                // )),
                                DataCell(Text(query['Status'] ?? '')),
                                DataCell(Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => onEdit(query),
                                    ),
                                    // IconButton(
                                    //   icon: Icon(Icons.ac_unit, color: Colors.red),
                                    //   onPressed: (){
                                    //     print("asdfghjk");
                                    //     print(query['id']);
                                    //     print(query['userType']);
                                    //     print(query['registrationId']);
                                    //     print("asdfghjk");
                                    //
                                    //   }
                                    // ),
                                    
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => onDelete(query),
                                    ),
                                  ],
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
      String label,
      List<String> items,
      String? selectedValue,
      Function(String?) onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: (selectedValue != null && items.contains(selectedValue)) ? selectedValue : null,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      hint: Text(
                        'Select $label',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      onChanged: onChanged,
                      items: items.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              if (selectedValue != null && selectedValue.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
