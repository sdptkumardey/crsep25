import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../globals.dart' as globals;
import 'db_helper.dart';
import 'search_screen.dart';

class DetailsPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const DetailsPage({super.key, required this.data});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  int close = 0;
  String? closeSt;
  final TextEditingController remarksController = TextEditingController();
  bool hasInternet = true;
// class field
  StreamSubscription<List<ConnectivityResult>>? connectivitySub;

  @override
  void initState() {
    super.initState();
    _logDetail(widget.data);
    _checkInternet();

    // 🔴 Adjusted listener for List<ConnectivityResult>
    connectivitySub = Connectivity().onConnectivityChanged.listen((results) async {
      final realInternet = await _hasRealInternet();
      setState(() {
        // results is a List, take first (primary connection type)
        final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
        hasInternet = result != ConnectivityResult.none && realInternet;
      });
    });
  }

  @override
  void dispose() {
    connectivitySub?.cancel();
    super.dispose();
  }

  /// 🔍 Double-checks real internet (ping)
  Future<bool> _hasRealInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkInternet() async {
    final connectivity = await Connectivity().checkConnectivity();
    final realInternet = await _hasRealInternet();
    setState(() {
      hasInternet = connectivity != ConnectivityResult.none && realInternet;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Details", style: TextStyle(color: Colors.white),),
          backgroundColor: const Color(0xFF104270),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildRow(Icons.directions_car, "Reg No.", widget.data['reg_num']),
                      _divider(),
                      _buildRow(Icons.person, "Name", widget.data['name']),
                      _divider(),
                      _buildRow(Icons.settings, "Engine No.", widget.data['eng_num']),
                      _divider(),
                      _buildRow(Icons.confirmation_number, "Chasis No.", widget.data['chasis_no']),
                      _divider(),
                      _buildRow(Icons.account_balance, "Portfolio", widget.data['make']),
                      _divider(),
                      _buildRow(Icons.apps, "Asset No.", widget.data['asset']),
                      _divider(),
                      _buildRow(Icons.payments, "EMI OS", widget.data['emi_os']),
                      _divider(),
                      _buildRow(Icons.money_off, "DUE", widget.data['due']),
                      _divider(),
                      _buildRow(Icons.check_circle, "BCC", widget.data['bcc'] ?? "0"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (!hasInternet)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade400, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.red, size: 36), // bigger icon
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "No Internet Connection!\nYou need internet to close this call.",
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 18, // larger text
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                )

              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                  ),
                  onPressed: () {
                    setState(() {
                      close = 1;
                    });
                  },
                  child: const Text("CLOSE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),

              if (close == 1) ...[
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text("Close Status *",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: closeSt,
                  items: ["Repo", "Settlement"].map((status) {
                    return DropdownMenuItem(value: status, child: Text(status));
                  }).toList(),
                  onChanged: (val) => setState(() => closeSt = val),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text("Remarks",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: remarksController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Enter remarks (optional)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF104270),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                  ),
                  onPressed: _saveClose,
                  child: const Text("SAVE",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String? value) => Row(
    children: [
      Icon(icon, color: const Color(0xFF007095)),
      const SizedBox(width: 12),
      Expanded(flex: 2, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
      Expanded(flex: 3, child: Text(value ?? "")),
    ],
  );

  Widget _divider() => const Divider(color: Colors.grey, height: 20, thickness: 0.8);

  Future<void> _saveClose() async {
    if (closeSt == null) {
      _showAlert(false, "Please select Close Status");
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final emp = prefs.getString('user_id') ?? '';
      final mob = prefs.getString('mob') ?? '';

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      final url = Uri.parse(
          "${globals.ipAddress}/native_app/call_close.php?subject=call&action=close");

      final body = {
        "emp": emp,
        "mob": mob,
        "etype": widget.data["etype"] ?? "",
        "p_no": widget.data["p_no"] ?? "",
        "dpd": widget.data["dpd"] ?? "",
        "bcc": widget.data["bcc"] ?? "",
        "lpp": widget.data["lpp"] ?? "",
        "name": widget.data["name"] ?? "",
        "state": widget.data["state"] ?? "",
        "reg_num": widget.data["reg_num"] ?? "",
        "eng_num": widget.data["eng_num"] ?? "",
        "chasis_no": widget.data["chasis_no"] ?? "",
        "emi_os": widget.data["emi_os"] ?? "",
        "asset": widget.data["asset"] ?? "",
        "due": widget.data["due"] ?? "",
        "st_code": widget.data["st_code"] ?? "",
        "make": widget.data["make"] ?? "",
        "id": widget.data["id"] ?? "",
        "lat": pos.latitude.toString(),
        "lon": pos.longitude.toString(),
        "loc_address": "NA",
        "close": "1",
        "close_st": closeSt ?? "",
        "remarks": remarksController.text,
      };

      final res = await http.post(url, body: body);

      if (res.statusCode == 200) {
        final result = jsonDecode(res.body);
        _showAlert(result['success'], result['message']);
      } else {
        _showAlert(false, "Server error ${res.statusCode}");
      }
    } catch (e) {
      _showAlert(false, "Exception: $e");
    }
    // ... (your save logic unchanged)
  }

  void _showAlert(bool success, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(success ? Icons.check_circle : Icons.cancel,
                color: success ? Colors.green : Colors.red),
            const SizedBox(width: 10),
            Text(success ? "Success" : "Failed"),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (success) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => SearchScreen()),
                      (route) => false,
                );
              }
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  Future<void> _logDetail(Map<String, dynamic> record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emp = prefs.getString('user_id') ?? '';
      final mob = prefs.getString('mob') ?? '';

      if (emp.isEmpty || mob.isEmpty) {
        debugPrint("⚠️ Missing emp/mob, skipping detail log");
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final log = {
        "emp": emp,
        "mob": mob,
        "etype": record["etype"] ?? "",
        "p_no": record["p_no"] ?? "",
        "dpd": record["dpd"] ?? "",
        "bcc": record["bcc"] ?? "",
        "lpp": record["lpp"] ?? "",
        "close": record["close"] ?? "",
        "name": record["name"] ?? "",
        "state": record["state"] ?? "",
        "reg_num": record["reg_num"] ?? "",
        "eng_num": record["eng_num"] ?? "",
        "chasis_no": record["chasis_no"] ?? "",
        "emi_os": record["emi_os"] ?? "",
        "asset": record["asset"] ?? "",
        "due": record["due"] ?? "",
        "st_code": record["st_code"] ?? "",
        "make": record["make"] ?? "",
        "repo_id": record["id"] ?? "",
        "lat": pos.latitude.toString(),
        "lon": pos.longitude.toString(),
        "loc_address": "NA",
        "created_on": DateTime.now().toIso8601String(),
      };

      await DBHelper.instance.insertDetailLog(log);
      debugPrint("✅ Detail log saved locally: $log");
    } catch (e) {
      debugPrint("❌ Exception logging detail: $e");
    }
  }
}
