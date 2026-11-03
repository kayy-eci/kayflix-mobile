import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/state_views.dart';
import '../../movies/domain/movie.dart';
import '../../movies/presentation/movie_providers.dart';
import '../../session/presentation/session_controller.dart';

class MovieFormPage extends ConsumerStatefulWidget {
  const MovieFormPage({super.key, this.existing});

  final Movie? existing;

  @override
  ConsumerState<MovieFormPage> createState() => _MovieFormPageState();
}

class _MovieFormPageState extends ConsumerState<MovieFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title =
      TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _year = TextEditingController(
    text: widget.existing == null ? '' : '${widget.existing!.year}',
  );
  late final TextEditingController _duration =
      TextEditingController(text: widget.existing?.duration ?? '');
  late final TextEditingController _genres =
      TextEditingController(text: widget.existing?.genres ?? '');

  late String _rating = _initialRating();

  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  String _initialRating() {
    final current = widget.existing?.rating ?? '';
    if (current.isNotEmpty) return current;
    return '';
  }

  List<String> get _ratingOptions {
    final options = List<String>.generate(10, (index) => '${index + 1}');
    if (_rating.isNotEmpty && !options.contains(_rating)) {
      options.insert(0, _rating);
    }
    return options;
  }

  @override
  void dispose() {
    _title.dispose();
    _year.dispose();
    _duration.dispose();
    _genres.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final movie = Movie(
      id: widget.existing?.id ?? 0,
      title: _title.text.trim(),
      year: int.tryParse(_year.text.trim()) ?? 0,
      rating: _rating,
      duration: _duration.text.trim(),
      genres: _genres.text.trim(),
    );

    try {
      final repository = ref.read(movieRepositoryProvider);
      if (_isEditing) {
        await repository.update(widget.existing!.id, movie);
      } else {
        await repository.create(movie);
      }

      ref.invalidate(moviesProvider);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? '"${movie.title}" berhasil diperbarui.'
                : '"${movie.title}" berhasil ditambahkan.',
          ),
        ),
      );
      context.pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.userMessage);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Gagal menyimpan film. Coba lagi.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider).value;

    if (session == null || !session.isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background),
        body: const EmptyStateView(
          icon: Icons.lock_outline,
          title: 'Akses ditolak',
          message: 'Hanya admin yang boleh mengubah katalog.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Film' : 'Tambah Film'),
        backgroundColor: AppColors.background,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            AppTextField(
              controller: _title,
              label: 'Judul Film',
              hint: 'Masukkan judul film',
              textInputAction: TextInputAction.next,
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'Judul wajib diisi'
                  : null,
            ),
            const SizedBox(height: 18),
            AppTextField(
              controller: _year,
              label: 'Tahun',
              hint: '2025',
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.calendar_today_outlined,
              validator: (value) {
                final year = int.tryParse((value ?? '').trim());
                if (year == null) return 'Tahun wajib berupa angka';
                if (year < 1888 || year > 2100) {
                  return 'Tahun harus antara 1888 dan 2100';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            const Text(
              'Rating',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _rating.isEmpty ? null : _rating,
              isExpanded: true,
              dropdownColor: AppColors.card,
              decoration: const InputDecoration(hintText: 'Pilih rating'),
              items: [
                for (final option in _ratingOptions)
                  DropdownMenuItem(value: option, child: Text(option)),
              ],
              onChanged: (value) =>
                  setState(() => _rating = value ?? ''),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Rating wajib dipilih' : null,
            ),
            const SizedBox(height: 18),
            AppTextField(
              controller: _duration,
              label: 'Durasi',
              hint: '2h 15m atau 2 Seasons',
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.schedule,
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'Durasi wajib diisi'
                  : null,
            ),
            const SizedBox(height: 18),
            AppTextField(
              controller: _genres,
              label: 'Genres',
              hint: 'Action, Drama',
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.local_movies_outlined,
              helperText: 'Pisahkan beberapa genre dengan koma.',
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'Minimal satu genre'
                  : null,
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
            const SizedBox(height: 26),
            PrimaryButton(
              label: _isEditing ? 'Simpan Perubahan' : 'Tambah ke Katalog',
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
