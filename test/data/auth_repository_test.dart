import 'package:flutter_test/flutter_test.dart';
import 'package:proscores/data/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AuthRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = AuthRepository(await SharedPreferences.getInstance());
  });

  test('signUp creates a user and logs it in', () async {
    final u = await repo.signUp(email: 'A@Test.com ', password: 'secret1');
    expect(u.email, 'a@test.com'); // normalized
    expect(repo.currentUser()!.id, u.id);
  });

  test('rejects duplicate email and weak password', () async {
    await repo.signUp(email: 'a@test.com', password: 'secret1');
    expect(() => repo.signUp(email: 'a@test.com', password: 'secret1'),
        throwsA(isA<AuthException>()));
    expect(() => repo.signUp(email: 'b@test.com', password: '123'),
        throwsA(isA<AuthException>()));
  });

  test('signIn verifies the password', () async {
    await repo.signUp(email: 'a@test.com', password: 'secret1');
    await repo.signOut();
    expect(repo.currentUser(), isNull);

    expect(() => repo.signIn(email: 'a@test.com', password: 'nope'),
        throwsA(isA<AuthException>()));
    final u = await repo.signIn(email: 'a@test.com', password: 'secret1');
    expect(u.email, 'a@test.com');
    expect(repo.currentUser()!.id, u.id);
  });
}
