import 'package:supabase_flutter/supabase_flutter.dart';
//import 'package:fresh_car/pages/home_page.dart';
//import 'package:fresh_car/pages/login.dart';

class SupabaseClient {
  static final client = Supabase.instance.client;

  // Private constructor to prevent instantiation
  SupabaseClient._();

  static SupabaseClient? _instance;

  static SupabaseClient get instance {
    _instance ??= SupabaseClient._();
    return _instance!;
  }
}
