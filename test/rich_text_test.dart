import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoterra_monitoring/models/line_item_text_run.dart';
import 'package:geoterra_monitoring/models/offering_line_item.dart';
import 'package:geoterra_monitoring/utils/rich_text_controller.dart';
import 'package:geoterra_monitoring/widgets/rich_text_shortcuts.dart';

void main() {
  test('text runs round-trip and normalize overlapping ranges', () {
    const runs = [
      LineItemTextRun(start: 0, end: 6, bold: true),
      LineItemTextRun(start: 3, end: 10, italic: true),
    ];

    final restored = LineItemTextRun.fromJson(runs.first.toJson());
    expect(restored.start, 0);
    expect(restored.end, 6);
    expect(restored.bold, isTrue);

    final normalized = normalizedLineItemTextRuns('Survey work', runs);
    expect(normalized.map((run) => (run.start, run.end, run.bold)), [
      (0, 3, true),
      (3, 6, true),
      (6, 10, false),
      (10, 11, false),
    ]);
    expect(normalized[1].italic, isTrue);
    expect(normalized[2].italic, isTrue);
  });

  test('line item persists rich text runs', () {
    const item = OfferingLineItem(
      description: 'Survey work',
      descriptionRuns: [
        LineItemTextRun(start: 0, end: 6, bold: true, italic: true),
      ],
      amount: 1,
    );

    final restored = OfferingLineItem.fromJson(item.toJson());
    expect(restored.description, 'Survey work');
    expect(restored.descriptionRuns, hasLength(1));
    expect(restored.descriptionRuns.single.start, 0);
    expect(restored.descriptionRuns.single.end, 6);
    expect(restored.descriptionRuns.single.bold, isTrue);
    expect(restored.descriptionRuns.single.italic, isTrue);
  });

  test('controller toggles bold and italic on a selection', () {
    final controller = RichTextEditingController(text: 'Survey work');

    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 6);
    controller.toggleBold();
    expect(controller.formatRuns, const [
      LineItemTextRun(start: 0, end: 6, bold: true),
    ]);

    controller.selection = const TextSelection(baseOffset: 7, extentOffset: 11);
    controller.toggleItalic();
    expect(controller.formatRuns, const [
      LineItemTextRun(start: 0, end: 6, bold: true),
      LineItemTextRun(start: 7, end: 11, italic: true),
    ]);

    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 6);
    controller.toggleBold();
    expect(controller.formatRuns, const [
      LineItemTextRun(start: 7, end: 11, italic: true),
    ]);
    controller.dispose();
  });

  test('typing after a bold selection keeps the bold style', () {
    final controller = RichTextEditingController(text: 'Survey');
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 6);
    controller.toggleBold();

    controller.value = controller.value.copyWith(
      text: 'Survey work',
      selection: const TextSelection.collapsed(offset: 11),
    );
    expect(controller.formatRuns, const [
      LineItemTextRun(start: 0, end: 11, bold: true),
    ]);
    controller.dispose();
  });

  test('collapsed bold toggle applies to the next typed text', () {
    final controller = RichTextEditingController(text: 'Survey');
    controller.selection = const TextSelection.collapsed(offset: 6);
    controller.toggleBold();

    controller.value = controller.value.copyWith(
      text: 'Survey work',
      selection: const TextSelection.collapsed(offset: 11),
    );
    expect(controller.formatRuns, const [
      LineItemTextRun(start: 6, end: 11, bold: true),
    ]);
    controller.dispose();
  });

  testWidgets('Ctrl+B and Ctrl+I format selected description text', (
    tester,
  ) async {
    final controller = RichTextEditingController(text: 'Survey work');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RichTextShortcuts(
            controller: controller,
            child: TextField(controller: controller),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 6);
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(controller.formatRuns, const [
      LineItemTextRun(start: 0, end: 6, bold: true),
    ]);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyI);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(controller.formatRuns, const [
      LineItemTextRun(start: 0, end: 6, bold: true, italic: true),
    ]);
    controller.dispose();
  });
}
