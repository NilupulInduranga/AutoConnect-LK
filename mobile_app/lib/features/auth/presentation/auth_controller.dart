import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/auth/data/auth_repository.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AsyncValue.data(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authRepository.signIn(email: email, password: password));
  }

  Future<void> signUp(String email, String password, String fullName, String role) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authRepository.signUp(
          email: email,
          password: password,
          fullName: fullName,
          role: role,
        ));
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authRepository.resetPassword(email));
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authRepository.signOut());
  }
}
