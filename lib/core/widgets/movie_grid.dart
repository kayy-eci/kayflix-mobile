import 'package:flutter/material.dart';

import '../../features/movies/domain/movie.dart';
import 'movie_art.dart';

/// Responsive portrait grid shared by My List and Search.
class MovieGrid extends StatelessWidget {
  const MovieGrid({
    super.key,
    required this.movies,
    required this.inList,
    required this.onTap,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 28),
    this.header,
  });

  final List<Movie> movies;
  final Set<int> inList;
  final void Function(Movie movie) onTap;
  final EdgeInsets padding;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1000
            ? 6
            : width >= 760
                ? 4
                : width >= 520
                    ? 3
                    : 2;

        final grid = GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          itemCount: movies.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 2 / 3,
          ),
          itemBuilder: (context, index) {
            final movie = movies[index];
            return PosterTile(
              movie: movie,
              inList: inList.contains(movie.id),
              onTap: () => onTap(movie),
            );
          },
        );

        if (header == null) return grid;

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: header),
            SliverPadding(
              padding: padding,
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2 / 3,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final movie = movies[index];
                    return PosterTile(
                      movie: movie,
                      inList: inList.contains(movie.id),
                      onTap: () => onTap(movie),
                    );
                  },
                  childCount: movies.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
