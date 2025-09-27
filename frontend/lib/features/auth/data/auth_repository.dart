import 'package:dio/dio.dart';

import '../domain/models/auth_models.dart';

abstract class IAuthRepository {
  Future<AuthSession> signIn(SignInRequest request);
  Future<SignupInitiated> initiateSignup(SignUpRequest request);
  Future<SignupVerificationResult> verifySignup({
    required String verificationId,
    required String emailCode,
    required String smsCode,
    required String totpCode,
  });
}

class AuthRepository implements IAuthRepository {
  AuthRepository(
    this._dio, {
    this.loginPath = '/login',
    this.signupInitPath = '/signup/init',
    this.signupVerifyPath = '/signup/verify',
  });

  final Dio _dio;
  final String loginPath;
  final String signupInitPath;
  final String signupVerifyPath;

  @override
  Future<AuthSession> signIn(SignInRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        loginPath,
        data: request.toJson(),
      );
      final data = _coerceToJsonMap(response.data);
      return AuthSession.fromJson(data);
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }

  @override
  Future<SignupInitiated> initiateSignup(SignUpRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        signupInitPath,
        data: request.toJson(),
      );
      final data = _coerceToJsonMap(response.data);
      return SignupInitiated.fromJson(data);
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }

  @override
  Future<SignupVerificationResult> verifySignup({
    required String verificationId,
    required String emailCode,
    required String smsCode,
    required String totpCode,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        signupVerifyPath,
        data: {
          'verification_id': verificationId,
          'email_code': emailCode,
          'sms_code': smsCode,
          'totp_code': totpCode,
        },
      );
      final data = _coerceToJsonMap(response.data);
      return SignupVerificationResult.fromJson(data);
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }

  Map<String, dynamic> _coerceToJsonMap(dynamic data) {
    if (data == null) {
      throw const AuthException(message: 'Response body was empty');
    }
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    throw const AuthException(message: 'Unexpected response payload');
  }
}

class AuthException implements Exception {
  const AuthException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  factory AuthException.fromDio(DioException error) {
    String friendlyMessage = 'Operation failed. Please try again later.';
    int? status;

    if (error.response != null) {
      status = error.response!.statusCode;
      final payload = error.response!.data;
      if (payload is Map) {
        final map = payload.map((key, value) => MapEntry(key.toString(), value));
        friendlyMessage = map['detail']?.toString() ??
            map['message']?.toString() ??
            friendlyMessage;
      } else if (payload is String && payload.isNotEmpty) {
        friendlyMessage = payload;
      }
    } else if (error.message != null && error.message!.isNotEmpty) {
      friendlyMessage = error.message!;
    }

    return AuthException(message: friendlyMessage, statusCode: status);
  }

  @override
  String toString() => 'AuthException($statusCode): $message';
}
