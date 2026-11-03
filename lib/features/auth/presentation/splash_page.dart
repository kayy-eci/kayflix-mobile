import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/state_views.dart';
import '../../session/presentation/session_controller.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.35),
            radius: 1.1,
            colors: [Color(0xFF2A0609), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: session.hasError
                ? ErrorStateView(
                    title: 'Tidak bisa memuat sesi',
                    message: session.error is ApiException
                        ? (session.error! as ApiException).userMessage
                        : 'Periksa koneksi ke server Kayflix.',
                    onRetry: () =>
                        ref.invalidate(sessionControllerProvider),
                  )
                : const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BrandLogo(fontSize: 44),
                      SizedBox(height: 26),
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
