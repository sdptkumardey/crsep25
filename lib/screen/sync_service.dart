import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'db_helper.dart';
import '../globals.dart' as globals;

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;

  SyncService._internal();

  Timer? _timer;

  void startSyncTimer() {
    _timer = Timer.periodic(const Duration(minutes: 2), (timer) async {
      await _syncSearchLogs();
      await _syncDetailLogs();
    });
    debugPrint("⏳ SyncService started");
  }

  void stopSyncTimer() {
    _timer?.cancel();
    debugPrint("🛑 SyncService stopped");
  }

  Future<void> _syncSearchLogs() async {
    await _syncGenericLogs(
      tableName: "search_logs",
      fetchFn: DBHelper.instance.getSearchLogs,
      clearFn: DBHelper.instance.clearSearchLogs,
      url: "${globals.ipAddress}/native_app/search_type2.php?subject=search&action=track",
    );
  }

  Future<void> _syncDetailLogs() async {
    await _syncGenericLogs(
      tableName: "detail_logs",
      fetchFn: DBHelper.instance.getDetailLogs,
      clearFn: DBHelper.instance.clearDetailLogs,
      url: "${globals.ipAddress}/native_app/search_track2.php?subject=search&action=track",
    );
  }

  Future<void> _syncGenericLogs({
    required String tableName,
    required Future<List<Map<String, dynamic>>> Function() fetchFn,
    required Future<void> Function() clearFn,
    required String url,
  }) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        debugPrint("⚠️ No internet, skipping sync for $tableName");
        return;
      }

      final logs = await fetchFn();
      if (logs.isEmpty) {
        debugPrint("✅ No $tableName to sync");
        return;
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(logs),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          await clearFn();
          debugPrint("☁️ Synced ${logs.length} $tableName, cleared local table");
        } else {
          debugPrint("⚠️ Server rejected $tableName sync: ${result['error']}");
        }
      } else {
        debugPrint("❌ Server error for $tableName: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Exception in $tableName sync: $e");
    }
  }
}
