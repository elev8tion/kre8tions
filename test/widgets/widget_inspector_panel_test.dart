import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kre8tions/widgets/widget_inspector_panel.dart';
import 'package:kre8tions/models/widget_selection.dart';

void main() {
  group('WidgetInspectorPanel', () {
    late WidgetSelection testSelection;
    final List<Map<String, dynamic>> propertyChanges = [];

    setUp(() {
      testSelection = const WidgetSelection(
        widgetType: 'FloatingActionButton',
        widgetId: 'test_fab_1',
        filePath: '/test/main.dart',
        lineNumber: 10,
        properties: {},
        sourceCode: 'FloatingActionButton(onPressed: () {})',
      );
      propertyChanges.clear();
    });

    testFindsTabs() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WidgetInspectorPanel(
              selectedWidget: testSelection,
              onPropertyChanged: (property, value) {
                propertyChanges.add({'property': property, 'value': value});
              },
              onClose: () {},
            ),
          ),
        ),
      );

      // Verify all 6 tabs are present
      expect(find.text('Style'), findsOneWidget);
      expect(find.text('Layout'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
      expect(find.text('Constructor'), findsOneWidget);
      expect(find.text('Interaction'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);
    });

    testWidgetInspector('displays all 6 tabs', testFindsTabs);

    testWidgetInspector('Constructor tab shows widget type', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WidgetInspectorPanel(
              selectedWidget: testSelection,
              onPropertyChanged: (property, value) {
                propertyChanges.add({'property': property, 'value': value});
              },
              onClose: () {},
            ),
          ),
        ),
      );

      // Tap on Constructor tab
      await tester.tap(find.text('Constructor'));
      await tester.pumpAndSettle();

      // Verify widget type is displayed
      expect(find.text('FloatingActionButton'), findsOneWidget);
    });

    testWidgetInspector('Advanced tab shows alignment picker', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WidgetInspectorPanel(
              selectedWidget: testSelection,
              onPropertyChanged: (property, value) {
                propertyChanges.add({'property': property, 'value': value});
              },
              onClose: () {},
            ),
          ),
        ),
      );

      // Tap on Advanced tab (6th tab, index 5)
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();

      // Verify alignment picker is present
      expect(find.text('Visual Alignment Picker'), findsOneWidget);
      expect(find.text('Alignment'), findsOneWidget);
    });

    testWidgetInspector('Container widget shows schema-based properties', (WidgetTester tester) async {
      final containerSelection = const WidgetSelection(
        widgetType: 'Container',
        widgetId: 'test_container_1',
        filePath: '/test/main.dart',
        lineNumber: 15,
        properties: {},
        sourceCode: 'Container(child: Text("Test"))',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WidgetInspectorPanel(
              selectedWidget: containerSelection,
              onPropertyChanged: (property, value) {
                propertyChanges.add({'property': property, 'value': value});
              },
              onClose: () {},
            ),
          ),
        ),
      );

      // Tap on Constructor tab
      await tester.tap(find.text('Constructor'));
      await tester.pumpAndSettle();

      // Verify Container-specific properties are shown
      expect(find.text('child'), findsWidgets); // Container has child property
      expect(find.text('width'), findsWidgets);
      expect(find.text('height'), findsWidgets);
    });

    testWidgetInspector('Advanced tab shows constraints editor', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WidgetInspectorPanel(
              selectedWidget: testSelection,
              onPropertyChanged: (property, value) {
                propertyChanges.add({'property': property, 'value': value});
              },
              onClose: () {},
            ),
          ),
        ),
      );

      // Tap on Advanced tab
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();

      // Verify constraints section is present
      expect(find.text('Constraints'), findsOneWidget);
      expect(find.text('Min Width'), findsOneWidget);
      expect(find.text('Max Width'), findsOneWidget);
      expect(find.text('Min Height'), findsOneWidget);
      expect(find.text('Max Height'), findsOneWidget);
    });

    testWidgetInspector('Advanced tab shows transform controls', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WidgetInspectorPanel(
              selectedWidget: testSelection,
              onPropertyChanged: (property, value) {
                propertyChanges.add({'property': property, 'value': value});
              },
              onClose: () {},
            ),
          ),
        ),
      );

      // Tap on Advanced tab
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();

      // Verify transform section is present
      expect(find.text('Transform'), findsOneWidget);
      expect(find.text('Rotation'), findsOneWidget);
      expect(find.text('Scale'), findsOneWidget);
    });

    testWidgetInspector('Interaction tab shows event handlers for schema widgets', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WidgetInspectorPanel(
              selectedWidget: testSelection,
              onPropertyChanged: (property, value) {
                propertyChanges.add({'property': property, 'value': value});
              },
              onClose: () {},
            ),
          ),
        ),
      );

      // Tap on Interaction tab
      await tester.tap(find.text('Interaction'));
      await tester.pumpAndSettle();

      // Verify event handlers section is present
      expect(find.text('Event Handlers'), findsOneWidget);
      // FloatingActionButton has onPressed in schema
      expect(find.text('onPressed *'), findsOneWidget);
    });
  });
}
