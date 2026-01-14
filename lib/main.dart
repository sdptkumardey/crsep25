import 'package:flutter/material.dart';
import 'package:crsep25/screen/home_screen.dart';
import 'package:crsep25/screen/login_screen.dart';
import 'package:crsep25/screen/id_card_screen.dart';  // ✅ Import here
import 'package:crsep25/screen/sync_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
void main() {
  runApp(const MyApp());
  // Start sync service when app launches
  SyncService().startSyncTimer();
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final isOtpVerified = prefs.getBool('isOtpVerified') ?? false;
    return isLoggedIn && isOtpVerified;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DEBT COLLECTION',
      theme: ThemeData(primarySwatch: Colors.blue),
      routes: {
        '/home': (_) => HomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/idcard': (_) => const IDCardScreen(),  // ✅ add route
      },
      home: FutureBuilder<bool>(
        future: _checkLogin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.data == true) {
            return HomeScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
