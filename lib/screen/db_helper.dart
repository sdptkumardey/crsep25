import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('repo.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5, // 🚀 bump version (new table)
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // repo_data table
    await db.execute('''
      CREATE TABLE repo_data (
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

    // search_logs table
    await db.execute('''
      CREATE TABLE search_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        emp TEXT,
        name TEXT,
        mob TEXT,
        typed TEXT,
        lat TEXT,
        lon TEXT,
        loc_address TEXT,
        created_on TEXT
      )
    ''');

    // detail_logs table
    await db.execute('''
      CREATE TABLE detail_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        emp TEXT,
        mob TEXT,
        etype TEXT,
        p_no TEXT,
        dpd TEXT,
        bcc TEXT,
        lpp TEXT,
        close TEXT,
        name TEXT,
        state TEXT,
        reg_num TEXT,
        eng_num TEXT,
        chasis_no TEXT,
        emi_os TEXT,
        asset TEXT,
        due TEXT,
        st_code TEXT,
        make TEXT,
        repo_id TEXT,
        lat TEXT,
        lon TEXT,
        loc_address TEXT,
        created_on TEXT
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Always ensure tables exist
    await db.execute('''
      CREATE TABLE IF NOT EXISTS search_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        emp TEXT,
        name TEXT,
        mob TEXT,
        typed TEXT,
        lat TEXT,
        lon TEXT,
        loc_address TEXT,
        created_on TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS detail_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        emp TEXT,
        mob TEXT,
        etype TEXT,
        p_no TEXT,
        dpd TEXT,
        bcc TEXT,
        lpp TEXT,
        close TEXT,
        name TEXT,
        state TEXT,
        reg_num TEXT,
        eng_num TEXT,
        chasis_no TEXT,
        emi_os TEXT,
        asset TEXT,
        due TEXT,
        st_code TEXT,
        make TEXT,
        repo_id TEXT,
        lat TEXT,
        lon TEXT,
        loc_address TEXT,
        created_on TEXT
      )
    ''');
  }

  // ----------------- Search Logs -----------------
  Future<void> insertSearchLog(Map<String, dynamic> log) async {
    final db = await instance.database;
    await db.insert("search_logs", log);
    debugPrint("💾 SearchLog saved locally: $log");
  }

  Future<List<Map<String, dynamic>>> getSearchLogs() async {
    final db = await instance.database;
    return await db.query("search_logs", orderBy: "id DESC");
  }

  Future<void> clearSearchLogs() async {
    final db = await instance.database;
    await db.delete("search_logs");
    debugPrint("🧹 All local search logs cleared");
  }

  // ----------------- Detail Logs -----------------
  Future<void> insertDetailLog(Map<String, dynamic> log) async {
    final db = await instance.database;
    await db.insert("detail_logs", log);
    debugPrint("💾 DetailLog saved locally: $log");
  }

  Future<List<Map<String, dynamic>>> getDetailLogs() async {
    final db = await instance.database;
    return await db.query("detail_logs", orderBy: "id DESC");
  }

  Future<void> clearDetailLogs() async {
    final db = await instance.database;
    await db.delete("detail_logs");
    debugPrint("🧹 All local detail logs cleared");
  }
}
