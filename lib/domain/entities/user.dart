import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String? email;
  final String? name;
  final String? avatarUrl;
  final String provider; // 'apple', 'github', 'email'

  const User({
    required this.id,
    this.email,
    this.name,
    this.avatarUrl,
    required this.provider,
  });

  @override
  List<Object?> get props => [id, email, name, avatarUrl, provider];
}
