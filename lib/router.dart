import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers.dart';
import 'ui/auth/delete_account_screen.dart';
import 'ui/auth/login_screen.dart';
import 'ui/auth/register_screen.dart';
import 'ui/feedback/feedback_screen.dart';
import 'ui/home/home_screen.dart';
import 'ui/schedule/schedule_screen.dart';
import 'ui/settings/settings_screen.dart';
import 'ui/shell.dart';
import 'ui/splash_screen.dart';
import 'ui/students/student_card_screen.dart';
import 'ui/trainers/trainers_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();
const _authRoutes = {'/login', '/register'};

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.read(authProvider);
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (!auth.ready) return loc == '/splash' ? null : '/splash';
      if (auth.user == null) return _authRoutes.contains(loc) ? null : '/login';
      if (loc == '/splash' || _authRoutes.contains(loc)) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/schedule', builder: (_, _) => const ScheduleScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/trainers', builder: (_, _) => const TrainersScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/feedback', builder: (_, _) => const FeedbackScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'delete-account',
                    parentNavigatorKey: _rootKey,
                    builder: (_, _) => const DeleteAccountScreen(),
                  ),
                  GoRoute(
                    path: 'student/:id',
                    parentNavigatorKey: _rootKey,
                    builder: (_, state) => StudentCardScreen(studentId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
