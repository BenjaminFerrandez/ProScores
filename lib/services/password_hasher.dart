import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Salted SHA-256 password hashing.
///
/// NOTE: For a real product you'd use a slow, memory-hard hash (bcrypt /
/// scrypt / argon2). SHA-256 is used here to stay dependency-light for a
/// student project; it is still far better than storing clear passwords.
class PasswordHasher {
  static final _random = Random.secure();

  /// A fresh random salt, base64url-encoded.
  static String generateSalt([int length = 16]) {
    final bytes = List<int>.generate(length, (_) => _random.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  static bool verify(String password, String salt, String expectedHash) =>
      hash(password, salt) == expectedHash;
}

/// Generates short, human-friendly affiliate codes (no ambiguous chars).
class AffiliateCode {
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final _random = Random.secure();

  static String generate([int length = 6]) => List.generate(
        length,
        (_) => _chars[_random.nextInt(_chars.length)],
      ).join();
}
