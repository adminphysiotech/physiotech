import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/validators.dart';
import '../../domain/models/auth_models.dart';
import '../controllers/sign_up_controller.dart';
import '../providers/auth_providers.dart';
import '../widgets/plan_option_card.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  late final TextEditingController _orgNameController;
  late final TextEditingController _legalNameController;
  late final TextEditingController _countryController;
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;
  late final TextEditingController _tenantEmailController;
  late final TextEditingController _tenantPhoneController;
  late final TextEditingController _websiteController;
  late final TextEditingController _taxNumberController;

  late final TextEditingController _adminFirstNameController;
  late final TextEditingController _adminLastNameController;
  late final TextEditingController _adminEmailController;
  late final TextEditingController _adminPhoneController;
  late final TextEditingController _adminPasswordController;
  late final TextEditingController _adminPasswordConfirmController;
  late final TextEditingController _adminJobTitleController;

  late final TextEditingController _emailCodeController;
  late final TextEditingController _smsCodeController;
  late final TextEditingController _totpCodeController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(signUpControllerProvider);

    _orgNameController = TextEditingController(text: state.tenant.organizationName)
      ..addListener(() =>
          ref.read(signUpControllerProvider.notifier).updateTenant(organizationName: _orgNameController.text));
    _legalNameController = TextEditingController(text: state.tenant.legalName)
      ..addListener(() =>
          ref.read(signUpControllerProvider.notifier).updateTenant(legalName: _legalNameController.text));
    _countryController = TextEditingController(text: state.tenant.country)
      ..addListener(() =>
          ref.read(signUpControllerProvider.notifier).updateTenant(country: _countryController.text));
    _cityController = TextEditingController(text: state.tenant.city)
      ..addListener(() =>
          ref.read(signUpControllerProvider.notifier).updateTenant(city: _cityController.text));
    _addressController = TextEditingController(text: state.tenant.addressLine)
      ..addListener(() =>
          ref.read(signUpControllerProvider.notifier).updateTenant(addressLine: _addressController.text));
    _tenantEmailController = TextEditingController(text: state.tenant.contactEmail)
      ..addListener(() =>
          ref.read(signUpControllerProvider.notifier).updateTenant(contactEmail: _tenantEmailController.text));
    _tenantPhoneController = TextEditingController(text: state.tenant.contactPhone)
      ..addListener(() =>
          ref.read(signUpControllerProvider.notifier).updateTenant(contactPhone: _tenantPhoneController.text));
    _websiteController = TextEditingController(text: state.tenant.website ?? '')
      ..addListener(() =>
          ref.read(signUpControllerProvider.notifier).updateTenant(website: _websiteController.text));
    _taxNumberController = TextEditingController(text: state.tenant.taxNumber ?? '')
      ..addListener(() =>
          ref.read(signUpControllerProvider.notifier).updateTenant(taxNumber: _taxNumberController.text));

    _adminFirstNameController = TextEditingController(text: state.admin.firstName)
      ..addListener(() =>
          ref.read(signUpControllerProvider.notifier).updateAdmin(firstName: _adminFirstNameController.text));
    _adminLastNameController = TextEditingController(text: state.admin.lastName)
      ..addListener(() =>
          ref.read(signUpControllerProvider.notifier).updateAdmin(lastName: _adminLastNameController.text));
    _adminEmailController = TextEditingController(text: state.admin.email)
      ..addListener(() =>
          ref.read(signUpControllerProvider.notifier).updateAdmin(email: _adminEmailController.text));
    _adminPhoneController = TextEditingController(text: state.admin.phone)
      ..addListener(() =>
          ref.read(signUpControllerProvider.notifier).updateAdmin(phone: _adminPhoneController.text));
    _adminPasswordController = TextEditingController(text: state.admin.password)
      ..addListener(() =>
          ref.read(signUpControllerProvider.notifier).updateAdmin(password: _adminPasswordController.text));
    _adminPasswordConfirmController =
        TextEditingController(text: state.admin.confirmPassword)
          ..addListener(() => ref
              .read(signUpControllerProvider.notifier)
              .updateAdmin(confirmPassword: _adminPasswordConfirmController.text));
    _adminJobTitleController = TextEditingController(text: state.admin.jobTitle ?? '')
      ..addListener(() =>
          ref.read(signUpControllerProvider.notifier).updateAdmin(jobTitle: _adminJobTitleController.text));

    _emailCodeController = TextEditingController();
    _smsCodeController = TextEditingController();
    _totpCodeController = TextEditingController();
  }

  SignUpController get _controller => ref.read(signUpControllerProvider.notifier);

  @override
  void dispose() {
    _orgNameController.dispose();
    _legalNameController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _tenantEmailController.dispose();
    _tenantPhoneController.dispose();
    _websiteController.dispose();
    _taxNumberController.dispose();
    _adminFirstNameController.dispose();
    _adminLastNameController.dispose();
    _adminEmailController.dispose();
    _adminPhoneController.dispose();
    _adminPasswordController.dispose();
    _adminPasswordConfirmController.dispose();
    _adminJobTitleController.dispose();
    _emailCodeController.dispose();
    _smsCodeController.dispose();
    _totpCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SignUpState>(signUpControllerProvider, (previous, next) {
      if (!mounted) return;
      if (next.verificationResult != null &&
          previous?.verificationResult != next.verificationResult) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification complete. Credentials issued.')),
        );
        _emailCodeController.clear();
        _smsCodeController.clear();
        _totpCodeController.clear();
      } else if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    final state = ref.watch(signUpControllerProvider);
    final plans = ref.watch(subscriptionPlansProvider);
    final currency = NumberFormat.currency(locale: 'en_US', symbol: 'TRY');

    return Scaffold(
      appBar: AppBar(title: const Text('Create organization account')),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: state.currentStep,
        onStepContinue: state.isSubmitting
            ? null
            : () {
                if (state.currentStep == 2) {
                  _controller.initiateSignup();
                } else {
                  _controller.nextStep();
                }
              },
        onStepCancel: state.isSubmitting ? null : _controller.previousStep,
        controlsBuilder: (context, details) {
          final isLastStep = state.currentStep == 2;
          return Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: state.isSubmitting ? null : details.onStepContinue,
                  child: state.isSubmitting && isLastStep
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isLastStep ? 'Start verification' : 'Continue'),
                ),
              ),
              if (state.currentStep > 0) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: state.isSubmitting ? null : details.onStepCancel,
                    child: const Text('Back'),
                  ),
                ),
              ],
            ],
          );
        },
        steps: [
          Step(
            title: const Text('Organization details'),
            subtitle: const Text('Basic profile and contact information'),
            isActive: state.currentStep >= 0,
            state: state.currentStep > 0 ? StepState.complete : StepState.indexed,
            content: _buildOrganizationForm(state),
          ),
          Step(
            title: const Text('Administrator account'),
            subtitle: const Text('Superuser contact and credentials'),
            isActive: state.currentStep >= 1,
            state: state.currentStep > 1 ? StepState.complete : StepState.indexed,
            content: _buildAdminForm(state),
          ),
          Step(
            title: const Text('Plan and billing'),
            subtitle: const Text('Choose subscription tier and billing cycle'),
            isActive: state.currentStep >= 2,
            state: state.currentStep == 2 && state.isPlanStepValid
                ? StepState.complete
                : StepState.indexed,
            content: _buildPlanSelector(state, plans, currency),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizationForm(SignUpState state) {
    return Column(
      children: [
        TextField(
          controller: _orgNameController,
          decoration: InputDecoration(
            labelText: 'Organization name',
            errorText: state.showErrors
                ? validateRequired(_orgNameController.text, label: 'Organization name')
                : null,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _legalNameController,
          decoration: const InputDecoration(
            labelText: 'Legal name (optional)',
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _countryController,
                decoration: InputDecoration(
                  labelText: 'Country',
                  errorText: state.showErrors
                      ? validateRequired(_countryController.text, label: 'Country')
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City',
                  errorText: state.showErrors
                      ? validateRequired(_cityController.text, label: 'City')
                      : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Address',
            errorText: state.showErrors
                ? validateRequired(_addressController.text, label: 'Address')
                : null,
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _tenantEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Contact email',
            errorText: state.showErrors
                ? validateEmail(_tenantEmailController.text)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _tenantPhoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Contact phone',
            errorText: state.showErrors
                ? validatePhoneNumber(_tenantPhoneController.text)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _websiteController,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Website (optional)',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _taxNumberController,
          decoration: const InputDecoration(
            labelText: 'Tax number (optional)',
          ),
        ),
      ],
    );
  }

  Widget _buildAdminForm(SignUpState state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _adminFirstNameController,
                decoration: InputDecoration(
                  labelText: 'First name',
                  errorText: state.showErrors
                      ? validateRequired(_adminFirstNameController.text, label: 'First name')
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _adminLastNameController,
                decoration: InputDecoration(
                  labelText: 'Last name',
                  errorText: state.showErrors
                      ? validateRequired(_adminLastNameController.text, label: 'Last name')
                      : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _adminJobTitleController,
          decoration: const InputDecoration(labelText: 'Job title (optional)'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _adminEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Administrator email',
            errorText: state.showErrors
                ? validateEmail(_adminEmailController.text)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _adminPhoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Mobile phone',
            errorText: state.showErrors
                ? validatePhoneNumber(_adminPhoneController.text)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _adminPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Temporary password',
            errorText: state.showErrors
                ? validatePassword(_adminPasswordController.text)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _adminPasswordConfirmController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Confirm password',
            errorText: state.showErrors
                ? validatePasswordConfirmation(
                    _adminPasswordController.text,
                    _adminPasswordConfirmController.text,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanSelector(
    SignUpState state,
    List<SubscriptionPlan> plans,
    NumberFormat currency,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<BillingPeriod>(
          segments: const [
            ButtonSegment(
              value: BillingPeriod.monthly,
              label: Text('Monthly'),
            ),
            ButtonSegment(
              value: BillingPeriod.annual,
              label: Text('Annual (save 10%)'),
            ),
          ],
          selected: {state.billingPeriod},
          showSelectedIcon: false,
          onSelectionChanged: (selection) =>
              _controller.setBillingPeriod(selection.first),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: plans
              .map(
                (plan) => SizedBox(
                  width: MediaQuery.of(context).size.width > 720
                      ? 320
                      : double.infinity,
                  child: PlanOptionCard(
                    plan: plan,
                    billingPeriod: state.billingPeriod,
                    currency: currency,
                    selected: state.selectedPlan?.code == plan.code,
                    onTap: () => _controller.selectPlan(plan),
                  ),
                ),
              )
              .toList(),
        ),
        if (state.showErrors && state.selectedPlan == null) ...[
          const SizedBox(height: 12),
          Text(
            'Please choose a subscription plan to continue.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 24),
        if (state.initiated != null) _buildVerificationInputs(state),
        if (state.verificationResult != null) _buildCredentialsSummary(state),
      ],
    );
  }

  Widget _buildVerificationInputs(SignUpState state) {
    final initiated = state.initiated!;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verification required',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'We sent an email code, an SMS code, and generated an authenticator secret.',
            ),
            const SizedBox(height: 8),
            SelectableText('TOTP secret: '),
            const SizedBox(height: 4),
            SelectableText('TOTP URI: '),
            const SizedBox(height: 16),
            TextField(
              controller: _emailCodeController,
              decoration: const InputDecoration(labelText: 'Email code'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _smsCodeController,
              decoration: const InputDecoration(labelText: 'SMS code'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _totpCodeController,
              decoration: const InputDecoration(labelText: 'Authenticator code'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: state.isVerifying
                  ? null
                  : () => _controller.verifySignup(
                        emailCode: _emailCodeController.text,
                        smsCode: _smsCodeController.text,
                        totpCode: _totpCodeController.text,
                      ),
              child: state.isVerifying
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Complete verification'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialsSummary(SignUpState state) {
    final result = state.verificationResult!;
    return Card(
      margin: const EdgeInsets.only(top: 16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tenant is provisioned',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SelectableText('Workspace email: '),
            SelectableText('Workspace temp password: '),
            const SizedBox(height: 8),
            SelectableText('Database: '),
            SelectableText('DB user: '),
            SelectableText('DB password: '),
          ],
        ),
      ),
    );
  }
}
