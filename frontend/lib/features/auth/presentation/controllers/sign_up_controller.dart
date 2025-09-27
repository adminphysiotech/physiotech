import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/validators.dart';
import '../../data/auth_repository.dart';
import '../../domain/models/auth_models.dart';

class SignUpState extends Equatable {
  const SignUpState({
    required this.tenant,
    required this.admin,
    this.selectedPlan,
    this.billingPeriod = BillingPeriod.monthly,
    this.currentStep = 0,
    this.showErrors = false,
    this.isSubmitting = false,
    this.isVerifying = false,
    this.errorMessage,
    this.initiated,
    this.verificationResult,
  });

  final TenantProfile tenant;
  final AdminProfile admin;
  final SubscriptionPlan? selectedPlan;
  final BillingPeriod billingPeriod;
  final int currentStep;
  final bool showErrors;
  final bool isSubmitting;
  final bool isVerifying;
  final String? errorMessage;
  final SignupInitiated? initiated;
  final SignupVerificationResult? verificationResult;

  bool get isTenantStepValid =>
      validateRequired(tenant.organizationName, label: 'Organization name') == null &&
      validateRequired(tenant.country, label: 'Country') == null &&
      validateRequired(tenant.city, label: 'City') == null &&
      validateRequired(tenant.addressLine, label: 'Address') == null &&
      validateEmail(tenant.contactEmail) == null &&
      validatePhoneNumber(tenant.contactPhone) == null;

  bool get isAdminStepValid =>
      validateRequired(admin.firstName, label: 'First name') == null &&
      validateRequired(admin.lastName, label: 'Last name') == null &&
      validateEmail(admin.email) == null &&
      validatePhoneNumber(admin.phone) == null &&
      validatePassword(admin.password) == null &&
      validatePasswordConfirmation(admin.password, admin.confirmPassword) == null;

  bool get isPlanStepValid => selectedPlan != null;

  bool get canSubmit => isTenantStepValid && isAdminStepValid && isPlanStepValid && !isSubmitting;

  SignUpState copyWith({
    TenantProfile? tenant,
    AdminProfile? admin,
    SubscriptionPlan? selectedPlan,
    BillingPeriod? billingPeriod,
    int? currentStep,
    bool? showErrors,
    bool? isSubmitting,
    bool? isVerifying,
    String? errorMessage,
    bool clearError = false,
    SignupInitiated? initiated,
    SignupVerificationResult? verificationResult,
  }) {
    return SignUpState(
      tenant: tenant ?? this.tenant,
      admin: admin ?? this.admin,
      selectedPlan: selectedPlan ?? this.selectedPlan,
      billingPeriod: billingPeriod ?? this.billingPeriod,
      currentStep: currentStep ?? this.currentStep,
      showErrors: showErrors ?? this.showErrors,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isVerifying: isVerifying ?? this.isVerifying,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      initiated: initiated ?? this.initiated,
      verificationResult: verificationResult ?? this.verificationResult,
    );
  }

  @override
  List<Object?> get props => [
        tenant,
        admin,
        selectedPlan,
        billingPeriod,
        currentStep,
        showErrors,
        isSubmitting,
        isVerifying,
        errorMessage,
        initiated,
        verificationResult,
      ];
}

class SignUpController extends StateNotifier<SignUpState> {
  SignUpController(
    this._repository, {
    required List<SubscriptionPlan> plans,
  })  : _plans = plans,
        super(
          SignUpState(
            tenant: TenantProfile.empty(),
            admin: AdminProfile.empty(),
          ),
        );

  final IAuthRepository _repository;
  final List<SubscriptionPlan> _plans;

  List<SubscriptionPlan> get plans => _plans;

  void updateTenant({
    String? organizationName,
    String? legalName,
    String? country,
    String? city,
    String? addressLine,
    String? contactEmail,
    String? contactPhone,
    String? website,
    String? taxNumber,
  }) {
    state = state.copyWith(
      tenant: state.tenant.copyWith(
        organizationName: organizationName,
        legalName: legalName,
        country: country,
        city: city,
        addressLine: addressLine,
        contactEmail: contactEmail,
        contactPhone: contactPhone,
        website: website,
        taxNumber: taxNumber,
      ),
      clearError: true,
    );
  }

  void updateAdmin({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? password,
    String? confirmPassword,
    String? jobTitle,
  }) {
    state = state.copyWith(
      admin: state.admin.copyWith(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
        confirmPassword: confirmPassword,
        jobTitle: jobTitle,
      ),
      clearError: true,
    );
  }

  void selectPlan(SubscriptionPlan plan) {
    state = state.copyWith(selectedPlan: plan, clearError: true);
  }

  void setBillingPeriod(BillingPeriod period) {
    state = state.copyWith(billingPeriod: period);
  }

  void nextStep() {
    state = state.copyWith(showErrors: true, clearError: true);
    final step = state.currentStep;
    if ((step == 0 && !state.isTenantStepValid) ||
        (step == 1 && !state.isAdminStepValid)) {
      return;
    }
    if (step < 2) {
      state = state.copyWith(
        currentStep: step + 1,
        showErrors: false,
        clearError: true,
      );
    }
  }

  void previousStep() {
    if (state.currentStep == 0) return;
    state = state.copyWith(
      currentStep: state.currentStep - 1,
      showErrors: false,
      clearError: true,
    );
  }

  Future<void> initiateSignup() async {
    state = state.copyWith(showErrors: true, clearError: true);
    if (!state.canSubmit || state.selectedPlan == null) {
      return;
    }
    state = state.copyWith(isSubmitting: true);
    try {
      final response = await _repository.initiateSignup(
        SignUpRequest(
          tenant: state.tenant,
          admin: state.admin,
          plan: state.selectedPlan!,
          billingPeriod: state.billingPeriod,
        ),
      );
      state = state.copyWith(
        isSubmitting: false,
        initiated: response,
        clearError: true,
      );
    } on AuthException catch (error) {
      state = state.copyWith(isSubmitting: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Signup could not be completed. Please try again.',
      );
    }
  }

  Future<void> verifySignup({
    required String emailCode,
    required String smsCode,
    required String totpCode,
  }) async {
    final init = state.initiated;
    if (init == null) {
      state = state.copyWith(errorMessage: 'Signup session is missing.');
      return;
    }
    state = state.copyWith(isVerifying: true, clearError: true);
    try {
      final response = await _repository.verifySignup(
        verificationId: init.verificationId,
        emailCode: emailCode,
        smsCode: smsCode,
        totpCode: totpCode,
      );
      state = state.copyWith(
        isVerifying: false,
        verificationResult: response,
        clearError: true,
      );
    } on AuthException catch (error) {
      state = state.copyWith(isVerifying: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isVerifying: false,
        errorMessage: 'Verification failed. Please try again.',
      );
    }
  }

  void reset() {
    state = SignUpState(
      tenant: TenantProfile.empty(),
      admin: AdminProfile.empty(),
    );
  }
}
