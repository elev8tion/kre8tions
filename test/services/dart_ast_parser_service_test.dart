import 'package:flutter_test/flutter_test.dart';
import 'package:kre8tions/services/dart_ast_parser_service.dart';
import 'package:kre8tions/services/code_execution_service.dart';

void main() {
  late DartAstParserService parserService;

  setUp(() {
    parserService = DartAstParserService.instance;
  });

  group('DartASTParserService - Basic Parsing', () {
    test('should parse simple Container widget', () async {
      const code = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100.0,
      height: 200.0,
      color: Colors.blue,
    );
  }
}
''';

      final tree = await parserService.parseWidgetTree(code, 'test.dart');

      expect(tree, isNotNull);
      expect(tree!.name, 'Root');
      expect(tree.children.isNotEmpty, true);

      // Find Container widget
      final container = tree.children.firstWhere(
        (node) => node.name == 'Container',
        orElse: () => throw Exception('Container not found'),
      );

      expect(container.name, 'Container');
      expect(container.type, WidgetType.layout);
      expect(container.properties['width'], 100.0);
      expect(container.properties['height'], 200.0);
      expect(container.properties['color'], 'Colors.blue');
    });

    test('should parse nested Column > Text > Icon structure', () async {
      const code = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Hello World'),
        Icon(Icons.star),
      ],
    );
  }
}
''';

      final tree = await parserService.parseWidgetTree(code, 'test.dart');

      expect(tree, isNotNull);
      expect(tree!.children.isNotEmpty, true);

      // Find Column widget
      final column = tree.children.firstWhere(
        (node) => node.name == 'Column',
        orElse: () => throw Exception('Column not found'),
      );

      expect(column.name, 'Column');
      expect(column.type, WidgetType.layout);
      expect(column.properties.containsKey('children'), true);
    });

    test('should parse ListView.builder pattern', () async {
      const code = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return Text('Item \$index');
      },
    );
  }
}
''';

      final tree = await parserService.parseWidgetTree(code, 'test.dart');

      expect(tree, isNotNull);
      expect(tree!.children.isNotEmpty, true);

      // Find ListView.builder
      final listView = tree.children.firstWhere(
        (node) => node.name.contains('ListView'),
        orElse: () => throw Exception('ListView not found'),
      );

      expect(listView.name, contains('ListView'));
      expect(listView.properties.containsKey('itemCount'), true);
      expect(listView.properties['itemCount'], 10);
    });

    test('should handle MaterialApp widget', () async {
      const code = '''
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(title: Text('Home')),
        body: Center(child: Text('Hello')),
      ),
    );
  }
}
''';

      final tree = await parserService.parseWidgetTree(code, 'test.dart');

      expect(tree, isNotNull);
      expect(tree!.children.isNotEmpty, true);

      // Find MaterialApp
      final materialApp = tree.children.firstWhere(
        (node) => node.name == 'MaterialApp',
        orElse: () => throw Exception('MaterialApp not found'),
      );

      expect(materialApp.name, 'MaterialApp');
      expect(materialApp.type, WidgetType.app);
      expect(materialApp.properties['title'], 'My App');
    });
  });

  group('DartASTParserService - Property Extraction', () {
    test('should extract string literal properties', () async {
      const code = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'Hello World',
      style: TextStyle(fontSize: 16.0),
    );
  }
}
''';

      final tree = await parserService.parseWidgetTree(code, 'test.dart');
      expect(tree, isNotNull);

      final text = tree!.children.firstWhere(
        (node) => node.name == 'Text',
        orElse: () => throw Exception('Text not found'),
      );

      // First positional argument becomes a property in some cases
      expect(text.properties.isNotEmpty, true);
    });

    test('should extract numeric literal properties', () async {
      const code = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100.0,
      height: 50,
    );
  }
}
''';

      final tree = await parserService.parseWidgetTree(code, 'test.dart');
      expect(tree, isNotNull);

      final sizedBox = tree!.children.firstWhere(
        (node) => node.name == 'SizedBox',
        orElse: () => throw Exception('SizedBox not found'),
      );

      expect(sizedBox.properties['width'], 100.0);
      expect(sizedBox.properties['height'], 50);
    });

    test('should extract boolean literal properties', () async {
      const code = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: true,
      readOnly: false,
    );
  }
}
''';

      final tree = await parserService.parseWidgetTree(code, 'test.dart');
      expect(tree, isNotNull);

      final textField = tree!.children.firstWhere(
        (node) => node.name == 'TextField',
        orElse: () => throw Exception('TextField not found'),
      );

      expect(textField.properties['enabled'], true);
      expect(textField.properties['readOnly'], false);
    });

    test('should extract named constant properties (Colors.blue)', () async {
      const code = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue,
    );
  }
}
''';

      final tree = await parserService.parseWidgetTree(code, 'test.dart');
      expect(tree, isNotNull);

      final container = tree!.children.firstWhere(
        (node) => node.name == 'Container',
        orElse: () => throw Exception('Container not found'),
      );

      expect(container.properties['color'], 'Colors.blue');
    });

    test('should extract constructor call properties (EdgeInsets.all)', () async {
      const code = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Text('Padded'),
    );
  }
}
''';

      final tree = await parserService.parseWidgetTree(code, 'test.dart');
      expect(tree, isNotNull);

      final padding = tree!.children.firstWhere(
        (node) => node.name == 'Padding',
        orElse: () => throw Exception('Padding not found'),
      );

      expect(padding.properties['padding'], contains('EdgeInsets.all(16.0)'));
    });

    test('should extract list literal properties', () async {
      const code = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('First'),
        Text('Second'),
      ],
    );
  }
}
''';

      final tree = await parserService.parseWidgetTree(code, 'test.dart');
      expect(tree, isNotNull);

      final column = tree!.children.firstWhere(
        (node) => node.name == 'Column',
        orElse: () => throw Exception('Column not found'),
      );

      expect(column.properties.containsKey('children'), true);
      expect(column.properties['children'], isList);
    });
  });

  group('DartASTParserService - Line Number Mapping', () {
    test('should preserve correct line numbers for widgets', () async {
      const code = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100.0,
    );
  }
}
''';

      final tree = await parserService.parseWidgetTree(code, 'test.dart');
      expect(tree, isNotNull);

      final container = tree!.children.firstWhere(
        (node) => node.name == 'Container',
        orElse: () => throw Exception('Container not found'),
      );

      // Container should be around line 6 (0-indexed might be 6 or 7)
      expect(container.line >= 5 && container.line <= 7, true);
    });

    test('should find widget at specific line number', () {
      const code = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100.0,
      height: 200.0,
    );
  }
}
''';

      // Container is on line 6
      final widget = parserService.findWidgetAtLine(code, 6);

      expect(widget, isNotNull);
      expect(widget!.widgetType, 'Container');
      expect(widget.lineNumber, 6);
      expect(widget.properties.isNotEmpty, true);
    });

    test('should find nested widget at specific line', () {
      const code = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Hello'),
        Container(width: 100),
      ],
    );
  }
}
''';

      // Text widget is on line 8
      final widget = parserService.findWidgetAtLine(code, 8);

      expect(widget, isNotNull);
      expect(widget!.widgetType, 'Text');
    });
  });

  group('DartASTParserService - Widget Type Classification', () {
    test('should classify layout widgets correctly', () {
      expect(parserService.classifyWidget('Container'), WidgetType.layout);
      expect(parserService.classifyWidget('Column'), WidgetType.layout);
      expect(parserService.classifyWidget('Row'), WidgetType.layout);
      expect(parserService.classifyWidget('Stack'), WidgetType.layout);
      expect(parserService.classifyWidget('Padding'), WidgetType.layout);
      expect(parserService.classifyWidget('ListView'), WidgetType.layout);
    });

    test('should classify input widgets correctly', () {
      expect(parserService.classifyWidget('TextField'), WidgetType.input);
      expect(parserService.classifyWidget('ElevatedButton'), WidgetType.input);
      expect(parserService.classifyWidget('Checkbox'), WidgetType.input);
      expect(parserService.classifyWidget('Switch'), WidgetType.input);
      expect(parserService.classifyWidget('FloatingActionButton'), WidgetType.input);
    });

    test('should classify display widgets correctly', () {
      expect(parserService.classifyWidget('Text'), WidgetType.display);
      expect(parserService.classifyWidget('Icon'), WidgetType.display);
      expect(parserService.classifyWidget('Image'), WidgetType.display);
      expect(parserService.classifyWidget('CircularProgressIndicator'), WidgetType.display);
    });

    test('should classify app widgets correctly', () {
      expect(parserService.classifyWidget('MaterialApp'), WidgetType.app);
      expect(parserService.classifyWidget('CupertinoApp'), WidgetType.app);
      expect(parserService.classifyWidget('WidgetsApp'), WidgetType.app);
    });

    test('should classify custom widgets as component', () {
      expect(parserService.classifyWidget('MyCustomWidget'), WidgetType.component);
      expect(parserService.classifyWidget('UserProfileCard'), WidgetType.component);
    });
  });

  group('DartASTParserService - Edge Cases', () {
    test('should handle empty widget tree', () async {
      const code = '''
import 'package:flutter/material.dart';

class EmptyWidget {
  void doSomething() {
    print('Not a widget');
  }
}
''';

      final tree = await parserService.parseWidgetTree(code, 'test.dart');

      expect(tree, isNotNull);
      expect(tree!.name, 'Root');
      expect(tree.children.isEmpty, true);
    });

    test('should handle syntax errors gracefully', () async {
      const code = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100.0,
      // Missing closing parenthesis
  }
}
''';

      final tree = await parserService.parseWidgetTree(code, 'test.dart');

      // Should still return a tree, even with errors
      expect(tree, isNotNull);
    });

    test('should handle conditional widgets', () async {
      const code = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  final bool showText;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: showText ? Text('Visible') : SizedBox.shrink(),
    );
  }
}
''';

      final tree = await parserService.parseWidgetTree(code, 'test.dart');

      expect(tree, isNotNull);
      expect(tree!.children.isNotEmpty, true);
    });

    test('should handle deeply nested widgets', () async {
      const code = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Container(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Deep'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
''';

      final tree = await parserService.parseWidgetTree(code, 'test.dart');

      expect(tree, isNotNull);
      expect(tree!.children.isNotEmpty, true);

      // Find Scaffold
      final scaffold = tree.children.firstWhere(
        (node) => node.name == 'Scaffold',
        orElse: () => throw Exception('Scaffold not found'),
      );

      expect(scaffold.name, 'Scaffold');
      expect(scaffold.type, WidgetType.layout);
    });

    test('should handle widgets with function properties', () async {
      const code = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => print('Pressed'),
      child: Text('Click Me'),
    );
  }
}
''';

      final tree = await parserService.parseWidgetTree(code, 'test.dart');

      expect(tree, isNotNull);

      final button = tree!.children.firstWhere(
        (node) => node.name == 'ElevatedButton',
        orElse: () => throw Exception('ElevatedButton not found'),
      );

      expect(button.properties.containsKey('onPressed'), true);
      expect(button.properties['onPressed'], contains('Function'));
    });

    test('should handle GridView and complex layouts', () async {
      const code = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      children: [
        Card(child: Text('1')),
        Card(child: Text('2')),
      ],
    );
  }
}
''';

      final tree = await parserService.parseWidgetTree(code, 'test.dart');

      expect(tree, isNotNull);
      expect(tree!.children.isNotEmpty, true);

      final gridView = tree.children.firstWhere(
        (node) => node.name.contains('GridView'),
        orElse: () => throw Exception('GridView not found'),
      );

      expect(gridView.name, contains('GridView'));
    });
  });

  group('DartASTParserService - Complex Scenarios', () {
    test('should handle Scaffold with AppBar and FloatingActionButton', () async {
      const code = '''
