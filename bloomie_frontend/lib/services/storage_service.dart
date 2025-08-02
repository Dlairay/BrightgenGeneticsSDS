import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/logger.dart';

class StorageService {
  static const _secureStorage = FlutterSecureStorage();
  static SharedPreferences? _prefs;
  
  // Initialize shared preferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    AppLogger.info('Storage service initialized');
  }
  
  // Secure storage methods (for sensitive data)
  static Future<void> saveSecureData(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      AppLogger.info('Secure data saved for key: $key');
    } catch (e) {
      AppLogger.error('Failed to save secure data', error: e);
    }
  }
  
  static Future<String?> getSecureData(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      AppLogger.error('Failed to read secure data', error: e);
      return null;
    }
  }
  
  static Future<void> deleteSecureData(String key) async {
    try {
      await _secureStorage.delete(key: key);
      AppLogger.info('Secure data deleted for key: $key');
    } catch (e) {
      AppLogger.error('Failed to delete secure data', error: e);
    }
  }
  
  static Future<void> clearAllSecureData() async {
    try {
      await _secureStorage.deleteAll();
      AppLogger.info('All secure data cleared');
    } catch (e) {
      AppLogger.error('Failed to clear secure data', error: e);
    }
  }
  
  // Shared preferences methods (for non-sensitive data)
  static Future<bool> setBool(String key, bool value) async {
    try {
      return await _prefs!.setBool(key, value);
    } catch (e) {
      AppLogger.error('Failed to save bool', error: e);
      return false;
    }
  }
  
  static bool? getBool(String key) {
    try {
      return _prefs!.getBool(key);
    } catch (e) {
      AppLogger.error('Failed to get bool', error: e);
      return null;
    }
  }
  
  static Future<bool> setString(String key, String value) async {
    try {
      return await _prefs!.setString(key, value);
    } catch (e) {
      AppLogger.error('Failed to save string', error: e);
      return false;
    }
  }
  
  static String? getString(String key) {
    try {
      return _prefs!.getString(key);
    } catch (e) {
      AppLogger.error('Failed to get string', error: e);
      return null;
    }
  }
  
  static Future<bool> setStringList(String key, List<String> value) async {
    try {
      return await _prefs!.setStringList(key, value);
    } catch (e) {
      AppLogger.error('Failed to save string list', error: e);
      return false;
    }
  }
  
  static List<String>? getStringList(String key) {
    try {
      return _prefs!.getStringList(key);
    } catch (e) {
      AppLogger.error('Failed to get string list', error: e);
      return null;
    }
  }
  
  static Future<bool> clear() async {
    try {
      return await _prefs!.clear();
    } catch (e) {
      AppLogger.error('Failed to clear preferences', error: e);
      return false;
    }
  }
  
  // Storage keys
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keyChatHistory = 'chat_history';
  static const String keyQuestionnaireProgress = 'questionnaire_progress';
}