import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login.dart'; // Import LoginPage for navigation
import 'package:http/http.dart' as http;
import 'dart:convert'; // Required for json.decode
import 'attendance_page.dart'; // Import AttendancePage
import 'leave_page.dart';
import 'package:geolocator/geolocator.dart';
import 'apply_for_leave.dart';

class EmployeeDetailPage extends StatefulWidget {
  const EmployeeDetailPage({super.key});

  @override
  _EmployeeDetailPageState createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends State<EmployeeDetailPage> {
  Map<String, dynamic>? _employeeData;
  final _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchEmployeeDetail();
  }

  // Method to get current location (GPS coordinates)
  Future<Position> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied) {
      // Handle denied permission case
      throw Exception('Location permission denied');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // Method to get address from coordinates using reverse geocoding
  Future<String> _getAddressFromCoordinates(double latitude, double longitude) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json&addressdetails=1');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data != null && data['address'] != null) {
          String address = '${data['display_name'] ?? ''}, ';
          return address.isNotEmpty ? address : 'Address not found';
        } else {
          return 'Address not found';
        }
      } else {
        throw Exception('Failed to fetch address');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  // Method to mark check-in with geolocation
  void _markCheckin() async {
    try {
      Position position = await _getCurrentLocation();
      String address = await _getAddressFromCoordinates(position.latitude, position.longitude);

      String geolocation = json.encode({
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "properties": {"name": address},
            "geometry": {
              "type": "Point",
              "coordinates": [position.longitude, position.latitude]
            }
          }
        ]
      });

      String loc = json.encode({
        "type": "Feature",
        "properties": {"name": address},
        "geometry": {
          "type": "Point",
          "coordinates": [position.longitude, position.latitude]
        }
      });

      final url = Uri.parse('https://88collection.dndts.net/api/method/checkin');
      final response = await http.post(
        url,
        headers: {
          'Authorization': await _storage.read(key: 'auth_token') ?? '',
          'Content-Type': 'application/json',
        },
        body: json.encode({"geolocation": geolocation, "list": loc}),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Check-in successful at $address')));
      } else {
        throw Exception('Failed to mark check-in');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _fetchEmployeeDetail() async {
    final url = Uri.parse('https://88collection.dndts.net/api/method/employee_detail');

    try {
      String? token = await _storage.read(key: 'auth_token');
      if (token == null) {
        _showError('User not authenticated. Please login again.');
        return;
      }

      final response = await http.get(
        url,
        headers: {
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _employeeData = data['Data'];
        });
      } else {
        _showError('Failed to fetch employee details.');
      }
    } catch (e) {
      _showError('An error occurred while fetching employee details.');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    await _storage.delete(key: 'auth_token');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _fetchAttendanceDetails() async {
    final url = Uri.parse('https://88collection.dndts.net/api/method/attendance_detail');

    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        _showError('User not authenticated. Please login again.');
        return;
      }

      final response = await http.get(
        url,
        headers: {
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> attendanceList = data['Data'];

        List<Map<String, dynamic>> attendanceData = attendanceList.map((attendance) {
          return {
            'attendance_date': attendance['attendance_date'] ?? '',
            'status': attendance['status'] ?? '',
          };
        }).toList();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AttendancePage(attendanceData: attendanceData),
          ),
        );
      } else {
        _showError('Failed to fetch attendance details.');
      }
    } catch (e) {
      _showError('An error occurred while fetching attendance details.');
    }
  }

  void _fetchLeaveDetails() async {
    final url = Uri.parse('https://88collection.dndts.net/api/method/leave_detail');

    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        _showError('User not authenticated. Please login again.');
        return;
      }

      final response = await http.get(
        url,
        headers: {
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> leaveList = data['Data'];

        List<Map<String, dynamic>> leaveData = leaveList.map((leave) {
          return {
            'leave_type': leave['leave_type'] ?? '',
            'from_date': leave['from_date'] ?? '',
            'to_date': leave['to_date'] ?? '',
            'total_leave_days': leave['total_leave_days'] ?? '',
          };
        }).toList();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LeavePage(leaveData: leaveData),
          ),
        );
      } else {
        _showError('Failed to fetch leave details.');
      }
    } catch (e) {
      _showError('An error occurred while fetching leave details.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Employee Detail',
          style: TextStyle(fontFamily: 'Times New Roman',color: Colors.white), // Set the text color to white
        ),
        backgroundColor: Color(0xFF3d3d61), // Set the background color (use your preferred color)
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            color: Colors.white, // Set the icon color to white
            onPressed: _logout, // Log out when this button is pressed
          ),
        ],
      ),

      body: _employeeData == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(_employeeData!['custom_image_link'] ?? '', height: 100),
            Text('Name: ${_employeeData!['employee_name']}', style: TextStyle(fontSize: 18)),
            Text('Designation: ${_employeeData!['designation']}', style: TextStyle(fontSize: 18)),
            Text('Department: ${_employeeData!['Department']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String? token = await _storage.read(key: 'auth_token');
                if (token == null) {
                  _showError('User not authenticated. Please login again.');
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FetchLeaveTypesPage(), // Pass the token here
                  ),
                );
              },
              child: Text('Apply for Leave'),
            ),

          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _fetchAttendanceDetails,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/attendance_svg.png', height: 40, width: 40), // Adjust size as needed
                   // Space between icon and text
                  Text(''),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _fetchLeaveDetails,
              child: Text('Leaves'),
            ),
            ElevatedButton(
              onPressed: _markCheckin,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/checkin.jpg', height: 40, width: 40), // Adjust size as needed
                  // Space between icon and text
                  Text(''),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
