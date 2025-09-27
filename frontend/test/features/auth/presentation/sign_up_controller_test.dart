import 'package:flutter_test/flutter_test.dart';

import 'package:physiotech_frontend/features/auth/data/auth_repository.dart';
import 'package:physiotech_frontend/features/auth/domain/models/auth_models.dart';
import 'package:physiotech_frontend/features/auth/presentation/controllers/sign_up_controller.dart';

class FakeAuthRepository implements IAuthRepository {
  @override
  Future<AuthSession> signIn(SignInRequest request) async {
    throw UnimplementedError();
  }

  @override
  Future<SignupInitiated> initiateSignup(SignUpRequest request) async {
    return SignupInitiated(
      organizationId: 42,
      verificationId: 'ver-123',
      totpSecret: 'secret',
      totpUri: 'otpauth://totp/test',
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    );
  }

  @override
  Future<SignupVerificationResult> verifySignup({
    required String verificationId,
    required String emailCode,
    required String smsCode,
    required String totpCode,
  }) async {
    return const SignupVerificationResult(
      organizationId: 42,
      workspaceEmail: 'john.doe@physiotech.app',
      workspaceTemporaryPassword: 'TempPass123',
      databaseName: 'tenant_clinic',
      databaseUser: 'user_clinic',
      databasePassword: 'dbPassword',
    );
  }
}

void main() {
  group('SignUpController', () {
    late SignUpController controller;
    final plans = SubscriptionPlan.defaultPlans;

    setUp(() {
      controller = SignUpController(
        FakeAuthRepository(),
        plans: plans,
      );
    });

    test('cannot submit when step data is incomplete', () async {
      await controller.initiateSignup();
      expect(controller.state.initiated, isNull);
      expect(controller.state.errorMessage, isNull);
    });

    test('successful flow returns verification data', () async {
      controller
        ..updateTenant(
          organizationName: 'Physiotech Center',
          legalName: 'Physiotech Center LLC',
          country: 'Turkey',
          city: 'Istanbul',
          addressLine: 'Bagdat Street 10',
          contactEmail: 'info@physiotech.com',
          contactPhone: '+90 555 000 00 00',
        )
        ..updateAdmin(
          firstName: 'John',
          lastName: 'Doe',
          email: 'owner@physiotech.com',
          phone: '+90 533 111 11 11',
          password: 'StrongPass123',
          confirmPassword: 'StrongPass123',
        )
        ..selectPlan(plans.first);

      await controller.initiateSignup();
      expect(controller.state.initiated, isNotNull);

      await controller.verifySignup(
        emailCode: '123456',
        smsCode: '654321',
        totpCode: '111111',
      );

      expect(controller.state.verificationResult, isNotNull);
      expect(controller.state.errorMessage, isNull);
    });
  });
}
