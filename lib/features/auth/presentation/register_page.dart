import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/buttons.dart';
import '../../session/presentation/session_controller.dart';
import 'auth_shell.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _username = TextEditingController();
  late final TextEditingController _email =
      TextEditingController(text: widget.initialEmail ?? '');
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
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
      await ref.read(sessionControllerProvider.notifier).register(
            username: _username.text,
            email: _email.text,
            password: _password.text,
          );

      if (!mounted) return;
      final email = _email.text.trim().toLowerCase();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun berhasil dibuat. Silakan masuk.'),
        ),
      );
      context.go('/login?email=${Uri.encodeComponent(email)}');
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.userMessage);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Gagal mendaftar. Coba lagi.');
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
              'Daftar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Buat akun Kayflix dalam hitungan detik.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: _username,
              label: 'Username',
              hint: 'Minimal 6 karakter',
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newUsername],
              prefixIcon: Icons.person_outline,
              validator: Validators.username,
            ),
            const SizedBox(height: 18),
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
              hint: 'Minimal 6 karakter',
              obscure: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              prefixIcon: Icons.lock_outline,
              validator: Validators.password,
            ),
            const SizedBox(height: 18),
            AppTextField(
              controller: _confirm,
              label: 'Konfirmasi Password',
              hint: 'Ulangi password',
              obscure: true,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.lock_outline,
              validator: (value) {
                if ((value ?? '').isEmpty) return 'Konfirmasi wajib diisi';
                if (value != _password.text) return 'Password tidak sama';
                return null;
              },
              onSubmitted: (_) => _loading ? null : _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.red.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 18,
                      color: AppColors.red,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFFFB4B4),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Buat Akun',
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Sudah punya akun?',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                TextButton(
                  onPressed: _loading ? null : () => context.go('/login'),
                  child: const Text(
                    'Masuk',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
