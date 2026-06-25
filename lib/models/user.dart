/// A locally-stored user account. Passwords are never stored in clear: only
/// a salted SHA-256 hash is kept (see PasswordHasher).
class User {
  final String id;
  final String email;
  final String passwordHash;
  final String salt;

  /// This user's own affiliate code, shared to refer others.
  final String affiliateCode;

  /// The affiliate code this user signed up with, if any.
  final String? referredByCode;

  /// Virtual commission balance (simulated euros).
  final double commissionBalance;

  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.salt,
    required this.affiliateCode,
    this.referredByCode,
    this.commissionBalance = 0,
    required this.createdAt,
  });

  User copyWith({double? commissionBalance}) => User(
        id: id,
        email: email,
        passwordHash: passwordHash,
        salt: salt,
        affiliateCode: affiliateCode,
        referredByCode: referredByCode,
        commissionBalance: commissionBalance ?? this.commissionBalance,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'passwordHash': passwordHash,
        'salt': salt,
        'affiliateCode': affiliateCode,
        'referredByCode': referredByCode,
        'commissionBalance': commissionBalance,
        'createdAt': createdAt.toIso8601String(),
      };

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] as String,
        email: j['email'] as String,
        passwordHash: j['passwordHash'] as String,
        salt: j['salt'] as String,
        affiliateCode: j['affiliateCode'] as String,
        referredByCode: j['referredByCode'] as String?,
        commissionBalance: (j['commissionBalance'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
