import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/user.dart';
import '../services/password_hasher.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Local, device-only account store backed by SharedPreferences. No backend:
/// all accounts live on the device (fine for a student project / demo).
class AuthRepository {
  AuthRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _usersKey = 'users';
  static const _sessionKey = 'session_user_id';

  List<User> _allUsers() {
    final raw = _prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(User.fromJson).toList();
  }

  Future<void> _saveUsers(List<User> users) async {
    await _prefs.setString(
        _usersKey, jsonEncode(users.map((u) => u.toJson()).toList()));
  }

  String _normalize(String email) => email.trim().toLowerCase();

  User? currentUser() {
    final id = _prefs.getString(_sessionKey);
    if (id == null) return null;
    for (final u in _allUsers()) {
      if (u.id == id) return u;
    }
    return null;
  }

  /// People who signed up with [affiliateCode], newest first.
  List<User> referredBy(String affiliateCode) {
    final code = affiliateCode.toUpperCase();
    final list =
        _allUsers().where((u) => u.referredByCode == code).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  String _uniqueAffiliateCode(List<User> users) {
    final taken = users.map((u) => u.affiliateCode).toSet();
    String code;
    do {
      code = AffiliateCode.generate();
    } while (taken.contains(code));
    return code;
  }

  Future<User> signUp({
    required String email,
    required String password,
    String? referralCode,
  }) async {
    final normalized = _normalize(email);
    if (normalized.isEmpty || !normalized.contains('@')) {
      throw AuthException('Adresse e-mail invalide.');
    }
    if (password.length < 6) {
      throw AuthException('Le mot de passe doit faire au moins 6 caractères.');
    }

    final users = _allUsers();
    if (users.any((u) => u.email == normalized)) {
      throw AuthException('Un compte existe déjà avec cet e-mail.');
    }

    // Apply referral, if a code was provided.
    User? referrer;
    final code = referralCode?.trim().toUpperCase();
    if (code != null && code.isNotEmpty) {
      referrer = users.cast<User?>().firstWhere(
            (u) => u!.affiliateCode == code,
            orElse: () => null,
          );
      if (referrer == null) {
        throw AuthException('Code de parrainage invalide.');
      }
    }

    final salt = PasswordHasher.generateSalt();
    final newUser = User(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      email: normalized,
      passwordHash: PasswordHasher.hash(password, salt),
      salt: salt,
      affiliateCode: _uniqueAffiliateCode(users),
      referredByCode: referrer?.affiliateCode,
      commissionBalance: referrer == null ? 0 : kWelcomeBonus,
      createdAt: DateTime.now(),
    );

    final updated = [...users, newUser];
    if (referrer != null) {
      // Credit the referrer's commission.
      for (var i = 0; i < updated.length; i++) {
        if (updated[i].id == referrer.id) {
          updated[i] = updated[i].copyWith(
              commissionBalance:
                  updated[i].commissionBalance + kReferralCommission);
        }
      }
    }

    await _saveUsers(updated);
    await _prefs.setString(_sessionKey, newUser.id);
    return newUser;
  }

  Future<User> signIn(
      {required String email, required String password}) async {
    final normalized = _normalize(email);
    final user = _allUsers().cast<User?>().firstWhere(
          (u) => u!.email == normalized,
          orElse: () => null,
        );
    if (user == null ||
        !PasswordHasher.verify(password, user.salt, user.passwordHash)) {
      throw AuthException('E-mail ou mot de passe incorrect.');
    }
    await _prefs.setString(_sessionKey, user.id);
    return user;
  }

  Future<void> signOut() async => _prefs.remove(_sessionKey);
}
