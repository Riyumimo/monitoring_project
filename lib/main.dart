import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import './features/auth/providers/auth_provider.dart';
import './features/offerings/providers/project_provider.dart';
import './features/timeline/providers/timeline_provider.dart';
import './features/workers/providers/worker_provider.dart';
import './app/router/app_router.dart';
import './core/services/error_logger.dart';
import './app/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorLogger.installGlobalHandlers();
  usePathUrlStrategy();
  final auth = AuthProvider();
  await auth.restoreSession();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<ProjectProvider>(
          create: (_) => ProjectProvider(),
        ),
        ChangeNotifierProvider<WorkerProvider>(create: (_) => WorkerProvider()),
        ChangeNotifierProxyProvider<WorkerProvider, TimelineProvider>(
          create: (_) => TimelineProvider(),
          update: (_, workerProvider, timelineProvider) {
            return timelineProvider!..syncWorkers(
              workerProvider.workers,
              hasLoaded: workerProvider.isLoaded,
            );
          },
        ),
      ],
      child: MyApp(auth: auth),
    ),
  );
}

class MyApp extends StatefulWidget {
  final AuthProvider auth;

  const MyApp({super.key, required this.auth});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppRouter _appRouter = AppRouter(widget.auth);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Geoterra Monitoring',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      routerConfig: _appRouter.router,
    );
  }
}
