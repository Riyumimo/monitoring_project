import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoterra_monitoring/models/project.dart';
import 'package:geoterra_monitoring/providers/project_provider.dart';
import 'package:geoterra_monitoring/providers/timeline_provider.dart';
import 'package:geoterra_monitoring/screens/timeline_page.dart';
import 'package:geoterra_monitoring/theme/app_theme.dart';
import 'package:provider/provider.dart';

class _TestProjectProvider extends ProjectProvider {
  _TestProjectProvider([this._testProjects = const []]);

  final List<Project> _testProjects;

  @override
  List<Project> get projects => _testProjects;

  @override
  Future<void> ensureProjectsLoaded() async {}
}

Widget _app({ProjectProvider? projectProvider}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => TimelineProvider()),
      ChangeNotifierProvider<ProjectProvider>.value(
        value: projectProvider ?? _TestProjectProvider(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: TimelinePage()),
    ),
  );
}

void main() {
  testWidgets('renders the timeline and team rows', (tester) async {
    await tester.pumpWidget(_app());

    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('Add Task'), findsOneWidget);
    expect(find.text('Bob Worker'), findsOneWidget);
    expect(find.text('Team member'), findsOneWidget);
  });

  testWidgets('shows project schedules assigned to workers', (tester) async {
    final now = DateTime.now();
    final project = Project(
      id: 'pr-test',
      number: 'PRJ-TEST',
      name: 'Timeline Project',
      offeringId: 'o-test',
      owner: 'Test Client',
      address: 'Test Address',
      status: ProjectStatus.inProgress,
      startDate: DateTime(now.year, now.month, 5),
      endDate: DateTime(now.year, now.month, 10),
      assignedWorkerIds: const ['u2'],
      assignedWorkerNames: const ['Bob Worker'],
    );

    await tester.pumpWidget(
      _app(projectProvider: _TestProjectProvider([project])),
    );
    await tester.pumpAndSettle();

    expect(find.text('Timeline Project'), findsOneWidget);
  });

  testWidgets('opens the new task dialog', (tester) async {
    await tester.pumpWidget(_app());

    await tester.tap(find.text('Add Task'));
    await tester.pumpAndSettle();

    expect(find.text('New Task'), findsOneWidget);
    expect(find.text('Task title'), findsOneWidget);
    expect(find.text('Start date'), findsOneWidget);
    expect(find.text('End date'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('opens the edit dialog when a task is tapped', (tester) async {
    await tester.pumpWidget(_app());

    await tester.tap(find.text('Site Survey - Kapuas'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Task'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('asks for confirmation before deleting a task', (tester) async {
    await tester.pumpWidget(_app());

    await tester.tap(find.text('Site Survey - Kapuas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete task?'), findsOneWidget);
    expect(find.text('Delete'), findsWidgets);
  });

  testWidgets('has a horizontal scrollbar and month navigation', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    expect(find.byType(Scrollbar), findsOneWidget);

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsNothing);
  });

  testWidgets('keeps the Add Task button usable on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());

    expect(find.text('Add Task'), findsOneWidget);
    await tester.tap(find.text('Add Task'));
    await tester.pumpAndSettle();

    expect(find.text('New Task'), findsOneWidget);
  });

  testWidgets('adds a task in a future month and moves the timeline', (
    tester,
  ) async {
    final now = DateTime.now();
    final targetMonth = DateTime(now.year, now.month + 2, 1);
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    await tester.pumpWidget(_app());

    await tester.tap(find.text('Add Task'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Cross-month task');

    await tester.tap(find.byIcon(Icons.event_outlined).first);
    await tester.pumpAndSettle();

    final dateDialog = find.byType(DatePickerDialog);
    expect(dateDialog, findsOneWidget);

    final nextMonth = find.descendant(
      of: dateDialog,
      matching: find.byTooltip('Next month'),
    );
    await tester.tap(nextMonth);
    await tester.pumpAndSettle();
    await tester.tap(nextMonth);
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(of: dateDialog, matching: find.text('15')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Add Task'));
    await tester.pumpAndSettle();

    final label = '${months[targetMonth.month - 1]} ${targetMonth.year}';
    expect(find.text(label), findsOneWidget);
    expect(find.text('Cross-month task'), findsOneWidget);
  });
}
