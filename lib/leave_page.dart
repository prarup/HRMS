import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class LeavePage extends StatelessWidget {
  final List<Map<String, dynamic>> leaveData;

  const LeavePage({super.key, required this.leaveData});

  @override
  Widget build(BuildContext context) {
    // Create a set of dates for leave days to highlight on the calendar
    Set<DateTime> leaveDates = leaveData
        .map((leave) => DateTime.parse(leave['from_date'])) // Assuming from_date is in a parsable format
        .toSet();

    return Scaffold(
      appBar: AppBar(
        title: Text('Leave Details'),
      ),
      body: Column(
        children: [
          // Calendar View
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TableCalendar(
              focusedDay: DateTime.now(),
              firstDay: DateTime.utc(2020, 01, 01),
              lastDay: DateTime.utc(2025, 12, 31),
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) {
                // Select the current day, if today's date
                return isSameDay(day, DateTime.now());
              },
              onDaySelected: (selectedDay, focusedDay) {
                // You can handle day selection here if needed
              },
              eventLoader: (day) {
                // If leave exists on that day, show it as an event
                return leaveDates.contains(day) ? ['Leave'] : [];
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Container(
                      width: 6.0,
                      height: 6.0,
                      decoration: BoxDecoration(
                        color: Colors.yellow,
                        shape: BoxShape.circle,
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
          ),
          // Leave details section
          leaveData.isEmpty
              ? Expanded(child: Center(child: Text('No Leave data available')))
              : Expanded(
            child: ListView.builder(
              itemCount: leaveData.length,
              itemBuilder: (context, index) {
                final leave = leaveData[index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Leave Type: ${leave['leave_type']}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8.0),
                        Text('From Date: ${leave['from_date']}'),
                        Text('To Date: ${leave['to_date']}'),
                        Text('Total Leave Days: ${leave['total_leave_days']}'),
                      ],
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
}
