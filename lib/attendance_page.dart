import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class AttendancePage extends StatefulWidget {
  final List<Map<String, dynamic>> attendanceData;

  const AttendancePage({super.key, required this.attendanceData});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late Map<DateTime, List<String>> _events;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _events = _mapAttendanceDataToEvents(widget.attendanceData);
    _selectedDay = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
  }

  Map<DateTime, List<String>> _mapAttendanceDataToEvents(List<Map<String, dynamic>> data) {
    Map<DateTime, List<String>> events = {};
    for (var entry in data) {
      final date = DateTime.parse(entry['attendance_date']);
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final status = entry['status'];

      if (events.containsKey(normalizedDate)) {
        events[normalizedDate]!.add(status);
      } else {
        events[normalizedDate] = [status];
      }
    }
    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Calendar'),
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
              // Remove marker, set to no markers
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
              // Use the defaultBuilder to customize day appearance
              defaultBuilder: (context, date, events) {
                final normalizedDay = DateTime(date.year, date.month, date.day);

                if (_events[normalizedDay] == null || _events[normalizedDay]!.isEmpty) {
                  return null;
                }

                final status = _events[normalizedDay]!.first; // Assuming one status per day for simplicity
                Color backgroundColor;
                switch (status) {
                  case 'Present':
                    backgroundColor = Colors.green.withOpacity(0.3); // Light green for present
                    break;
                  case 'Absent':
                    backgroundColor = Colors.red.withOpacity(0.3); // Light red for absent
                    break;
                  case 'On Leave':
                    backgroundColor = Colors.orange.withOpacity(0.3); // Light orange for on leave
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
                          scale: 0.6, // Scale down only the circle
                          child: Container(
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              shape: BoxShape.circle, // Make the highlight a circle
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
              children: _events[_selectedDay]!.map((status) {
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

                return ListTile(
                  title: Text(
                    'Status: $status',
                    style: TextStyle(color: textColor),
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
