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
        title: Text('Attendance Calendar'),
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
              markersMaxCount: 1,
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: _events[_selectedDay] == null || _events[_selectedDay]!.isEmpty
                ? Center(child: Text('No attendance data for selected day'))
                : ListView(
              children: _events[_selectedDay]!
                  .map((status) => ListTile(
                title: Text('Status: $status'),
              ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

