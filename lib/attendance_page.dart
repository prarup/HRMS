import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class AttendancePage extends StatefulWidget {
  final List<Map<String, dynamic>> attendanceData;

  const AttendancePage({super.key, required this.attendanceData});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late Map<DateTime, List<Map<String, dynamic>>> _events; // Change to store complete data for the day
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _events = _mapAttendanceDataToEvents(widget.attendanceData);
    _selectedDay = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
  }

  Map<DateTime, List<Map<String, dynamic>>> _mapAttendanceDataToEvents(List<Map<String, dynamic>> data) {
    Map<DateTime, List<Map<String, dynamic>>> events = {};
    for (var entry in data) {
      final date = DateTime.parse(entry['attendance_date']);
      final normalizedDate = DateTime(date.year, date.month, date.day);

      if (events.containsKey(normalizedDate)) {
        events[normalizedDate]!.add(entry);
      } else {
        events[normalizedDate] = [entry];
      }
    }
    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendance Detail',
          style: TextStyle(fontFamily: 'Times New Roman', color: Colors.white), // Set the text color to white
        ),
        backgroundColor: Color(0xFF3d3d61),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2050, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            eventLoader: (day) {
              final normalizedDay = DateTime(day.year, day.month, day.day);
              return _events[normalizedDay] ?? [];
            },
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              markersMaxCount: 0,
              todayDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekendStyle: TextStyle(color: Colors.red),
            ),
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, date, events) {
                final normalizedDay = DateTime(date.year, date.month, date.day);

                if (_events[normalizedDay] == null || _events[normalizedDay]!.isEmpty) {
                  return null;
                }

                final status = _events[normalizedDay]!.first['status']; // Get status from data
                Color backgroundColor;
                switch (status) {
                  case 'Present':
                    backgroundColor = Colors.green.withOpacity(0.3);
                    break;
                  case 'Absent':
                    backgroundColor = Colors.red.withOpacity(0.3);
                    break;
                  case 'On Leave':
                    backgroundColor = Colors.orange.withOpacity(0.3);
                    break;
                  default:
                    backgroundColor = Colors.transparent;
                }

                return Container(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.scale(
                          scale: 0.6,
                          child: Container(
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Text(
                          '${date.day}',
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: _events[_selectedDay] == null || _events[_selectedDay]!.isEmpty
                ? const Center(child: Text('No attendance data for selected day'))
                : ListView(
              children: _events[_selectedDay]!.map((entry) {
                final status = entry['status'];
                final leaveType = entry['leave_type'] ?? 'N/A'; // Handle missing leave_type
                final inTime = entry['in_time'] ?? 'N/A'; // Handle missing in_time
                final outTime = entry['out_time'] ?? 'N/A'; // Handle missing out_time

                Color textColor;
                switch (status) {
                  case 'Present':
                    textColor = Colors.green;
                    break;
                  case 'Absent':
                    textColor = Colors.red;
                    break;
                  case 'On Leave':
                    textColor = Colors.orange;
                    break;
                  default:
                    textColor = Colors.black;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(
                      'Status: $status',
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Leave Type: $leaveType'),
                        Text('In Time: $inTime'),
                        Text('Out Time: $outTime'),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
