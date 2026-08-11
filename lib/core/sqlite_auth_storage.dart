import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite Database Storage Helper for Auth Sessions & Credentials
class SqliteAuthStorage {
  static final SqliteAuthStorage instance = SqliteAuthStorage._internal();
  SqliteAuthStorage._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = "$dbPath/hrportal_auth_v2.db";

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE user_auth (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
    );
  }

  Future<void> write(String key, String value) async {
    try {
      final db = await database;
      await db.insert(
        'user_auth',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('[SqliteAuthStorage Write Error]: $e');
    }
  }

  Future<String?> read(String key) async {
    try {
      final db = await database;
      final maps = await db.query(
        'user_auth',
        where: 'key = ?',
        whereArgs: [key],
      );
      if (maps.isNotEmpty) {
        return maps.first['value'] as String?;
      }
    } catch (e) {
      debugPrint('[SqliteAuthStorage Read Error]: $e');
    }
    return null;
  }

  Future<void> delete(String key) async {
    try {
      final db = await database;
      await db.delete(
        'user_auth',
        where: 'key = ?',
        whereArgs: [key],
      );
    } catch (e) {
      debugPrint('[SqliteAuthStorage Delete Error]: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      final db = await database;
      await db.delete('user_auth');
    } catch (e) {
      debugPrint('[SqliteAuthStorage Clear Error]: $e');
    }
  }

  /// Save full session & credentials to SQLite DB
  Future<void> saveSession({
    required String username,
    required String password,
    required String token,
    required String name,
    required String nidn,
    required String nip,
    required String email,
    required String role,
    required List<String> groups,
  }) async {
    await write('username', username);
    await write('password', password);
    await write('token', token);
    await write('name', name);
    await write('nidn', nidn);
    await write('nip', nip);
    await write('email', email);
    await write('role', role);
    await write('groups', jsonEncode(groups));
    await write('last_login', DateTime.now().toIso8601String());
  }

  /// Retrieve session from SQLite DB
  Future<Map<String, dynamic>?> getSession() async {
    final token = await read('token');
    if (token == null || token.isEmpty) return null;

    final username = await read('username') ?? '';
    final password = await read('password') ?? '';
    final name = await read('name') ?? '';
    final nidn = await read('nidn') ?? '';
    final nip = await read('nip') ?? '';
    final email = await read('email') ?? '';
    final role = await read('role') ?? '';
    final groupsRaw = await read('groups');
    List<String> groups = [];
    if (groupsRaw != null) {
      try {
        groups =
            (jsonDecode(groupsRaw) as List).map((e) => e.toString()).toList();
      } catch (_) {}
    }

    return {
      'username': username,
      'password': password,
      'token': token,
      'name': name,
      'nidn': nidn,
      'nip': nip,
      'email': email,
      'role': role,
      'groups': groups,
    };
  }
}
