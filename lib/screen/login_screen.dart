import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';
import '../globals.dart' as globals;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  bool isLoading = false;
  bool showOtpBox = false; // step 2
  String _userId = "";
  String _mob = "";

  /// Step 1: Login with mobile + password
  Future<void> login() async {
    final mob = _mobController.text.trim();
    final password = _passwordController.text.trim();

    if (mob.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter mobile & password')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${globals.ipAddress}/native_app/login.php?subject=login&action=chk'),
        body: {'mob': mob, 'password': password},
      );

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        // login success → store minimal info, show OTP box
        _userId = data['user_id'].toString();
        _mob = mob;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('user_id', _userId);
        await prefs.setString('mob', _mob);
        await prefs.setString('name', data['name']);

        setState(() {
          showOtpBox = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid login')),
        );
      }
    } catch (e) {
      print('HTTP error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Step 2: Verify OTP
  Future<void> verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter OTP')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${globals.ipAddress}/native_app/otp_match.php?subject=otp&action=match'),
        body: {
          'id': _userId,
          'mob': _mob,
          'otp': otp,
        },
      );

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isOtpVerified', true);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP, please try again')),
        );
        // reset to login
        setState(() {
          showOtpBox = false;
          _mobController.clear();
          _passwordController.clear();
          _otpController.clear();
        });
      }
    } catch (e) {
      print('HTTP error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("images/bg-1.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('images/cr_logo.png', width: 140),
            const SizedBox(height: 10),
            const Text(
              'LOGIN',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30,
                color: Color(0xFFcc4c99),
              ),
            ),
            const SizedBox(height: 20),

            if (!showOtpBox) ...[
              TextField(
                controller: _mobController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile Number'),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 40),
              isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: login,
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text(
                    'Login',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF600d41),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ] else ...[
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Enter OTP'),
              ),
              const SizedBox(height: 40),
              isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: verifyOtp,
                  icon: const Icon(Icons.verified, color: Colors.white),
                  label: const Text(
                    'Verify OTP',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
