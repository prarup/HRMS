import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApplyForLeavePage extends StatefulWidget {
  final String authToken; // Declare the token variable

  ApplyForLeavePage({required this.authToken}); // Constructor to accept token

  @override
  _ApplyForLeavePageState createState() => _ApplyForLeavePageState();
}

class _ApplyForLeavePageState extends State<ApplyForLeavePage> {
  final _leaveTypeController = TextEditingController();
  final _fromDateController = TextEditingController();
  final _toDateController = TextEditingController();
  final _reasonController = TextEditingController();
  String? _selectedLeaveType; // Variable to store selected leave type
  List<String> _leaveTypes = []; // List to store leave types

  @override
  void initState() {
    super.initState();
    _fetchLeaveTypes(); // Fetch leave types on initialization
  }

  // Method to fetch leave types from the API
  Future<void> _fetchLeaveTypes() async {
    final url = Uri.parse('https://88collection.dndts.net/api/method/fetchleavetype');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': widget.authToken,  // Use the passed token
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _leaveTypes = List<String>.from(data['leave_types'] ?? []);
        });
      } else {
        throw Exception('Failed to fetch leave types');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // Method to apply for leave
  Future<void> _applyForLeave() async {
    final url = Uri.parse('https://88collection.dndts.net/api/method/apply_leave');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': widget.authToken,  // Use the passed token
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'leave_type': _selectedLeaveType,
          'from_date': _fromDateController.text,
          'to_date': _toDateController.text,
          'reason': _reasonController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Leave application successful!')),
        );
      } else {
        throw Exception('Failed to apply for leave');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Apply for Leave'),
        backgroundColor: Color(0xFF3d3d61), // Set the background color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown for selecting leave type
            DropdownButton<String>(
              value: _selectedLeaveType,
              hint: Text('Select Leave Type'),
              isExpanded: true,
              onChanged: (newValue) {
                setState(() {
                  _selectedLeaveType = newValue;
                });
              },
              items: _leaveTypes.map((leaveType) {
                return DropdownMenuItem<String>(
                  value: leaveType,
                  child: Text(leaveType),
                );
              }).toList(),
            ),
            TextField(
              controller: _fromDateController,
              decoration: InputDecoration(labelText: 'From Date (YYYY-MM-DD)'),
              keyboardType: TextInputType.datetime,
            ),
            TextField(
              controller: _toDateController,
              decoration: InputDecoration(labelText: 'To Date (YYYY-MM-DD)'),
              keyboardType: TextInputType.datetime,
            ),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(labelText: 'Reason for Leave'),
              maxLines: 4,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _applyForLeave,
              child: Text('Apply for Leave'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3d3d61), // Correct button color
              ),
            ),
          ],
        ),
      ),
    );
  }
}
