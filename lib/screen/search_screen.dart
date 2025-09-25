import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:geolocator/geolocator.dart';
import '../globals.dart' as globals;
import 'db_helper.dart';
import 'details_page.dart';
import 'home_screen.dart';

class SearchScreen extends StatefulWidget {
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  String searchMode = "reg_num"; // reg_num, eng_num, chasis_no, name
  String selectedPrefix = "ALL";
  String queryText = "";
  Timer? _debounce;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> wbResults = [];
  List<Map<String, dynamic>> otherResults = [];
  List<String> prefixOptions = ["ALL"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkRowCount();
    _loadPrefixes();
  }

  Future<void> _checkRowCount() async {
    final db = await DBHelper.instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM repo_data'),
    );
    debugPrint("📊 Repo_data table has $count rows.");
  }

  Future<void> _loadPrefixes() async {
    final db = await DBHelper.instance.database;
    final result = await db.rawQuery(
        "SELECT DISTINCT UPPER(substr(reg_num,1,2)) as prefix "
            "FROM repo_data "
            "WHERE substr(reg_num,1,2) <> '' "
            "ORDER BY prefix");

    setState(() {
      prefixOptions = ["ALL"];
      prefixOptions.addAll(result.map((e) => e['prefix'].toString()).toList());
    });
  }

  void _onSearchChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (text.length < 4) return;

    setState(() {
      queryText = text;
    });

    // after 3s idle → perform search + trigger log
    _debounce = Timer(const Duration(seconds: 3), () async {
      await _performSearch(queryText);

      // 🚀 Don't await here → run in background
      _fetchLocationAndLog(queryText);

      // 👇 Clear only the input field, keep results
      _searchController.clear();
    });
  }



  Future<void> _performSearch(String text) async {
    final start = DateTime.now(); // ⏱️ start timer

    final db = await DBHelper.instance.database;
    String where = "";
    List<dynamic> args = [];

    if (searchMode == "reg_num" && selectedPrefix != "ALL") {
      where += "UPPER(substr(reg_num,1,2))=?";
      args.add(selectedPrefix.toUpperCase());
    }

    if (text.isNotEmpty) {
      if (where.isNotEmpty) where += " AND ";
      where += "UPPER($searchMode) LIKE ?";
      args.add("%${text.toUpperCase()}%");
    }

    final results = await db.query(
      "repo_data",
      where: where.isNotEmpty ? where : null,
      whereArgs: args,
    );

    final end = DateTime.now(); // ⏱️ stop timer
    final elapsed = end.difference(start).inMilliseconds;

    debugPrint("🔍 Search completed in ${elapsed}ms, results: ${results.length}");

    setState(() {
      wbResults = results
          .where((e) => e['reg_num'].toString().toUpperCase().startsWith("WB"))
          .toList();
      otherResults = results
          .where((e) => !e['reg_num'].toString().toUpperCase().startsWith("WB"))
          .toList();
    });
  }


  Future<void> _fetchLocationAndLog(String typed) async {
    try {
      // Get saved user details
      final prefs = await SharedPreferences.getInstance();
      final emp  = prefs.getString('user_id') ?? '';
      final name = prefs.getString('name') ?? '';
      final mob  = prefs.getString('mob') ?? '';

      if (emp.isEmpty || mob.isEmpty) {
        debugPrint("⚠️ Missing emp or mob in prefs. Skipping log.");
        return;
      }

      // Ask for location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint("❌ Location permissions are permanently denied.");
        return;
      }

      // Get current position
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocode via Nominatim
      final url = Uri.parse(
          "https://nominatim.openstreetmap.org/reverse?lat=${pos.latitude}&lon=${pos.longitude}&format=json");

      final response = await http.get(url, headers: {
        "User-Agent": "CredSepApp/1.0 (contact@yourdomain.com)"
      });

      String address = "Unknown";
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        address = data['display_name'] ?? "Address not found";
      }

      // Prepare log data
      final log = {
        "emp": emp,
        "name": name,
        "mob": mob,
        "typed": typed,
        "lat": pos.latitude.toString(),
        "lon": pos.longitude.toString(),
        "loc_address": address,
        "created_on": DateTime.now().toIso8601String(),
      };

      // Save locally
      await DBHelper.instance.insertSearchLog(log);

      // Debug print logs
      final logs = await DBHelper.instance.getSearchLogs();
      debugPrint("📋 Current local logs: $logs");

    } catch (e) {
      debugPrint("❌ Exception while logging search: $e");
    }
  }



  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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
          iconTheme: const IconThemeData(color: Colors.white),
          automaticallyImplyLeading: false, // 🚫 disables back button
          title: InkWell(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HomeScreen()),
              );
            },
            child: Row(
              children: const [
                Icon(Icons.home, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  "Search Open Data",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      
      
        body: Column(
          children: [
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildModeButton("Reg-Num", "reg_num"),
                  const SizedBox(width: 6),
                  _buildModeButton("Engine-Num", "eng_num"),
                  const SizedBox(width: 6),
                  _buildModeButton("Chasis-Num", "chasis_no"),
                  const SizedBox(width: 6),
                  _buildModeButton("Name", "name"),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  if (searchMode == "reg_num")
                    Expanded(
                      flex: 2,
                      child: DropdownButton<String>(
                        value: selectedPrefix,
                        isExpanded: true,
                        items: prefixOptions
                            .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedPrefix = val!;
                          });
                          if (queryText.length >= 4) {
                            _performSearch(queryText);
                          }
                        },
                      ),
                    ),
                  if (searchMode == "reg_num") const SizedBox(width: 10),
                  Expanded(
                    flex: searchMode == "reg_num" ? 4 : 6,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: "Enter at least 4 chars",
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ],
              ),
            ),
      
      
            if (queryText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Search - "$queryText" found ${wbResults.length + otherResults.length} records',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
      
            TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: [
                Tab(text: "WB (${wbResults.length})"),
                Tab(text: "OTHERS (${otherResults.length})"),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildResultList(wbResults),
                  _buildResultList(otherResults),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(String label, String mode) {
    final bool isSelected = searchMode == mode;
    return Expanded(
      child: SizedBox(
        height: 38,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
            isSelected ? const Color(0xFFFF9800) : const Color(0xFF007095),
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero, // ✅ removes default left/right padding
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            side: isSelected
                ? const BorderSide(color: Colors.black, width: 2)
                : BorderSide.none,
          ),
          onPressed: () {
            setState(() {
              searchMode = mode;
              selectedPrefix = "ALL";
            });
          },
          child: Center(
            child: Text(
              label,
              maxLines: 1, // ✅ force single line
              overflow: TextOverflow.visible, // ✅ don’t cut with ...
              style: TextStyle(
                fontSize: 12, // ✅ bigger text
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }




  Widget _buildResultList(List<Map<String, dynamic>> results) {
    return ListView.builder(
      itemCount: (results.length / 2).ceil(),
      itemBuilder: (ctx, i) {
        final first = results[i * 2];
        final second = (i * 2 + 1 < results.length) ? results[i * 2 + 1] : null;
        return Row(
          children: [
            _buildRecordBox(first),
            if (second != null) _buildRecordBox(second),
          ],
        );
      },
    );
  }

  Widget _buildRecordBox(Map<String, dynamic> record) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailsPage(data: record)),
          );
        },
        child: Container(
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              record['reg_num'] ?? "",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
