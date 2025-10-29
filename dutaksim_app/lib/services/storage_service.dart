import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';

  static Future<void> saveUser({
    required String id,
    required String name,
    required String phone,
    String? token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.userIdKey, id);
    await prefs.setString(Constants.userNameKey, name);
    await prefs.setString(Constants.userPhoneKey, phone);
    if (token != null) {
      await prefs.setString(_tokenKey, token);
    }
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<Map<String, String>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(Constants.userIdKey);
    final name = prefs.getString(Constants.userNameKey);
    final phone = prefs.getString(Constants.userPhoneKey);

    if (id == null || name == null || phone == null) {
      return null;
    }

    return {
      'id': id,
      'name': name,
      'phone': phone,
    };
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(Constants.userIdKey);
    await prefs.remove(Constants.userNameKey);
    await prefs.remove(Constants.userPhoneKey);
    await prefs.remove(_tokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final user = await getUser();
    return user != null;
  }
}
