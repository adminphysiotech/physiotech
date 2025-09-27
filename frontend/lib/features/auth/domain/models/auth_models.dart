import 'package:equatable/equatable.dart';

enum BillingPeriod { monthly, annual }

extension BillingPeriodLabel on BillingPeriod {
  String get label => switch (this) {
        BillingPeriod.monthly => 'Monthly',
        BillingPeriod.annual => 'Annual',
      };

  String get apiValue => name;
}

class SubscriptionPlan extends Equatable {
  const SubscriptionPlan({
    required this.code,
    required this.title,
    required this.description,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.features,
  });

  final String code;
  final String title;
  final String description;
  final double monthlyPrice;
  final double annualPrice;
  final List<String> features;

  double priceFor(BillingPeriod period) =>
      period == BillingPeriod.monthly ? monthlyPrice : annualPrice;

  Map<String, dynamic> toJson({required BillingPeriod billingPeriod}) => {
        'code': code,
        'billing_period': billingPeriod.apiValue,
      };

  static List<SubscriptionPlan> get defaultPlans => const [
        SubscriptionPlan(
          code: 'basic',
          title: 'Basic',
          description: 'Essential tools for young clinics.',
          monthlyPrice: 599.0,
          annualPrice: 5990.0,
          features: [
            'Patient intake and tracking',
            'Core scheduling',
            'PDF export',
            'Two admin seats',
          ],
        ),
        SubscriptionPlan(
          code: 'standard',
          title: 'Standard',
          description: 'Automation and media workflows for growing teams.',
          monthlyPrice: 1099.0,
          annualPrice: 10990.0,
          features: [
            'Everything in Basic',
            'Branch management',
            'Video and media uploads',
            'Scheduling automations',
            'Custom assessment templates',
          ],
        ),
        SubscriptionPlan(
          code: 'pro',
          title: 'Pro',
          description: 'Enterprise analytics and collaboration suite.',
          monthlyPrice: 1699.0,
          annualPrice: 16990.0,
          features: [
            'Everything in Standard',
            'Video consults',
            'Pose estimation workflows',
            'Advanced reporting and versioning',
            'Priority concierge support',
          ],
        ),
      ];

  @override
  List<Object?> get props =>
      [code, title, description, monthlyPrice, annualPrice, features];
}

class TenantProfile extends Equatable {
  const TenantProfile({
    required this.organizationName,
    required this.legalName,
    required this.country,
    required this.city,
    required this.addressLine,
    required this.contactEmail,
    required this.contactPhone,
    this.website,
    this.taxNumber,
  });

  final String organizationName;
  final String legalName;
  final String country;
  final String city;
  final String addressLine;
  final String contactEmail;
  final String contactPhone;
  final String? website;
  final String? taxNumber;

  factory TenantProfile.empty() => const TenantProfile(
        organizationName: '',
        legalName: '',
        country: '',
        city: '',
        addressLine: '',
        contactEmail: '',
        contactPhone: '',
        website: '',
        taxNumber: '',
      );

  TenantProfile copyWith({
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
    return TenantProfile(
      organizationName: organizationName ?? this.organizationName,
      legalName: legalName ?? this.legalName,
      country: country ?? this.country,
      city: city ?? this.city,
      addressLine: addressLine ?? this.addressLine,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      website: website ?? this.website,
      taxNumber: taxNumber ?? this.taxNumber,
    );
  }

  Map<String, dynamic> toJson() => {
        'organization_name': organizationName,
        'legal_name': legalName.isEmpty ? organizationName : legalName,
        'country': country,
        'city': city,
        'address_line': addressLine,
        'contact_email': contactEmail,
        'contact_phone': contactPhone,
        'website': website,
        'tax_number': taxNumber,
      };

  @override
  List<Object?> get props => [
        organizationName,
        legalName,
        country,
        city,
        addressLine,
        contactEmail,
        contactPhone,
        website,
        taxNumber,
      ];
}

class AdminProfile extends Equatable {
  const AdminProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
    required this.confirmPassword,
    this.jobTitle,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String password;
  final String confirmPassword;
  final String? jobTitle;

