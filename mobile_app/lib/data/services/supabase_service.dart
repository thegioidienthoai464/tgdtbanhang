import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://gzcpwwcoaycxqbgrjvzn.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_kiCUjPVYWcQP7oyrsg3K7g_xySklDFY';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
