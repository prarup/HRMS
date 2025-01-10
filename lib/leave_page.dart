import 'package:flutter/material.dart';

class LeavePage extends StatelessWidget {
  final List<Map<String, dynamic>> leaveData;

  const LeavePage({super.key, required this.leaveData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leave Details'),
      ),
      body: leaveData.isEmpty
          ? Center(child: Text('No Leave data available'))
          : ListView.builder(
              itemCount: leaveData.length,
              itemBuilder: (context, index) {
                final leave = leaveData[index];
                return ListTile(
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('From Date: ${leave['from_date']}'),
                      Text('To Date: ${leave['to_date']}'),
                      Text('Total Leave Days: ${leave['total_leave_days']}'),
                    ],
                  ),
                  title: Text('Leave Type: ${leave['leave_type']}'),
                );
              },
            ),
    );
  }
}
