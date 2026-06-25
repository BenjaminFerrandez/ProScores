import 'package:flutter_test/flutter_test.dart';
import 'package:proscores/services/password_hasher.dart';

void main() {
  test('hash is deterministic for the same salt, verifies correctly', () {
    final salt = PasswordHasher.generateSalt();
    final h = PasswordHasher.hash('s3cret!', salt);
    expect(PasswordHasher.hash('s3cret!', salt), h);
    expect(PasswordHasher.verify('s3cret!', salt, h), isTrue);
    expect(PasswordHasher.verify('wrong', salt, h), isFalse);
  });

  test('different salts produce different hashes', () {
    final h1 = PasswordHasher.hash('same', PasswordHasher.generateSalt());
    final h2 = PasswordHasher.hash('same', PasswordHasher.generateSalt());
    expect(h1, isNot(h2));
  });

  test('affiliate codes are non-empty and reasonably random', () {
    final codes = {for (var i = 0; i < 50; i++) AffiliateCode.generate()};
    expect(codes.every((c) => c.length == 6), isTrue);
    expect(codes.length, greaterThan(45)); // very few collisions expected
  });
}
