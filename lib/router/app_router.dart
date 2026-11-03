import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/presentation/admin_movies_page.dart';
import '../features/admin/presentation/movie_form_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/profiles_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/auth/presentation/splash_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/movies/domain/movie.dart';
import '../features/movies/presentation/movie_detail_page.dart';
import '../features/movies/presentation/player_page.dart';
import '../features/my_list/presentation/my_list_page.dart';
import '../features/new_hot/presentation/new_hot_page.dart';
import '../features/profile/presentation/edit_profile_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/search/presentation/search_page.dart';
import '../features/session/presentation/session_controller.dart';
import '../features/shell/presentation/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final location = state.matchedLocation;
      final onSplash = location == '/splash';
      final onAuth = location == '/login' || location == '/register';

      // While bootstrapping (or after a bootstrap failure) stay on splash.
      if (session.isLoading || session.hasError) {
        return onSplash ? null : '/splash';
      }

      final value = session.value;
      if (value == null) {
        return onAuth ? null : '/login';
      }

      if (onAuth || onSplash) return '/profiles';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginPage(
          initialEmail: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterPage(
          initialEmail: state.extra is String ? state.extra as String : null,
        ),
      ),
      GoRoute(
        path: '/profiles',
        builder: (_, _) => const ProfilesPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, _) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/new',
                builder: (_, _) => const NewHotPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my-list',
                builder: (_, _) => const MyListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/search',
        builder: (_, _) => const SearchPage(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, _) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/movie/:id/play',
        builder: (context, state) => PlayerPage(
          movieId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
        ),
      ),
      GoRoute(
        path: '/movie/:id',
        builder: (context, state) => MovieDetailPage(
          movieId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
        ),
      ),
      GoRoute(
        path: '/admin',
        builder: (_, _) => const AdminMoviesPage(),
      ),
      GoRoute(
        path: '/admin/movie',
        builder: (context, state) => MovieFormPage(
          existing: state.extra is Movie ? state.extra as Movie : null,
        ),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
