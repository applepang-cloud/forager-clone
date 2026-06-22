import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the full game snapshot to local storage (localStorage on web).
class SaveManager {
  static const _key = 'forager_save_v2';

  static Future<Map<String, dynamic>?> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString(_key);
      if (s == null) return null;
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(Map<String, dynamic> data) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, jsonEncode(data));
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_key);
    } catch (_) {}
  }
}
