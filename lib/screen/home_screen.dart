import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../globals.dart' as globals;
import 'attendance_page.dart';
import 'app_drawer.dart';
import 'db_helper.dart';
import 'repo_model.dart';
import 'search_screen.dart';
import 'package:sqflite/sqflite.dart';

class HomeScreen extends StatefulWidget {
  static String id = 'home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = '';
  bool isLoading = true;
  bool showAttendanceButton = false;
  double _progress = 0.0; // progress 0.0–1.0

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _loadUserAndCheckAttendance();
  }

  Future<void> _printRandValues() async {
    final prefs = await SharedPreferences.getInstance();
    final r1 = prefs.getString('rand1') ?? 'not set';
    final r2 = prefs.getString('rand2') ?? 'not set';
    final r3 = prefs.getString('rand3') ?? 'not set';
    debugPrint("🎲 Rand values → rand1: $r1, rand2: $r2, rand3: $r3");
  }

  Future<void> _initPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('rand1')) {
      await prefs.setString('rand1', '0');
      await prefs.setString('rand2', '0');
      await prefs.setString('rand3', '0');
    }
  }

  Future<void> _loadUserAndCheckAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('user_id') ?? '';
    final mob = prefs.getString('mob') ?? '';
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    setState(() {
      userName = prefs.getString('name') ?? '';
    });

    final lastAttDate = prefs.getString('last_att_date') ?? '';
    final attMarked = prefs.getBool('att_marked') ?? false;

    if (lastAttDate == today && attMarked == true) {
      setState(() {
        showAttendanceButton = false;
        isLoading = false;
      });
      await _loadRepoData();
      await _printRowCount();
      return;
    }

    final response = await http.post(
      Uri.parse("${globals.ipAddress}/native_app/attendance.php?subject=att&action=chk"),
      body: {'user_id': uid, 'mob': mob},
    );

    final data = jsonDecode(response.body);

    if (data['att_show'] == true) {
      setState(() {
        showAttendanceButton = true;
        isLoading = false;
      });
    } else {
      await prefs.setString('last_att_date', today);
      await prefs.setBool('att_marked', true);
      setState(() {
        showAttendanceButton = false;
        isLoading = false;
      });
      await _loadRepoData();
    }
  }

  Future<void> _loadRepoData() async {
    setState(() {
      isLoading = true;
      _progress = 0.0;
    });

    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('user_id') ?? '';
    final mob = prefs.getString('mob') ?? '';
    final rand1 = prefs.getString('rand1') ?? '0';
    final rand2 = prefs.getString('rand2') ?? '0';
    final rand3 = prefs.getString('rand3') ?? '0';

    final response = await http.post(
      Uri.parse("${globals.ipAddress}/native_app/repo_date.php?subject=repo&action=load"),
      body: {'id': uid, 'mob': mob, 'rand1': rand1, 'rand2': rand2, 'rand3': rand3},
    );

    final data = jsonDecode(response.body);

    await prefs.setString('rand1', data['rand1']);
    await prefs.setString('rand2', data['rand2']);
    await prefs.setString('rand3', data['rand3']);

    final listData = data['list_data'] as List<dynamic>? ?? [];
    if (listData.isNotEmpty) {
      final db = await DBHelper.instance.database;
      await db.delete("repo_data");

      const chunkSize = 5000;
      for (var i = 0; i < listData.length; i += chunkSize) {
        final end = (i + chunkSize < listData.length) ? i + chunkSize : listData.length;
        final chunk = listData.sublist(i, end);

        await db.transaction((txn) async {
          final batch = txn.batch();
          for (var item in chunk) {
            batch.insert('repo_data', RepoData.fromJson(item).toMap());
          }
          await batch.commit(noResult: true);
        });

        setState(() {
          _progress = end / listData.length;
        });

        debugPrint("📥 Inserted $end / ${listData.length} rows");
      }

      final count =
      Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM repo_data'));
      debugPrint("✅ Repo data saved in SQLite. Row count: $count");
    } else {
      debugPrint("⚠️ No data received from API.");
    }

    await _printRandValues();

    setState(() {
      _progress = 0.0;
      isLoading = false;
    });
  }

  Future<void> _resetAndReload(BuildContext context) async {
    final db = await DBHelper.instance.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS repo_data (
        id TEXT PRIMARY KEY,
        etype TEXT,
        p_no TEXT,
        dpd TEXT,
        bcc TEXT,
        lpp TEXT,
        name TEXT,
        reg_num TEXT,
        eng_num TEXT,
        chasis_no TEXT,
        st_code TEXT,
        state TEXT,
        emi_os TEXT,
        due TEXT,
        asset TEXT,
        make TEXT,
        close TEXT
      )
    ''');

    await db.delete("repo_data");

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("rand1", "0");
    await prefs.setString("rand2", "0");
    await prefs.setString("rand3", "0");

    debugPrint("🗑️ Table cleared & prefs reset. Reloading data...");

    await _loadRepoData();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Data reset and reloaded")),
      );
    }
  }

  Future<void> _printRowCount() async {
    final db = await DBHelper.instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM repo_data'),
    );
    debugPrint("📊 Repo_data table has $count rows.");
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF104270),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            const Icon(Icons.person, color: Colors.white),
            const SizedBox(width: 8),
            Text(userName.isNotEmpty ? userName : "HOME",
                style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
      drawer: AppDrawer(
        userName: userName,
        onResetReload: _resetAndReload,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFd9f2f2), Color(0xFFabb3fe)], // Teal → Indigo
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: isLoading
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              if (_progress > 0)
                Column(
                  children: [
                    LinearProgressIndicator(value: _progress),
                    const SizedBox(height: 8),
                    Text("${(_progress * 100).toStringAsFixed(1)}% Loaded"),
                  ],
                ),
            ],
          )
              : showAttendanceButton
              ? ElevatedButton.icon(
            icon: const Icon(Icons.fingerprint, color: Colors.white),
            label: const Text("Mark Attendance",
                style: TextStyle(color: Colors.white, fontSize: 18)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(
                  horizontal: 30, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AttendancePage()),
              );
              _loadUserAndCheckAttendance();
            },
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔎 Search Data button
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // 🔎 Search Data card
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SearchScreen()),
                          );
                        },
                        child: Card(
                          color: Colors.teal,
                          elevation: 6,
                          shape:
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Container(
                            height: 160,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.search, size: 50, color: Colors.white),
                                SizedBox(height: 12),
                                Text(
                                  "Search Data",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // 🪪 ID Card card
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/idcard');
                        },
                        child: Card(
                          color: Colors.indigo,
                          elevation: 6,
                          shape:
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Container(
                            height: 160,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.badge, size: 50, color: Colors.white),
                                SizedBox(height: 12),
                                Text(
                                  "ID Card",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 🔄 Refresh button at bottom
              IconButton(
                icon: const Icon(Icons.refresh,
                    size: 40, color: Colors.red),
                onPressed: () async {
                  _initPrefs();
                  _loadUserAndCheckAttendance();
                },
              ),
              const Text("Refresh",
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

}
