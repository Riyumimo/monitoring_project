import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/dashboard_page.dart';
import '../screens/dashboard_shell.dart';
import '../screens/login_screen.dart';
import '../screens/map_view_screen.dart';
import '../screens/project_detail_screen.dart';
import '../screens/project_form_screen.dart';
import '../screens/projects_page.dart';
import '../screens/tools_view.dart';
import '../screens/workers_view.dart';

class AppRouter {
  AppRouter(this.auth);

  final AuthProvider auth;

  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String projects = '/projects';
  static const String tools = '/tools';
  static const String workers = '/workers';
  static const String newProject = '/projects/new';
  static const String map = '/map';

  static String projectDetail(String id) => '/projects/$id';
  static String projectEdit(String id) => '/projects/$id/edit';

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
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
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
                path: projects,
                builder: (context, state) => const ProjectsPage(),
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
        ],
      ),
      GoRoute(
        path: newProject,
        builder: (context, state) => const ProjectFormScreen(),
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
      GoRoute(
        path: map,
        builder: (context, state) => const MapViewScreen(),
      ),
    ],
  );
}
