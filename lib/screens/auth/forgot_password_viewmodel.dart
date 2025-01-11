import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chromaniac/services/auth_service.dart';

enum ForgotPasswordStatus { initial, loading, success, error }

class ForgotPasswordState {
  final ForgotPasswordStatus status;
  final String? errorMessage;

  const ForgotPasswordState({
    this.status = ForgotPasswordStatus.initial,
    this.errorMessage,
  });

  ForgotPasswordState copyWith({
    ForgotPasswordStatus? status,
    String? errorMessage,
  }) {
    return ForgotPasswordState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ForgotPasswordViewModel extends StateNotifier<ForgotPasswordState> {
  final AuthService _authService;

  ForgotPasswordViewModel(this._authService)
      : super(const ForgotPasswordState());

  Future<void> resetPassword(String email) async {
    state = state.copyWith(status: ForgotPasswordStatus.loading);

    try {
      await _authService.resetPassword(email);
      state = state.copyWith(status: ForgotPasswordStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: ForgotPasswordStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }
}

final forgotPasswordViewModelProvider =
    StateNotifierProvider<ForgotPasswordViewModel, ForgotPasswordState>((ref) {
  return ForgotPasswordViewModel(AuthService());
});
