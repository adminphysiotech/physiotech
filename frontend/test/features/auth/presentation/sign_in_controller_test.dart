import 'package:flutter_test/flutter_test.dart';

import 'package:physiotech_frontend/features/auth/data/auth_repository.dart';
import 'package:physiotech_frontend/features/auth/domain/models/auth_models.dart';
import 'package:physiotech_frontend/features/auth/presentation/controllers/sign_in_controller.dart';

class FakeAuthRepository implements IAuthRepository {
  @override
  Future<AuthSession> signIn(SignInRequest request) async {
    return AuthSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      subject: request.email,
      roles: const ['superuser'],
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  @override
  Future<SignupInitiated> initiateSignup(SignUpRequest request) async {
    throw UnimplementedError();
  }

  @override
  Future<SignupVerificationResult> verifySignup({
    required String verificationId,
    required String emailCode,
    required String smsCode,
    required String totpCode,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  group('SignInController', () {
    late SignInController controller;

    setUp(() {
      controller = SignInController(FakeAuthRepository());
    });

    test('state is invalid when empty', () {
      expect(controller.state.isValid, isFalse);
    });

    test('successful submit stores session', () async {
      controller.updateEmail('admin@clinic.com');
      controller.updatePassword('Password123');
      await controller.submit();
      expect(controller.state.session, isNotNull);
      expect(controller.state.errorMessage, isNull);
      expect(controller.state.isLoading, isFalse);
    });
  });
}
