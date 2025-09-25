import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../globals.dart' as globals;

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  bool isLoading = false;
  String userName = '';

  @override
  void initState() {
    super.initState();
    loadUserName();
  }

  Future<void> loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('name') ?? '';
    });
  }

  Future<void> markAttendance(int attSt) async {
    // ✅ Step 1: Check permissions
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission is required to mark attendance.")),
        );
        return; // stop here
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Location permissions are permanently denied. Please enable them from settings."),
        ),
      );
      return; // stop here
    }

    // ✅ Step 2: Safe to use GPS now
    setState(() => isLoading = true);

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );

    // ✅ Step 3: Continue with API call (same as before)
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    final name = prefs.getString('name') ?? '';
    final mob = prefs.getString('mob') ?? '';

    final response = await http.post(
      Uri.parse("${globals.ipAddress}/native_app/attendance.php?subject=att&action=register"),
      body: {
        'user_id': userId,
        'name': name,
        'mob': mob,
        'lat': position.latitude.toString(),
        'lon': position.longitude.toString(),
        'att_st': attSt.toString(),
      },
    );

    final result = jsonDecode(response.body);
    if (result['status'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance saved successfully")),
      );
      Navigator.pop(context); // Go back to Home after marking
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save attendance")),
      );
    }

    setState(() => isLoading = false);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF104270),
        title: const Text("Attendance", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('images/att3.png', height: 250),
            const SizedBox(height: 30),
            Text(
              "Please mark your attendance for today:",
              style: const TextStyle(fontSize: 20.0),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 300.0,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text("Present",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => markAttendance(1),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 300.0,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.close, color: Colors.white),
                label: const Text("Absent",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => markAttendance(0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
