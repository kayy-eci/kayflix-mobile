import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/mime.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../my_list/presentation/likes_controller.dart';
import '../../my_list/presentation/my_list_controller.dart';
import '../../session/presentation/session_controller.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _uploading = false;

  Future<void> _changeAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ganti foto profil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Pilih dari galeri'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Ambil dari kamera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (source == null || !mounted) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ukuran gambar maksimal 5MB.')),
        );
        return;
      }

      setState(() => _uploading = true);
      await ref.read(sessionControllerProvider.notifier).uploadAvatar(
            bytes: bytes,
            filename: picked.name,
            mimeType: mimeTypeForFilename(picked.name),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil diperbarui.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.userMessage)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengunggah foto profil.')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await _confirm(
      title: 'Keluar dari Kayflix?',
      message: 'Kamu perlu masuk kembali untuk melanjutkan menonton.',
      confirmLabel: 'Keluar',
    );
    if (!confirmed) return;
    await ref.read(sessionControllerProvider.notifier).signOut();
  }

  Future<void> _deleteAccount() async {
    final confirmed = await _confirm(
      title: 'Hapus akun?',
      message:
          'Akun dan akses kamu akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!confirmed) return;

    try {
      await ref.read(sessionControllerProvider.notifier).deleteAccount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun berhasil dihapus.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.userMessage)),
      );
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: destructive ? AppColors.red : Colors.white,
              foregroundColor: destructive ? Colors.white : Colors.black,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider).value;
    final myListCount = ref.watch(myListProvider).value?.length ?? 0;
    final likesCount = ref.watch(likesProvider).value?.length ?? 0;

    if (session == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingView(),
      );
    }

    final user = session.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: _uploading ? null : _changeAvatar,
                  child: UserAvatar(
                    user: user,
                    size: 104,
                    showEditBadge: !_uploading,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                if (_uploading)
                  const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              user.username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              user.email,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: session.isAdmin
                    ? AppColors.red.withValues(alpha: 0.15)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: session.isAdmin
                      ? AppColors.red.withValues(alpha: 0.5)
                      : AppColors.border,
                ),
              ),
              child: Text(
                session.isAdmin ? 'ADMIN' : 'MEMBER',
                style: TextStyle(
                  color: session.isAdmin
                      ? const Color(0xFFFF8A8A)
                      : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: '$myListCount',
                  label: 'Daftar Saya',
                  icon: Icons.bookmark_border,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: '$likesCount',
                  label: 'Disukai',
                  icon: Icons.thumb_up_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _MenuTile(
            icon: Icons.edit_outlined,
            label: 'Edit Profil',
            subtitle: 'Ubah username, email, dan password',
            onTap: () => context.push('/profile/edit'),
          ),
          _MenuTile(
            icon: Icons.bookmark_border,
            label: 'Daftar Saya',
            subtitle: '$myListCount judul tersimpan',
            onTap: () => context.go('/my-list'),
          ),
          if (session.isAdmin)
            _MenuTile(
              icon: Icons.dashboard_customize_outlined,
              label: 'Kelola Film',
              subtitle: 'Tambah, ubah, dan hapus judul',
              accent: true,
              onTap: () => context.push('/admin'),
            ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _MenuTile(
            icon: Icons.logout,
            label: 'Keluar',
            onTap: _signOut,
          ),
          _MenuTile(
            icon: Icons.delete_outline,
            label: 'Hapus Akun',
            destructive: true,
            onTap: _deleteAccount,
          ),
          const SizedBox(height: 26),
          const Center(
            child: Text(
              'Kayflix Mobile • v1.0.0',
              style: TextStyle(color: AppColors.textMuted, fontSize: 10.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool destructive;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? AppColors.red
        : accent
            ? Colors.white
            : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 21, color: destructive ? AppColors.red : color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
