import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../../domain/models/auth_models.dart';
import '../../../../core/utils/validators.dart';

class SignInState extends Equatable {
  const SignInState({
    this.email = '',
    this.password = '',
    this.isLoading = false,
    this.showErrors = false,
    this.errorMessage,
    this.session,
  });

  final String email;
  final String password;
  final bool isLoading;
  final bool showErrors;
  final String? errorMessage;
  final AuthSession? session;

  bool get isValid =>
      validateEmail(email) == null && validatePassword(password) == null;

  bool get canSubmit => isValid && !isLoading;

  SignInState copyWith({
    String? email,
    String? password,
    bool? isLoading,
    bool? showErrors,
    String? errorMessage,
    AuthSession? session,
    bool clearError = false,
  }) {
    return SignInState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      showErrors: showErrors ?? this.showErrors,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      session: session ?? this.session,
    );
  }

  @override
  List<Object?> get props =>
      [email, password, isLoading, showErrors, errorMessage, session];
}

class SignInController extends StateNotifier<SignInState> {
  SignInController(this._repository) : super(const SignInState());

  final IAuthRepository _repository;

  void updateEmail(String email) {
    state = state.copyWith(email: email, clearError: true);
  }

  void updatePassword(String password) {
    state = state.copyWith(password: password, clearError: true);
  }

  Future<void> submit() async {
    state = state.copyWith(showErrors: true, clearError: true);
    if (!state.isValid) {
      return;
    }
    state = state.copyWith(isLoading: true);
    try {
      final session = await _repository.signIn(
        SignInRequest(email: state.email, password: state.password),
      );
      state = state.copyWith(
        isLoading: false,
        session: session,
        clearError: true,
      );
    } on AuthException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unexpected error. Please try again later.',
      );
    }
  }
}
