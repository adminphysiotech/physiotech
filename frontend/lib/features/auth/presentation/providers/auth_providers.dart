import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/auth_repository.dart';
import '../../domain/models/auth_models.dart';
import '../controllers/sign_in_controller.dart';
import '../controllers/sign_up_controller.dart';

final subscriptionPlansProvider =
    Provider<List<SubscriptionPlan>>((_) => SubscriptionPlan.defaultPlans);

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(
    dio,
    loginPath: '/login',
    signupInitPath: '/signup/init',
    signupVerifyPath: '/signup/verify',
  );
});

final signInControllerProvider =
    StateNotifierProvider<SignInController, SignInState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return SignInController(repo);
});

final signUpControllerProvider =
    StateNotifierProvider<SignUpController, SignUpState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final plans = ref.watch(subscriptionPlansProvider);
  return SignUpController(repo, plans: plans);
});
