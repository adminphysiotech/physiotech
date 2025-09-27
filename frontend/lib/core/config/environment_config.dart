class EnvironmentConfig {
  const EnvironmentConfig._();

  static const String authServiceBaseUrl = String.fromEnvironment(
    'AUTH_SERVICE_BASE_URL',
    defaultValue: 'http://127.0.0.1:8080/api/v1/auth',
  );
}
