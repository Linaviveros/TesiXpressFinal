import 'package:supabase_flutter/supabase_flutter.dart';

class Supa {
  static const String supabaseUrl = 'https://qzkpyauczwmiltmxrwrr.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF6a3B5YXVjendtaWx0bXhyd3JyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxMTU2MDIsImV4cCI6MjA3NDY5MTYwMn0.ez-ezhb47OoteSCuYKGrRAR8ApCyyzrGANDvw7r0kGM';

  static late SupabaseClient client;

  static Future<void> init() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    client = Supabase.instance.client;
  }
}
