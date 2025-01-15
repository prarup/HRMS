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
                    : item['total_leaves_allocated']
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
                children: [
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Leave Type',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Allocated Leaves',
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
                          _fromDate != null ? _fromDate!.toLocal().toString().split(' ')[0] : 'Select Date',
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
                          _toDate != null ? _toDate!.toLocal().toString().split(' ')[0] : 'Select Date',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        Icon(Icons.calendar_today, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Half Day Switch
              Row(
                children: [
                  Checkbox(
                    value: _isHalfDay,
                    onChanged: (bool? value) {
                      setState(() {
                        _isHalfDay = value!;
                      });
                    },
                  ),
                  Text(
                    'Half Day',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Half Day Type Selection
              if (_isHalfDay)
                DropdownButton<String>(
                  value: _selectedHalfDayType,
                  hint: Text('Select Half Day Type'),
                  items: _halfDayTypes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedHalfDayType = newValue;
                    });
                  },
                ),
              SizedBox(height: 20),

              // Reason Field
              TextField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 20),

              // Submit Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Handle submission
                  },
                  child: Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
