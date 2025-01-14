// company_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';

class CompanyScreen extends StatefulWidget {
  @override
  _CompanyScreenState createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  final TextEditingController _companyController = TextEditingController();
  final _storage = FlutterSecureStorage();
  bool _isLoading = false;
  String? _errorMessage;

  void _next() async {
    if (_companyController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Company is required.';
      });
      return;
    }

    final url = Uri.parse('http://45.115.217.134:82/api/method/hrmapping');
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        url,
        body: {'company': _companyController.text},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ip = data['Data']['ip'];
        final imageUrl = data['Data']['imageurl'];
        final company = data['Data']['company'];

        // Store the IP and image URL in secure storage
        await _storage.write(key: 'ip', value: ip);
        await _storage.write(key: 'image_url', value: imageUrl);
        await _storage.write(key: 'company', value: company);

        // Navigate to login screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch data. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again later.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Company')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _companyController,
              decoration: InputDecoration(
                hintText: 'Enter Company Name',
                filled: true,
                fillColor: Colors.grey[200],
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _next,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
