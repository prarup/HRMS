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
      appBar: AppBar(title: const Text(''),backgroundColor: Color(0xFFFFFFFF),),
      body: Container(
        color: Colors.white,  // Set the body color to white
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Image.asset('assets/applogo.png', height: 100),
            const SizedBox(height: 25),
            TextField(
              controller: _companyController,
              decoration: InputDecoration(
                hintText: 'Enter Company Name',
                filled: true,
                fillColor: Colors.grey[200],
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Color(0xFFFFFFFF)!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.blue),
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(10.0), // Adjust padding as needed
                  child: Image.asset(
                    'assets/company.png', // Replace with your asset icon path
                    height: 20, // Adjust size as needed
                  ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Adjust padding to make the button smaller
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Next',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Powered by Dots and Dashes',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
