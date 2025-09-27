import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/utils/validators.dart';
import '../controllers/sign_in_controller.dart';
import '../providers/auth_providers.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(signInControllerProvider);
    _emailController = TextEditingController(text: state.email)
      ..addListener(() {
        ref.read(signInControllerProvider.notifier).updateEmail(
              _emailController.text,
            );
      });
    _passwordController = TextEditingController(text: state.password)
      ..addListener(() {
        ref.read(signInControllerProvider.notifier).updatePassword(
              _passwordController.text,
            );
      });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SignInState>(signInControllerProvider, (previous, next) {
      if (!mounted) return;
      if (next.session != null && previous?.session != next.session) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome ${next.session!.subject}')),
        );
      } else if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    final state = ref.watch(signInControllerProvider);
    final controller = ref.read(signInControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Physiotech Control Panel')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.healing,
                    size: 64, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Sign in to manage your clinic tenants',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'admin@clinic.com',
                    errorText: state.showErrors
                        ? validateEmail(_emailController.text)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    errorText: state.showErrors
                        ? validatePassword(_passwordController.text)
                        : null,
                  ),
                  onSubmitted: (_) => controller.submit(),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: implement password reset flow.
                    },
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: state.isLoading ? null : controller.submit,
                  child: state.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign in'),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => context.go(SignUpRoute.path),
                  child: const Text('Create new organization'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
