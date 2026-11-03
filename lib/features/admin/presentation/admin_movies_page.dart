import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/movie_art.dart';
import '../../../core/widgets/state_views.dart';
import '../../movies/domain/movie.dart';
import '../../movies/presentation/movie_providers.dart';
import '../../session/presentation/session_controller.dart';

class AdminMoviesPage extends ConsumerStatefulWidget {
  const AdminMoviesPage({super.key});

  @override
  ConsumerState<AdminMoviesPage> createState() => _AdminMoviesPageState();
}

class _AdminMoviesPageState extends ConsumerState<AdminMoviesPage> {
  int? _deletingId;

  Future<void> _delete(Movie movie) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Hapus film?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '"${movie.title}" akan dihapus dari katalog.',
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
              backgroundColor: AppColors.red,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingId = movie.id);
    try {
      await ref.read(movieRepositoryProvider).delete(movie.id);
      ref.invalidate(moviesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${movie.title}" berhasil dihapus.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.userMessage)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus film.')),
      );
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider).value;
    final moviesAsync = ref.watch(moviesProvider);

    if (session == null || !session.isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Kelola Film'),
          backgroundColor: AppColors.background,
        ),
        body: const EmptyStateView(
          icon: Icons.lock_outline,
          title: 'Akses ditolak',
          message: 'Halaman ini hanya tersedia untuk akun admin.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Film'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: () => ref.invalidate(moviesProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/movie'),
        backgroundColor: AppColors.red,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Film'),
      ),
      body: moviesAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorStateView(
          message: error is Exception
              ? error.toString().replaceFirst('ApiException: ', '')
              : 'Gagal memuat film.',
          onRetry: () => ref.invalidate(moviesProvider),
        ),
        data: (movies) {
          if (movies.isEmpty) {
            return EmptyStateView(
              title: 'Belum ada film',
              message: 'Tambahkan judul pertama ke katalog Kayflix.',
              actionLabel: 'Tambah Film',
              onAction: () => context.push('/admin/movie'),
            );
          }

          return RefreshIndicator(
            color: AppColors.red,
            backgroundColor: AppColors.card,
            onRefresh: () async {
              ref.invalidate(moviesProvider);
              try {
                await ref.read(moviesProvider.future);
              } catch (_) {}
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: movies.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${movies.length} judul di katalog',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  );
                }

                final movie = movies[index - 1];
                return _AdminMovieTile(
                  movie: movie,
                  deleting: _deletingId == movie.id,
                  onEdit: () => context.push('/admin/movie', extra: movie),
                  onDelete: () => _delete(movie),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AdminMovieTile extends StatelessWidget {
  const _AdminMovieTile({
    required this.movie,
    required this.deleting,
    required this.onEdit,
    required this.onDelete,
  });

  final Movie movie;
  final bool deleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 48,
            child: GradientPoster(
              seed: movie.id,
              title: movie.title,
              showTitle: false,
              borderRadius: 8,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${movie.yearLabel} • ${movie.rating} • ${movie.duration}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  movie.genres,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          if (deleting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            IconButton(
              tooltip: 'Edit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 19),
              color: AppColors.textSecondary,
            ),
            IconButton(
              tooltip: 'Hapus',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 19),
              color: AppColors.red,
            ),
          ],
        ],
      ),
    );
  }
}
