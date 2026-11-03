import 'package:flutter/material.dart';

import '../../features/movies/domain/movie.dart';
import '../theme/app_colors.dart';

/// A gradient placeholder used everywhere a real poster would be.
///
/// The backend does not store artwork yet, so every movie gets a stable
/// gradient derived from its id. Swapping in `CachedNetworkImage` later only
/// requires changing this widget.
class GradientPoster extends StatelessWidget {
  const GradientPoster({
    super.key,
    required this.seed,
    required this.title,
    this.borderRadius = 10,
    this.showTitle = true,
    this.titleStyle,
    this.overlay,
  });

  final int seed;
  final String title;
  final double borderRadius;
  final bool showTitle;
  final TextStyle? titleStyle;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.posterGradientFor(seed),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.18),
                ),
              ),
            ),
            if (showTitle)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle ??
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                  ),
                ),
              ),
            ?overlay,
          ],
        ),
      ),
    );
  }
}

/// Small outlined badge used for the content rating ("16+", "8").
class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.rating});

  final String rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textMuted, width: 1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        rating,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Landscape card used inside the home rows (matches the web `NetflixCard`).
class MovieCard extends StatelessWidget {
  const MovieCard({
    super.key,
    required this.movie,
    required this.onTap,
    this.inList = false,
  });

  final Movie movie;
  final VoidCallback onTap;
  final bool inList;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 196,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: GradientPoster(
              seed: movie.id,
              title: movie.title,
              overlay: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Text(
                      '${movie.matchPercent}% Match',
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (inList)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        Icons.bookmark,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Portrait tile used by grids (My List, Search, admin previews).
class PosterTile extends StatelessWidget {
  const PosterTile({
    super.key,
    required this.movie,
    required this.onTap,
    this.inList = false,
  });

  final Movie movie;
  final VoidCallback onTap;
  final bool inList;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: GradientPoster(
            seed: movie.id,
            title: movie.title,
            borderRadius: 12,
            showTitle: false,
            overlay: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 28, 10, 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          movie.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${movie.yearLabel} • ${movie.genreList.take(1).join()}',
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
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      movie.rating,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (inList)
                  const Positioned(
                    top: 8,
                    left: 8,
                    child: Icon(Icons.bookmark, size: 15, color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
