import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages API keys and environment configuration.
/// Keys are stored in platform-specific secure storage, never hardcoded.
class EnvConfig {
  static const _storage = FlutterSecureStorage();

  // Storage keys
  static const _geminiApiKey = 'gemini_api_key';
  static const _supabaseUrl = 'supabase_url';
  static const _supabaseAnonKey = 'supabase_anon_key';
  static const _resendApiKey = 'resend_api_key';

  // Gemini
  static Future<String?> getGeminiApiKey() => _storage.read(key: _geminiApiKey);

  static Future<void> setGeminiApiKey(String value) =>
      _storage.write(key: _geminiApiKey, value: value);

  // Supabase
  static Future<String?> getSupabaseUrl() => _storage.read(key: _supabaseUrl);

  static Future<void> setSupabaseUrl(String value) =>
      _storage.write(key: _supabaseUrl, value: value);

  static Future<String?> getSupabaseAnonKey() =>
      _storage.read(key: _supabaseAnonKey);

  static Future<void> setSupabaseAnonKey(String value) =>
      _storage.write(key: _supabaseAnonKey, value: value);

  // Resend
  static Future<String?> getResendApiKey() => _storage.read(key: _resendApiKey);

  static Future<void> setResendApiKey(String value) =>
      _storage.write(key: _resendApiKey, value: value);

  /// Returns true if all required keys for online features are set.
  static Future<bool> hasRequiredKeys() async {
    final gemini = await getGeminiApiKey();
    return gemini != null && gemini.isNotEmpty;
  }

  /// Clears all stored keys.
  static Future<void> clearAll() => _storage.deleteAll();
}
