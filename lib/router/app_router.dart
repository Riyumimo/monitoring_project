import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/dashboard_page.dart';
import '../screens/dashboard_shell.dart';
import '../screens/login_screen.dart';
import '../screens/offering_detail_screen.dart';
import '../screens/offering_form_screen.dart';
import '../screens/offerings_page.dart';
import '../screens/project_detail_screen.dart';
import '../screens/project_form_screen.dart';
import '../screens/timeline_page.dart';
import '../screens/tools_view.dart';
import '../screens/worker_form_screen.dart';
import '../screens/workers_view.dart';

class AppRouter {
  AppRouter(this.auth);

  final AuthProvider auth;

  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String offerings = '/offerings';
  static const String tools = '/tools';
  static const String workers = '/workers';
  static const String timeline = '/timeline';
  static const String newOffering = '/offerings/new';
  static const String newWorker = '/workers/new';

  static String offeringDetail(String id, {int tab = 0}) =>
      tab == 0 ? '/offerings/$id' : '/offerings/$id?tab=$tab';
  static String offeringEdit(String id) => '/offerings/$id/edit';
  static String newProject(String offeringId) =>
      '/offerings/$offeringId/project/new';
  static String projectDetail(String id) => '/projects/$id';
  static String projectEdit(String id) => '/projects/$id/edit';
  static String workerEdit(String id) => '/workers/$id/edit';

  late final GoRouter router = GoRouter(
    initialLocation: dashboard,
    refreshListenable: auth,
    redirect: (context, state) {
      final isLogin = state.matchedLocation == login;
      final authed = auth.isAuthenticated;
      if (!authed) return isLogin ? null : login;
      if (isLogin) return dashboard;
      return null;
    },
    routes: [
      GoRoute(path: login, builder: (context, state) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            DashboardShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: dashboard,
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: offerings,
                builder: (context, state) => const OfferingsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: tools,
                builder: (context, state) => const ToolsView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: workers,
                builder: (context, state) => const WorkersView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: timeline,
                builder: (context, state) => const TimelinePage(),
              ),
            ],
          ),
        ],
      ),
      // Offering form (create / edit).
      GoRoute(
        path: newOffering,
        builder: (context, state) => const OfferingFormScreen(),
      ),
      GoRoute(
        path: '/offerings/:id',
        builder: (context, state) {
          final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
          return OfferingDetailScreen(
            id: state.pathParameters['id']!,
            initialTab: tab.clamp(0, 3),
          );
        },
      ),
      GoRoute(
        path: '/offerings/:id/edit',
        builder: (context, state) =>
            OfferingFormScreen(offeringId: state.pathParameters['id']),
      ),
      // Project form, reachable from an accepted offering.
      GoRoute(
        path: '/offerings/:id/project/new',
        builder: (context, state) =>
            ProjectFormScreen(offeringId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/projects/:id',
        builder: (context, state) =>
            ProjectDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/projects/:id/edit',
        builder: (context, state) =>
            ProjectFormScreen(projectId: state.pathParameters['id']),
      ),
      // Worker form (create / edit).
      GoRoute(
        path: newWorker,
        builder: (context, state) => const WorkerFormScreen(),
      ),
      GoRoute(
        path: '/workers/:id/edit',
        builder: (context, state) =>
            WorkerFormScreen(workerId: state.pathParameters['id']),
      ),
    ],
  );
}
