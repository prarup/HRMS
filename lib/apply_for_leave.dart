import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class FetchLeaveTypesPage extends StatefulWidget {
  FetchLeaveTypesPage({Key? key}) : super(key: key);

  @override
  _FetchLeaveTypesPageState createState() => _FetchLeaveTypesPageState();
}

class _FetchLeaveTypesPageState extends State<FetchLeaveTypesPage> {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  List<Map<String, dynamic>> _leaveData = [];
  List<String> _halfDayTypes = ['First half', 'Second Half']; // Example Half Day Types
  String? _selectedLeaveType;
  bool _isLoading = true;
  String? _authToken;
  DateTime? _fromDate;
  DateTime? _toDate;
  TextEditingController _reasonController = TextEditingController();
  bool _isHalfDay = false;
  String? _selectedHalfDayType;

  @override
  void initState() {
    super.initState();
    _fetchAuthTokenAndLeaveTypes();
  }

  // Fetch the auth token and then fetch leave types
  Future<void> _fetchAuthTokenAndLeaveTypes() async {
    String? token = await _storage.read(key: 'auth_token');
    if (token == null) {
      _showError('User not authenticated. Please login again.');
      return;
    }
    _authToken = token;
    _fetchLeaveTypes();
  }

  // Fetch the leave types using the auth token
  Future<void> _fetchLeaveTypes() async {
    final url = Uri.parse('https://88collection.dndts.net/api/method/fetchleavetype');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': _authToken!},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (data['Data'] is List<dynamic>) {
            _leaveData = (data['Data'] as List<dynamic>).map((item) {
              return {
                'leave_type': item['leave_type'],
                'total_leaves_allocated': (item['total_leaves_allocated'] is double)
                    ? (item['total_leaves_allocated'] as double).toInt()
                    : item['total_leaves_allocated'],
                'remaining_leave': (item['remaining_leave'] is double)
                    ? (item['remaining_leave'] as double).toInt()
                    : item['remaining_leave']
              };
            }).toList();
          }
          _selectedLeaveType = _leaveData.isNotEmpty ? _leaveData[0]['leave_type'] : null;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch leave types');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error: ${e.toString()}');
    }
  }

  // Show error message in a snackbar
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onLeaveTypeChanged(String? newValue) {
    setState(() {
      _selectedLeaveType = newValue;
    });
  }

  double _calculateTotalDays() {
    if (_fromDate != null && _toDate != null) {
      final difference = _toDate!.difference(_fromDate!);
      double totalDays = difference.inDays + 1.0; // Add 1 to include both start and end days as a float
      if (_isHalfDay) {
        totalDays = totalDays / 2.0; // Divide by 2 to get half a day
      }
      return totalDays;
    }
    return 0.0; // Return 0 if no dates are selected
  }

  // Open Modal Bottom Sheet to select a leave type
  void _openLeaveTypeModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: _leaveData.map((item) {
              return ListTile(
                title: Text(item['leave_type']),
                onTap: () {
                  _onLeaveTypeChanged(item['leave_type']);
                  Navigator.pop(context); // Close the modal after selection
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // Show date picker and update fromDate
  Future<void> _selectDate(BuildContext context, DateTime? initialDate, ValueChanged<DateTime?> onDateSelected) async {
    DateTime pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    ) ?? DateTime.now();

    // Validate that fromDate is not earlier than today
    if (pickedDate.isBefore(DateTime.now().subtract(Duration(days: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('From Date cannot be earlier than today')),
      );
      return;
    }

    // Validate that toDate is later than fromDate
    if (initialDate != null && pickedDate.isBefore(initialDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('To Date must be later than From Date')),
      );
      return;
    }

    onDateSelected(pickedDate);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leave Application', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF3d3d61),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView( // Wrap the entire body in a SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Table displaying leave types and allocated leaves
              Table(
                border: TableBorder.all(color: Colors.grey, width: 1),
                columnWidths: {
                  0: FixedColumnWidth(150), // Adjust the width of the 'Leave Type' column
                  1: FixedColumnWidth(100), // Adjust the width of the 'Allocated' column
                  2: FixedColumnWidth(100), // Adjust the width of the 'Remaining' column
                },
                children: [
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'Leave Type',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'Allocated',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'Remaining',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  ..._leaveData.map((item) {
                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(item['leave_type']),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(item['total_leaves_allocated'].toString()),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(item['remaining_leave'].toString()),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              SizedBox(height: 20),  // Space between the table and other form fields

              // Leave Type Selection
              Text(
                'Leave Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              SizedBox(height: 20),
              // Button to open modal
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: InkWell(
                  onTap: _openLeaveTypeModal, // Open modal on tap
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedLeaveType ?? 'Select Leave Type',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // From Date
              Text(
                'From Date',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              GestureDetector(
                onTap: () => _selectDate(context, _fromDate, (selectedDate) {
                  setState(() {
                    _fromDate = selectedDate;
                  });
                }),
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _fromDate != null
                              ? _fromDate!.toLocal().toString().split(' ')[0]
                              : 'Select Date',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        Icon(Icons.calendar_today, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // To Date
              Text(
                'To Date',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              GestureDetector(
                onTap: () => _selectDate(context, _toDate, (selectedDate) {
                  setState(() {
                    _toDate = selectedDate;
                  });
                }),
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _toDate != null
                              ? _toDate!.toLocal().toString().split(' ')[0]
                              : 'Select Date',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        Icon(Icons.calendar_today, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Half Day Checkbox
              Row(
                children: [
                  Checkbox(
                    value: _isHalfDay,
                    onChanged: (bool? value) {
                      setState(() {
                        _isHalfDay = value ?? false;
                      });
                    },
                  ),
                  Text(
                    'Half Day',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              // Half Day Type Dropdown
              if (_isHalfDay) ...[
                Text(
                  'Select Half Day Type',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                DropdownButton<String>(
                  value: _selectedHalfDayType,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedHalfDayType = newValue;
                    });
                  },
                  items: _halfDayTypes.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],

              // Reason Field
              SizedBox(height: 20),
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason for Leave',
                  border: OutlineInputBorder(),
                ),
              ),

              SizedBox(height: 20),

              // Total Days Selected Field
              Text(
                'Total Days Selected: ${_calculateTotalDays()}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),

              SizedBox(height: 20),

              // Submit Button
              ElevatedButton(
                onPressed: () async {
                  double totalLeaveDays = _calculateTotalDays();
                  print(_fromDate);

                  // Convert DateTime objects to ISO 8601 string format, with null check
                  String fromDateString = _fromDate?.toIso8601String() ?? ''; // Provide a fallback if null
                  String toDateString = _toDate?.toIso8601String() ?? ''; // Provide a fallback if null

                  // Prepare the data to be sent in the body
                  Map<String, dynamic> requestBody = {
                    'leave_type': _selectedLeaveType,
                    'from_date': fromDateString, // Use the string version of the date
                    'to_date': toDateString,     // Use the string version of the date
                    'reason': _reasonController.text,
                    'total_leave_days': totalLeaveDays,
                    'half_days': _isHalfDay,
                    'half_day_type': _selectedHalfDayType,
                  };

                  // Send the POST request
                  try {
                    final response = await http.post(
                      Uri.parse('https://88collection.dndts.net/api/method/leavepost'), // Replace with your API endpoint
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': _authToken!
                      },
                      body: json.encode(requestBody), // Encode body as JSON
                    );

                    if (response.statusCode == 200) {
                      // Success: Process the response
                      print('Request succeeded');
                      print('Response Body: ${response.body}');  // Print the response body

                      // Decode the response if it's in JSON format
                      var responseData = json.decode(response.body);
                      print('Response Data: $responseData'); // Print the decoded response data

                      // Show the message from the response
                      String message = responseData['Data'] ?? 'Unexpected response';  // Default message if 'Data' is missing

                      // Show a Snackbar with the message from the response
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                    } else {
                      // Failure: Handle error
                      print('Failed to submit. Status code: ${response.statusCode}');
                      print('Response Body: ${response.body}'); // Print the error response body
                    }
                  } catch (e) {
                    print('Error sending request: $e');
                  }
                },
                child: Text('Submit'),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
