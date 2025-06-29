// models/user.dart
class User {
  final String id;
  final String name;
  final String email;
  final String provider;
  final String role;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.provider,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      provider: json['provider'],
      role: json['role'],
    );
  }
}
