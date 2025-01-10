import 'package:flutter/material.dart';
import 'login.dart';
import 'employee_detail_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final _storage = FlutterSecureStorage();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Detail',
      home: FutureBuilder<String?>(
        future: _storage.read(key: 'auth_token'),  // Check for stored auth token
        builder: (context, snapshot) {
          // If the connection is still loading, show a loading indicator
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          // If the token exists, navigate to EmployeeDetailPage
          if (snapshot.hasData && snapshot.data != null) {
            return EmployeeDetailPage();
          } else {
            // If no token, navigate to the LoginPage
            return LoginPage();
          }
        },
      ),
    );
  }
}
