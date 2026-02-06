import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages API keys and environment configuration.
/// Reads from .env file first, falls back to secure storage.
class EnvConfig {
  static const _storage = FlutterSecureStorage();

  // .env key -> secure storage key mappings
  static const _envToStorageKeys = {
    'GEMINI_API_KEY': 'gemini_api_key',
    'SUPABASE_URL': 'supabase_url',
    'SUPABASE_ANON_KEY': 'supabase_anon_key',
    'RESEND_API_KEY': 'resend_api_key',
  };

  /// Load .env file and seed any keys into secure storage.
  static Future<void> init() async {
    try {
      await dotenv.load();
    } catch (_) {
      // .env file may not exist; that's fine.
      return;
    }
    // Seed keys from .env into secure storage if present.
    for (final entry in _envToStorageKeys.entries) {
      final value = dotenv.maybeGet(entry.key);
      if (value != null && value.isNotEmpty) {
        try {
          await _storage.write(key: entry.value, value: value);
        } catch (_) {
          // Secure storage may not be available (e.g. missing entitlements).
        }
      }
    }
  }

  /// Read a key, trying secure storage first then falling back to .env.
  static Future<String?> _get(String storageKey, String envKey) async {
    try {
      final value = await _storage.read(key: storageKey);
      if (value != null && value.isNotEmpty) return value;
    } catch (_) {
      // Secure storage not available.
    }
    return dotenv.maybeGet(envKey);
  }

  // Gemini
  static Future<String?> getGeminiApiKey() =>
      _get('gemini_api_key', 'GEMINI_API_KEY');

  static Future<void> setGeminiApiKey(String value) =>
      _storage.write(key: 'gemini_api_key', value: value);

  // Supabase
  static Future<String?> getSupabaseUrl() =>
      _get('supabase_url', 'SUPABASE_URL');

  static Future<void> setSupabaseUrl(String value) =>
      _storage.write(key: 'supabase_url', value: value);

  static Future<String?> getSupabaseAnonKey() =>
      _get('supabase_anon_key', 'SUPABASE_ANON_KEY');

  static Future<void> setSupabaseAnonKey(String value) =>
      _storage.write(key: 'supabase_anon_key', value: value);

  // Resend
  static Future<String?> getResendApiKey() =>
      _get('resend_api_key', 'RESEND_API_KEY');

  static Future<void> setResendApiKey(String value) =>
      _storage.write(key: 'resend_api_key', value: value);

  /// Returns true if all required keys for online features are set.
  static Future<bool> hasRequiredKeys() async {
    final gemini = await getGeminiApiKey();
    return gemini != null && gemini.isNotEmpty;
  }

  /// Clears all stored keys.
  static Future<void> clearAll() => _storage.deleteAll();
}
