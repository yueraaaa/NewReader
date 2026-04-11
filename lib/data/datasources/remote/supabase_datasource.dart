import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDatasource {
  final SupabaseClient _client;

  SupabaseDatasource(this._client);

  // Auth methods
  Future<User?> getCurrentUser() async => _client.auth.currentUser;

  Stream<User?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((event) => event.session?.user);

  Future<User> signInWithApple() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'realreader://login-callback',
    );
    // OAuth sign-in is asynchronous - the user is returned via auth state change
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Apple sign in failed');
    }
    return user;
  }

  Future<User> signInWithGithub() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.github,
      redirectTo: 'realreader://login-callback',
    );
    // OAuth sign-in is asynchronous - the user is returned via auth state change
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('GitHub sign in failed');
    }
    return user;
  }

  Future<User> signInWithEmail(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.user!;
  }

  Future<User> signUpWithEmail(String email, String password) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    if (response.user == null) {
      throw Exception('Sign up failed');
    }
    return response.user!;
  }

  Future<void> signOut() async => await _client.auth.signOut();

  // Remote CRUD - these use the Supabase REST API or PostgREST
  Future<List<Map<String, dynamic>>> getFeeds(String? since) async {
    final query = _client.from('feeds').select();
    if (since != null) {
      query.gte('updated_at', since);
    }
    return await query;
  }

  Future<void> upsertFeed(Map<String, dynamic> feed) async {
    await _client.from('feeds').upsert(feed);
  }

  Future<List<Map<String, dynamic>>> getArticles(String? since) async {
    final query = _client.from('articles').select();
    if (since != null) {
      query.gte('updated_at', since);
    }
    return await query;
  }

  Future<void> upsertArticle(Map<String, dynamic> article) async {
    await _client.from('articles').upsert(article);
  }

  Future<List<Map<String, dynamic>>> getCategories(String? since) async {
    final query = _client.from('categories').select();
    if (since != null) {
      query.gte('updated_at', since);
    }
    return await query;
  }

  Future<void> upsertCategory(Map<String, dynamic> category) async {
    await _client.from('categories').upsert(category);
  }

  Future<Map<String, dynamic>?> getSetting(String key) async {
    final result = await _client
        .from('settings')
        .select()
        .eq('key', key)
        .maybeSingle();
    return result;
  }

  Future<void> setSetting(String key, String value) async {
    await _client.from('settings').upsert({'key': key, 'value': value});
  }
}
