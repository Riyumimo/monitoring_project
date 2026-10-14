import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:geoterra_monitoring/providers/auth_provider.dart';
import 'package:geoterra_monitoring/providers/project_provider.dart';
import 'package:geoterra_monitoring/main.dart';

void main() {
  testWidgets('Unauthenticated users are redirected to the login screen',
      (WidgetTester tester) async {
    final auth = AuthProvider();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<ProjectProvider>(
            create: (_) => ProjectProvider(),
          ),
        ],
        child: MyApp(auth: auth),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Login'), findsWidgets);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
