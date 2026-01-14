import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../globals.dart' as globals;

import 'home_screen.dart';

class IDCardScreen extends StatefulWidget {
  const IDCardScreen({super.key});

  @override
  State<IDCardScreen> createState() => _IDCardScreenState();
}

class _IDCardScreenState extends State<IDCardScreen> {
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = "";

  Map<String, dynamic>? cardData;

  @override
  void initState() {
    super.initState();
    _fetchIDCard();
  }

  Future<void> _fetchIDCard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? "";
      final mob = prefs.getString('mob') ?? "";

      final response = await http.post(
        Uri.parse("${globals.ipAddress}/native_app/id_card.php?subject=idcard&action=show"),
        body: {'id': userId, 'mob': mob},
      );

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        setState(() {
          cardData = data;
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          errorMessage = data['message'] ?? "Unknown error";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = "Something went wrong: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 🚀 Always replace with HomeScreen instead of normal back
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
        return false; // ❌ prevent default back navigation
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF104270),
          title: const Text("ID Card", style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : hasError
              ? Text(errorMessage,
              style: const TextStyle(fontSize: 16, color: Colors.red))
              : _buildIDCard(),
        ),
      ),
    );
  }

  Widget _buildIDCard() {
    if (cardData == null) return const SizedBox();

    final imgUrl = "${globals.ipAddress}/upload_image/emp/${cardData!['img_url']}";
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo
            Image.asset("images/dd_logo.jpg", width: 100),
            const SizedBox(height: 10),

            // User Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imgUrl,
                width: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.person, size: 100, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),

            // ID Category
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cardData!['id_category'],
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),

            // Name
            Row(
              children: [
                const Icon(Icons.account_box, color: Colors.indigo),
                const SizedBox(width: 6),
                const Text("Name: ",
                    style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text(cardData!['name'],
                    style: const TextStyle(color: Colors.black, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 10),

            // Emp Code
            Row(
              children: [
                const Icon(Icons.badge, color: Colors.blueGrey),
                const SizedBox(width: 6),
                const Text("EMP CODE: ",
                    style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text(cardData!['id_code'],
                    style: const TextStyle(color: Colors.black, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 10),

            // Mobile
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.green),
                const SizedBox(width: 6),
                const Text("Mobile: ",
                    style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text(cardData!['mob'],
                    style: const TextStyle(color: Colors.black, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 10),

            // Blood Group
            Row(
              children: [
                const Icon(Icons.bloodtype, color: Colors.red),
                const SizedBox(width: 6),
                const Text("Blood Group: ",
                    style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text(cardData!['id_blood'],
                    style: const TextStyle(color: Colors.black, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
