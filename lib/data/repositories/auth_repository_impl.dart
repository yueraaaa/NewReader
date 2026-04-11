import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/supabase_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseDatasource _datasource;

  AuthRepositoryImpl(this._datasource);

  User _mapToUser(supabase.User user) {
    final provider = user.appMetadata.containsKey('provider')
        ? user.appMetadata['provider'] as String
        : 'email';
    return User(
      id: user.id,
      email: user.email,
      name: user.userMetadata?['name'] as String?,
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
      provider: provider,
    );
  }

  @override
  Future<User?> getCurrentUser() async {
    final user = await _datasource.getCurrentUser();
    return user != null ? _mapToUser(user) : null;
  }

  @override
  Stream<User?> get authStateChanges =>
      _datasource.authStateChanges.map((user) => user != null ? _mapToUser(user) : null);

  @override
  Future<User> signInWithApple() async {
    final user = await _datasource.signInWithApple();
    return _mapToUser(user);
  }

  @override
  Future<User> signInWithGithub() async {
    final user = await _datasource.signInWithGithub();
    return _mapToUser(user);
  }

  @override
  Future<User> signInWithEmail(String email, String password) async {
    final user = await _datasource.signInWithEmail(email, password);
    return _mapToUser(user);
  }

  @override
  Future<User> signUpWithEmail(String email, String password) async {
    final user = await _datasource.signUpWithEmail(email, password);
    return _mapToUser(user);
  }

  @override
  Future<void> signOut() async => await _datasource.signOut();
}
