import '../../domain/entities/user.dart';

abstract class AuthRepository {
  Future<User?> getCurrentUser();
  Stream<User?> get authStateChanges;
  Future<User> signInWithApple();
  Future<User> signInWithGithub();
  Future<User> signInWithEmail(String email, String password);
  Future<User> signUpWithEmail(String email, String password);
  Future<void> signOut();
}