  factory AdminProfile.empty() => const AdminProfile(
        firstName: '',
        lastName: '',
        email: '',
        phone: '',
        password: '',
        confirmPassword: '',
        jobTitle: '',
      );

  AdminProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? password,
    String? confirmPassword,
    String? jobTitle,
  }) {
    return AdminProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      jobTitle: jobTitle ?? this.jobTitle,
    );
  }

  String get fullName => '$firstName $lastName'.trim();

  Map<String, dynamic> toJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'password': password,
        'job_title': jobTitle,
      };

  @override
  List<Object?> get props =>
      [firstName, lastName, email, phone, password, confirmPassword, jobTitle];
}

class SignInRequest extends Equatable {
  const SignInRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'email': email.trim(),
        'password': password,
      };

  @override
  List<Object?> get props => [email, password];
}

class SignUpRequest extends Equatable {
  const SignUpRequest({
    required this.tenant,
    required this.admin,
    required this.plan,
    required this.billingPeriod,
  });

  final TenantProfile tenant;
  final AdminProfile admin;
  final SubscriptionPlan plan;
  final BillingPeriod billingPeriod;

  Map<String, dynamic> toJson() => {
        'organization_name': tenant.organizationName,
        'legal_name': tenant.legalName,
        'contact_email': tenant.contactEmail,
        'contact_phone': tenant.contactPhone,
        'address': tenant.addressLine,
        'admin_first_name': admin.firstName,
        'admin_last_name': admin.lastName,
        'admin_personal_email': admin.email,
        'admin_mobile_phone': admin.phone,
        'subscription_plan': plan.code,
        'billing_cycle': billingPeriod.apiValue,
      };

  @override
  List<Object?> get props => [tenant, admin, plan, billingPeriod];
}

class AuthSession extends Equatable {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.subject,
    required this.roles,
    this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final String subject;
  final List<String> roles;
  final DateTime? expiresAt;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    DateTime? parsedExpiry;
    final rawExpiry = json['expires_at'];
    if (rawExpiry != null) {
      parsedExpiry = DateTime.tryParse(rawExpiry.toString());
    }

    return AuthSession(
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      roles: (json['roles'] as List?)
              ?.map((role) => role.toString())
              .toList(growable: false) ??
          const [],
      expiresAt: parsedExpiry,
    );
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, subject, roles, expiresAt];
}

class SignupInitiated extends Equatable {
  const SignupInitiated({
    required this.organizationId,
    required this.verificationId,
    required this.totpSecret,
    required this.totpUri,
    required this.expiresAt,
  });

  final int organizationId;
  final String verificationId;
  final String totpSecret;
  final String totpUri;
  final DateTime expiresAt;

  factory SignupInitiated.fromJson(Map<String, dynamic> json) {
    return SignupInitiated(
      organizationId: json['organization_id'] as int,
      verificationId: json['verification_id'].toString(),
      totpSecret: json['totp_secret'].toString(),
      totpUri: json['totp_uri'].toString(),
      expiresAt: DateTime.parse(json['expires_at'].toString()),
    );
  }

  @override
  List<Object?> get props =>
      [organizationId, verificationId, totpSecret, totpUri, expiresAt];
}

class SignupVerificationResult extends Equatable {
  const SignupVerificationResult({
    required this.organizationId,
    required this.workspaceEmail,
    required this.workspaceTemporaryPassword,
    required this.databaseName,
    required this.databaseUser,
    required this.databasePassword,
  });

  final int organizationId;
  final String workspaceEmail;
  final String workspaceTemporaryPassword;
  final String databaseName;
  final String databaseUser;
  final String databasePassword;

  factory SignupVerificationResult.fromJson(Map<String, dynamic> json) {
    return SignupVerificationResult(
      organizationId: json['organization_id'] as int,
      workspaceEmail: json['workspace_email'].toString(),
      workspaceTemporaryPassword: json['temp_workspace_password'].toString(),
      databaseName: json['database_name'].toString(),
      databaseUser: json['database_user'].toString(),
      databasePassword: json['database_password'].toString(),
    );
  }

  @override
  List<Object?> get props => [
        organizationId,
        workspaceEmail,
        workspaceTemporaryPassword,
        databaseName,
        databaseUser,
        databasePassword,
      ];
}
