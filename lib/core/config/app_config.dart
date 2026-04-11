class AppConfig {
  static const String minimaxApiKey = String.fromEnvironment('MINIMAX_API_KEY', defaultValue: '');
  static const String minimaxGroupId = String.fromEnvironment('MINIMAX_GROUP_ID', defaultValue: '');
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
}
