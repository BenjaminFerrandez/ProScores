/// A locally-stored user account. Passwords are never stored in clear: only
/// a salted SHA-256 hash is kept (see PasswordHasher).
class User {
  final String id;
  final String email;
  final String passwordHash;
  final String salt;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.salt,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'passwordHash': passwordHash,
        'salt': salt,
        'createdAt': createdAt.toIso8601String(),
      };

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] as String,
        email: j['email'] as String,
        passwordHash: j['passwordHash'] as String,
        salt: j['salt'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