import 'package:flutter/material.dart';

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My App'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: Text('Hello World'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.add),
      ),
    );
  }
}
''';

      final tree = await parserService.parseWidgetTree(code, 'test.dart');

      expect(tree, isNotNull);
      expect(tree!.children.isNotEmpty, true);

      final scaffold = tree.children.firstWhere(
        (node) => node.name == 'Scaffold',
        orElse: () => throw Exception('Scaffold not found'),
      );

      expect(scaffold.name, 'Scaffold');
      expect(scaffold.properties.isNotEmpty, true);
    });

    test('should handle StatefulWidget with setState', () async {
      const code = '''
import 'package:flutter/material.dart';

class CounterWidget extends StatefulWidget {
  @override
  _CounterWidgetState createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Counter: \$_counter'),
        ElevatedButton(
          onPressed: () => setState(() => _counter++),
          child: Text('Increment'),
        ),
      ],
    );
  }
}
''';

      final tree = await parserService.parseWidgetTree(code, 'test.dart');

      expect(tree, isNotNull);
      expect(tree!.children.isNotEmpty, true);
    });

    test('should extract properties from widget with all property types', () async {
      const code = '''
import 'package:flutter/material.dart';

class ComplexWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100.0,
      height: 200,
      color: Colors.blue,
      padding: EdgeInsets.all(16.0),
      margin: EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text('Complex'),
    );
  }
}
''';

      final tree = await parserService.parseWidgetTree(code, 'test.dart');

      expect(tree, isNotNull);

      final container = tree!.children.firstWhere(
        (node) => node.name == 'Container',
        orElse: () => throw Exception('Container not found'),
      );

      expect(container.properties['width'], 100.0);
      expect(container.properties['height'], 200);
      expect(container.properties['color'], 'Colors.blue');
      expect(container.properties.containsKey('padding'), true);
      expect(container.properties.containsKey('margin'), true);
    });
  });
}
