import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../movies/domain/movie.dart';
import '../../movies/presentation/movie_providers.dart';

/// A full-screen mock player. The backend exposes no stream URL, so this
/// screen simulates playback with a ticking timeline.
class PlayerPage extends ConsumerStatefulWidget {
  const PlayerPage({super.key, required this.movieId});

  final int movieId;

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  Timer? _timer;
  Duration _duration = const Duration(minutes: 45);
  Duration _position = Duration.zero;
  bool _playing = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_playing) return;
      if (_position >= _duration) {
        setState(() => _playing = false);
        return;
      }
      setState(() {
        _position += const Duration(seconds: 1);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _seekBy(int seconds) {
    final target = _position + Duration(seconds: seconds);
    setState(() {
      if (target < Duration.zero) {
        _position = Duration.zero;
      } else if (target > _duration) {
        _position = _duration;
      } else {
        _position = target;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final movie = ref.watch(movieByIdProvider(widget.movieId));

    if (movie == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black),
        body: const Center(
          child: Text(
            'Film tidak tersedia.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    _duration = _parseDuration(movie.duration);
    if (_position > _duration) _position = _duration;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.posterGradientFor(movie.id),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.65),
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0, 0.45, 1],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _TopBar(movie: movie),
                const Spacer(),
                _CenterBadge(playing: _playing),
                const Spacer(),
                _Controls(
                  position: _position,
                  duration: _duration,
                  playing: _playing,
                  onPlayPause: () {
                    if (_position >= _duration) {
                      setState(() {
                        _position = Duration.zero;
                        _playing = true;
                      });
                      return;
                    }
                    setState(() => _playing = !_playing);
                  },
                  onSeek: (value) {
                    setState(() {
                      _position = Duration(seconds: value.round());
                    });
                  },
                  onBack10: () => _seekBy(-10),
                  onForward10: () => _seekBy(10),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: Text(
                    'Demo playback • server belum menyediakan streaming',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Duration _parseDuration(String raw) {
    final hours = RegExp(r'(\d+)\s*(?:h|j|jam)', caseSensitive: false)
        .firstMatch(raw);
    final minutes = RegExp(r'(\d+)\s*(?:m|mnt|menit)', caseSensitive: false)
        .firstMatch(raw);

    if (hours == null && minutes == null) {
      return const Duration(minutes: 45);
    }

    final h = int.tryParse(hours?.group(1) ?? '') ?? 0;
    final m = int.tryParse(minutes?.group(1) ?? '') ?? 0;
    final result = Duration(hours: h, minutes: m);
    return result == Duration.zero ? const Duration(minutes: 45) : result;
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            icon: const Icon(Icons.keyboard_arrow_down, size: 28),
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterBadge extends StatelessWidget {
  const _CenterBadge({required this.playing});

  final bool playing;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: playing ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 220),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pause_circle_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Dijeda',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.position,
    required this.duration,
    required this.playing,
    required this.onPlayPause,
    required this.onSeek,
    required this.onBack10,
    required this.onForward10,
  });

  final Duration position;
  final Duration duration;
  final bool playing;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onSeek;
  final VoidCallback onBack10;
  final VoidCallback onForward10;

  @override
  Widget build(BuildContext context) {
    final maxSeconds = duration.inSeconds <= 0 ? 1 : duration.inSeconds;
    final value = position.inSeconds.clamp(0, maxSeconds).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.red,
              inactiveTrackColor: Colors.white24,
              thumbColor: AppColors.red,
              overlayColor: AppColors.red.withValues(alpha: 0.2),
              trackHeight: 2.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              min: 0,
              max: maxSeconds.toDouble(),
              value: value,
              onChanged: onSeek,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _format(position),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                Text(
                  _format(duration),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onBack10,
                icon: const Icon(Icons.replay_10, size: 30),
                color: Colors.white,
              ),
              const SizedBox(width: 26),
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPlayPause,
                  child: SizedBox(
                    width: 62,
                    height: 62,
                    child: Icon(
                      playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 34,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 26),
              IconButton(
                onPressed: onForward10,
                icon: const Icon(Icons.forward_10, size: 30),
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  String _format(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }
}
