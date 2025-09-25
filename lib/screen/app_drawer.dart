import 'package:flutter/material.dart';
import 'logout_screen.dart';
import 'home_screen.dart';

class AppDrawer extends StatelessWidget {
  final String userName;
  final Future<void> Function(BuildContext) onResetReload;

  const AppDrawer({
    super.key,
    required this.userName,
    required this.onResetReload,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF104270)),
              accountName: Text(userName.isNotEmpty ? userName : "Guest"),
              accountEmail: const Text(""),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Color(0xFF104270)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.blue),
              title: const Text("Home"),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => HomeScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.blue),
              title: const Text("Attendance"),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Go to Attendance Page")),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.badge, color: Colors.green),
              title: const Text("ID Card"),
              onTap: () {
                Navigator.pushNamed(context, '/idcard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.red),
              title: const Text("Reset & Reload"),
              onTap: () async {
                Navigator.pop(context); // close drawer
                await onResetReload(context); // ✅ callback to HomeScreen
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout"),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LogoutScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
