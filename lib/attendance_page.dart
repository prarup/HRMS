import 'package:flutter/material.dart';

class AttendancePage extends StatelessWidget {
  final List<Map<String, dynamic>> attendanceData;

  const AttendancePage({super.key, required this.attendanceData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Details'),
      ),
      body: attendanceData.isEmpty
          ? Center(child: Text('No attendance data available'))
          : ListView.builder(
              itemCount: attendanceData.length,
              itemBuilder: (context, index) {
                final attendance = attendanceData[index];
                return ListTile(
                  title: Text('Date: ${attendance['attendance_date']}'),
                  subtitle: Text('Status: ${attendance['status']}'),
                );
              },
            ),
    );
  }
}
