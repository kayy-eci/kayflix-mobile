import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/buttons.dart';
import '../../session/presentation/session_controller.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _initialized = false;
  bool _saving = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final user = ref.read(sessionControllerProvider).value?.user;
    if (user != null) {
      _username.text = user.username;
      _email.text = user.email;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(sessionControllerProvider.notifier).updateProfile(
            username: _username.text,
            email: _email.text,
            password: _password.text,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );
      context.pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.userMessage);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Gagal menyimpan perubahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: AppColors.background,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            const Text(
              'Perbarui data akunmu. Backend Kayflix mewajibkan password diisi setiap kali menyimpan perubahan.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _username,
              label: 'Username',
              hint: 'Minimal 6 karakter',
              textInputAction: TextInputAction.next,
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
              prefixIcon: Icons.mail_outline,
              validator: Validators.email,
            ),
            const SizedBox(height: 18),
            AppTextField(
              controller: _password,
              label: 'Password',
              hint: 'Masukkan password akun',
              obscure: true,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.lock_outline,
              helperText: 'Wajib diisi, minimal 6 karakter.',
              validator: Validators.password,
              onSubmitted: (_) => _saving ? null : _save(),
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
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Simpan Perubahan',
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
