import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/auth_repository.dart';
import '../models/user.dart';

/// Holds the current session (null = logged out). Initializes the local store
/// on first build.
class AuthController extends AsyncNotifier<User?> {
  AuthRepository? _repo;

  @override
  Future<User?> build() async {
    final prefs = await SharedPreferences.getInstance();
    _repo = AuthRepository(prefs);
    return _repo!.currentUser();
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? referralCode,
  }) async {
    final user = await _repo!
        .signUp(email: email, password: password, referralCode: referralCode);
    state = AsyncData(user);
  }

  Future<void> signIn(
      {required String email, required String password}) async {
    final user = await _repo!.signIn(email: email, password: password);
    state = AsyncData(user);
  }

  Future<void> signOut() async {
    await _repo!.signOut();
    state = const AsyncData(null);
  }

  /// Accounts referred by the logged-in user (for the affiliate dashboard).
  List<User> myReferrals() {
    final me = state.value;
    if (me == null || _repo == null) return const [];
    return _repo!.referredBy(me.affiliateCode);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, User?>(AuthController.new);
