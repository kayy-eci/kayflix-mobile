import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/buttons.dart';
import '../../session/presentation/session_controller.dart';
import 'auth_shell.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email =
      TextEditingController(text: widget.initialEmail ?? '');
  final TextEditingController _password = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(sessionControllerProvider.notifier).login(
            email: _email.text,
            password: _password.text,
          );
      // The router redirects as soon as the session becomes available.
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.userMessage);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Gagal masuk. Coba lagi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrandLogo(fontSize: 36),
            const SizedBox(height: 28),
            const Text(
              'Masuk',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Lanjutkan menonton film favoritmu.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: _email,
              label: 'Email',
              hint: 'nama@email.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              prefixIcon: Icons.mail_outline,
              validator: Validators.email,
            ),
            const SizedBox(height: 18),
            AppTextField(
              controller: _password,
              label: 'Password',
              hint: 'Masukkan password',
              obscure: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              prefixIcon: Icons.lock_outline,
              validator: Validators.password,
              onSubmitted: (_) => _loading ? null : _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(message: _error!),
            ],
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Masuk',
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Belum punya akun?',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => context.go(
                            '/register',
                            extra: _email.text.trim(),
                          ),
                  child: const Text(
                    'Daftar sekarang',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'Server: ${ApiConfig.baseUrl}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFFFB4B4),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
