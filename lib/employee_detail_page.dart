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
      String? ip = await _storage.read(key: 'ip');
      final url = Uri.parse('$ip/api/method/checkin');
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
    String? ip = await _storage.read(key: 'ip');
    final url = Uri.parse('$ip/api/method/employee_detail');

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
    String? ip = await _storage.read(key: 'ip');
    final url = Uri.parse('$ip/api/method/attendance_detail');

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
    String? ip = await _storage.read(key: 'ip');
    final url = Uri.parse('$ip/api/method/leave_detail');

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

        backgroundColor: Colors.white, // Set the background color
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            color: Colors.black, // Set the icon color to white
            onPressed: _logout, // Log out when this button is pressed
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: _employeeData == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(  // Center the image
              child: ClipOval(
                child: Image.network(
                  _employeeData!['custom_image_link'] ?? '',
                  height: 120,
                  width: 120,  // Ensure the width and height are the same for a perfect circle
                  fit: BoxFit.cover,  // Ensure the image fits well within the circle
                ),
              ),
            ),
            SizedBox(height: 10),
            Center(  // Center the name text
              child: Text('${_employeeData!['employee_name']}',
                  style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
            ),
            Center(  // Center the designation text
              child: Text('${_employeeData!['designation']}',
                  style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold)),
            ),

            SizedBox(height: 100),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3, // Number of columns
                crossAxisSpacing: 10, // Space between columns
                mainAxisSpacing: 10, // Space between rows
                children: [
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
                          builder: (context) => FetchLeaveTypesPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Rounded rectangle shape
                      ),
                      padding: EdgeInsets.all(0), // Adjust padding as needed
                      backgroundColor: Colors.white, // Set button color
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/leaveicon.png', // Replace with your icon path
                          height: 40, // Set height
                          width: 40, // Set width
                        ),
                        // Space between the icon and text
                        Text(
                          'Leave',
                          style: TextStyle(
                            fontSize: 12, // Adjust font size
                            color: Colors.black, // Adjust text color
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _fetchAttendanceDetails,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Rounded rectangle shape
                      ),
                      padding: EdgeInsets.all(0), // Adjust padding as needed
                      backgroundColor: Colors.white, // Set button color
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/attendance.png', // Replace with your icon path
                          height: 40, // Set height
                          width: 40, // Set width
                        ),
                        // Space between the icon and text
                        Text(
                          'Attendance',
                          style: TextStyle(
                            fontSize: 12, // Adjust font size
                            color: Colors.black, // Adjust text color
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Another button action
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Rounded rectangle shape
                      ),
                      padding: EdgeInsets.all(0), // Adjust padding as needed
                      backgroundColor: Colors.white, // Set button color
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/checkin.jpg', // Replace with your icon path
                          height: 40, // Set height
                          width: 40, // Set width
                        ),
                        // Space between the icon and text
                        Text(
                          'Checkin',
                          style: TextStyle(
                            fontSize: 12, // Adjust font size
                            color: Colors.black, // Adjust text color
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Another button action
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Rounded rectangle shape
                      ),
                      padding: EdgeInsets.all(0), // Adjust padding as needed
                      backgroundColor: Colors.white, // Set button color
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/team.png', // Replace with your icon path
                          height: 40, // Set height
                          width: 40, // Set width
                        ),
                        // Space between the icon and text
                        Text(
                          'My Team',
                          style: TextStyle(
                            fontSize: 12, // Adjust font size
                            color: Colors.black, // Adjust text color
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Another button action
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Rounded rectangle shape
                      ),
                      padding: EdgeInsets.all(0), // Adjust padding as needed
                      backgroundColor: Colors.white, // Set button color
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/salary.png', // Replace with your icon path
                          height: 40, // Set height
                          width: 40, // Set width
                        ),
                        // Space between the icon and text
                        Text(
                          'Salary',
                          style: TextStyle(
                            fontSize: 12, // Adjust font size
                            color: Colors.black, // Adjust text color
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Another button action
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Rounded rectangle shape
                      ),
                      padding: EdgeInsets.all(0), // Adjust padding as needed
                      backgroundColor: Colors.white, // Set button color
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/travel.png', // Replace with your icon path
                          height: 40, // Set height
                          width: 40, // Set width
                        ),
                        // Space between the icon and text
                        Text(
                          'Travel',
                          style: TextStyle(
                            fontSize: 12, // Adjust font size
                            color: Colors.black, // Adjust text color
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Another button action
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Rounded rectangle shape
                      ),
                      padding: EdgeInsets.all(0), // Adjust padding as needed
                      backgroundColor: Colors.white, // Set button color
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/holidays.png', // Replace with your icon path
                          height: 40, // Set height
                          width: 40, // Set width
                        ),
                        // Space between the icon and text
                        Text(
                          'Holidays',
                          style: TextStyle(
                            fontSize: 12, // Adjust font size
                            color: Colors.black, // Adjust text color
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Another button action
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Rounded rectangle shape
                      ),
                      padding: EdgeInsets.all(0), // Adjust padding as needed
                      backgroundColor: Colors.white, // Set button color
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/task.png', // Replace with your icon path
                          height: 40, // Set height
                          width: 40, // Set width
                        ),
                        // Space between the icon and text
                        Text(
                          'Tasks',
                          style: TextStyle(
                            fontSize: 12, // Adjust font size
                            color: Colors.black, // Adjust text color
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Another button action
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Rounded rectangle shape
                      ),
                      padding: EdgeInsets.all(0), // Adjust padding as needed
                      backgroundColor: Colors.white, // Set button color
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/calendar.png', // Replace with your icon path
                          height: 40, // Set height
                          width: 40, // Set width
                        ),
                        // Space between the icon and text
                        Text(
                          'Events',
                          style: TextStyle(
                            fontSize: 12, // Adjust font size
                            color: Colors.black, // Adjust text color
                          ),
                        ),
                      ],
                    ),
                  )
                  // Add more buttons as needed
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,  // Set the background color to grey
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,  // Center the content
          children: [
            TextButton(
              onPressed: _markCheckin,
              style: TextButton.styleFrom(
                padding: EdgeInsets.all(0),  // Remove any padding around the button
                shape: CircleBorder(),  // Make the button circular
              ),
              child: Image.asset(
                'assets/11527831.png',  // Replace with the path to your image
                height: 100,  // Set the height of the image
                width: 100,  // Set the width of the image
              ),
            ),
          ],
        ),
      ),



    );
  }

}
