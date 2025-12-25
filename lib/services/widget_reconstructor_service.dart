import 'package:flutter/material.dart';
import 'package:kre8tions/services/code_execution_service.dart';

/// 🎨 **LIVE WIDGET RECONSTRUCTION SERVICE**
///
/// Converts WidgetTreeNode metadata into actual Flutter widgets
/// for real-time preview without screenshots or mocks.
class WidgetReconstructorService {
  static final WidgetReconstructorService _instance = WidgetReconstructorService._();
  static WidgetReconstructorService get instance => _instance;
  WidgetReconstructorService._();

  /// 🏗️ **RECONSTRUCT WIDGET TREE**
  /// Converts WidgetTreeNode hierarchy into live Flutter widgets
  Widget reconstructWidget(WidgetTreeNode node, {ThemeData? theme}) {
    theme ??= ThemeData.dark();

    switch (node.name) {
      case 'Root':
        return _buildRoot(node, theme);

      case 'MaterialApp':
        return _buildMaterialApp(node, theme);

      case 'Scaffold':
        return _buildScaffold(node, theme);

      case 'AppBar':
        return _buildAppBar(node, theme);

      case 'Container':
        return _buildContainer(node, theme);

      case 'Column':
        return _buildColumn(node, theme);

      case 'Row':
        return _buildRow(node, theme);

      case 'Text':
        return _buildText(node, theme);

      case 'Card':
        return _buildCard(node, theme);

      case 'ListView':
        return _buildListView(node, theme);

      case 'GridView':
        return _buildGridView(node, theme);

      case 'Stack':
        return _buildStack(node, theme);

      case 'Center':
        return _buildCenter(node, theme);

      case 'Padding':
        return _buildPadding(node, theme);

      case 'SizedBox':
        return _buildSizedBox(node, theme);

      case 'Expanded':
        return _buildExpanded(node, theme);

      case 'Flexible':
        return _buildFlexible(node, theme);

      case 'Align':
        return _buildAlign(node, theme);

      case 'ElevatedButton':
      case 'TextButton':
      case 'OutlinedButton':
        return _buildButton(node, theme);

      case 'TextField':
        return _buildTextField(node, theme);

      case 'Image':
        return _buildImage(node, theme);

      case 'Icon':
        return _buildIcon(node, theme);

      case 'Divider':
        return _buildDivider(node, theme);

      case 'CircularProgressIndicator':
        return _buildProgressIndicator(node, theme);

      default:
        return _buildUnknownWidget(node, theme);
    }
  }

  // 🏗️ **ROOT BUILDER**
  Widget _buildRoot(WidgetTreeNode node, ThemeData theme) {
    if (node.children.isEmpty) {
      return Container(
        color: theme.scaffoldBackgroundColor,
        child: Center(
          child: Text(
            'No widgets to preview',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    // If root has single child, render it directly
    if (node.children.length == 1) {
      return reconstructWidget(node.children.first, theme: theme);
    }

    // Multiple children - wrap in Column
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: node.children.map((child) {
          return Expanded(
            child: reconstructWidget(child, theme: theme),
          );
        }).toList(),
      ),
    );
  }

  // 🎨 **MATERIAL APP BUILDER**
  Widget _buildMaterialApp(WidgetTreeNode node, ThemeData theme) {
    final title = node.properties['title'] as String? ?? 'Flutter App';

    Widget home = Container();
    if (node.children.isNotEmpty) {
      home = reconstructWidget(node.children.first, theme: theme);
    }

    return MaterialApp(
      title: title,
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: home,
    );
  }

  // 🏗️ **SCAFFOLD BUILDER**
  Widget _buildScaffold(WidgetTreeNode node, ThemeData theme) {
    Widget? appBar;
    Widget? body;
    Widget? floatingActionButton;
    Widget? bottomNavigationBar;

    for (final child in node.children) {
      switch (child.name) {
        case 'AppBar':
          appBar = reconstructWidget(child, theme: theme) as PreferredSizeWidget?;
          break;
        case 'FloatingActionButton':
          floatingActionButton = reconstructWidget(child, theme: theme);
          break;
        case 'BottomNavigationBar':
          bottomNavigationBar = reconstructWidget(child, theme: theme);
          break;
        default:
          body = reconstructWidget(child, theme: theme);
      }
    }

    return Scaffold(
      appBar: appBar as PreferredSizeWidget?,
      body: body ?? Container(),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }

  // 📱 **APPBAR BUILDER**
  Widget _buildAppBar(WidgetTreeNode node, ThemeData theme) {
    final title = node.properties['title'] as String? ?? 'App';

    return AppBar(
      title: Text(title),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
    );
  }

  // 📦 **CONTAINER BUILDER**
  Widget _buildContainer(WidgetTreeNode node, ThemeData theme) {
    final width = node.properties['width'] as double?;
    final height = node.properties['height'] as double?;
    final color = _parseColor(node.properties['color'], theme.colorScheme.surface);
    final padding = _parseEdgeInsets(node.properties['padding']);
    final margin = _parseEdgeInsets(node.properties['margin']);

    Widget? child;
    if (node.children.isNotEmpty) {
      child = reconstructWidget(node.children.first, theme: theme);
    }

    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(
          node.properties['borderRadius'] as double? ?? 0,
        ),
      ),
      child: child,
    );
  }

  // 📊 **COLUMN BUILDER**
  Widget _buildColumn(WidgetTreeNode node, ThemeData theme) {
    final mainAxisAlignment = _parseMainAxisAlignment(
      node.properties['mainAxisAlignment'],
    );
    final crossAxisAlignment = _parseCrossAxisAlignment(
      node.properties['crossAxisAlignment'],
    );

    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: node.children
          .map((child) => reconstructWidget(child, theme: theme))
          .toList(),
    );
  }

  // ➡️ **ROW BUILDER**
  Widget _buildRow(WidgetTreeNode node, ThemeData theme) {
    final mainAxisAlignment = _parseMainAxisAlignment(
      node.properties['mainAxisAlignment'],
    );
    final crossAxisAlignment = _parseCrossAxisAlignment(
      node.properties['crossAxisAlignment'],
    );

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: node.children
          .map((child) => reconstructWidget(child, theme: theme))
          .toList(),
    );
  }

  // 📝 **TEXT BUILDER**
  Widget _buildText(WidgetTreeNode node, ThemeData theme) {
    final data = node.properties['data'] as String? ??
                 node.properties['text'] as String? ??
                 'Text';
    final fontSize = node.properties['fontSize'] as double? ?? 14.0;
    final fontWeight = _parseFontWeight(node.properties['fontWeight']);
    final color = _parseColor(node.properties['color'], theme.colorScheme.onSurface);

    return Text(
      data,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }

  // 🎴 **CARD BUILDER**
  Widget _buildCard(WidgetTreeNode node, ThemeData theme) {
    final elevation = node.properties['elevation'] as double? ?? 4.0;

    Widget? child;
    if (node.children.isNotEmpty) {
      child = reconstructWidget(node.children.first, theme: theme);
    }

    return Card(
      elevation: elevation,
      child: child,
    );
  }

  // 📜 **LISTVIEW BUILDER**
  Widget _buildListView(WidgetTreeNode node, ThemeData theme) {
    final itemCount = node.properties['itemCount'] as int? ??
                     node.children.length;

    if (node.children.isEmpty) {
      // Generate placeholder items
      return ListView.builder(
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.circle, color: theme.colorScheme.primary),
            title: Text('Item ${index + 1}'),
            subtitle: Text('List item description'),
          );
        },
      );
    }

    return ListView(
      children: node.children
          .map((child) => reconstructWidget(child, theme: theme))
          .toList(),
    );
  }

  // 🔲 **GRIDVIEW BUILDER**
  Widget _buildGridView(WidgetTreeNode node, ThemeData theme) {
    final crossAxisCount = node.properties['crossAxisCount'] as int? ?? 2;

    if (node.children.isEmpty) {
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.0,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Item ${index + 1}',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          );
        },
      );
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      children: node.children
          .map((child) => reconstructWidget(child, theme: theme))
          .toList(),
    );
  }

  // 📚 **STACK BUILDER**
  Widget _buildStack(WidgetTreeNode node, ThemeData theme) {
    return Stack(
      children: node.children
          .map((child) => reconstructWidget(child, theme: theme))
          .toList(),
    );
  }

  // 🎯 **CENTER BUILDER**
  Widget _buildCenter(WidgetTreeNode node, ThemeData theme) {
    Widget? child;
    if (node.children.isNotEmpty) {
      child = reconstructWidget(node.children.first, theme: theme);
    }

    return Center(child: child);
  }

  // 📏 **PADDING BUILDER**
  Widget _buildPadding(WidgetTreeNode node, ThemeData theme) {
    final padding = _parseEdgeInsets(node.properties['padding']) ??
                   const EdgeInsets.all(16.0);

    Widget? child;
    if (node.children.isNotEmpty) {
      child = reconstructWidget(node.children.first, theme: theme);
    }

    return Padding(
      padding: padding,
      child: child ?? Container(),
    );
  }

  // 📐 **SIZEDBOX BUILDER**
  Widget _buildSizedBox(WidgetTreeNode node, ThemeData theme) {
    final width = node.properties['width'] as double?;
    final height = node.properties['height'] as double?;

    Widget? child;
    if (node.children.isNotEmpty) {
      child = reconstructWidget(node.children.first, theme: theme);
    }

    return SizedBox(
      width: width,
      height: height,
      child: child,
    );
  }

  // ↔️ **EXPANDED BUILDER**
  Widget _buildExpanded(WidgetTreeNode node, ThemeData theme) {
    final flex = node.properties['flex'] as int? ?? 1;

    Widget? child;
    if (node.children.isNotEmpty) {
      child = reconstructWidget(node.children.first, theme: theme);
    }

    return Expanded(
      flex: flex,
      child: child ?? Container(),
    );
  }

  // 🔄 **FLEXIBLE BUILDER**
  Widget _buildFlexible(WidgetTreeNode node, ThemeData theme) {
    final flex = node.properties['flex'] as int? ?? 1;

    Widget? child;
    if (node.children.isNotEmpty) {
      child = reconstructWidget(node.children.first, theme: theme);
    }

    return Flexible(
      flex: flex,
      child: child ?? Container(),
    );
  }

  // 🎯 **ALIGN BUILDER**
  Widget _buildAlign(WidgetTreeNode node, ThemeData theme) {
    final alignment = _parseAlignment(node.properties['alignment']) ??
                     Alignment.center;

    Widget? child;
    if (node.children.isNotEmpty) {
      child = reconstructWidget(node.children.first, theme: theme);
    }

    return Align(
      alignment: alignment,
      child: child ?? Container(),
    );
  }

  // 🔘 **BUTTON BUILDER**
  Widget _buildButton(WidgetTreeNode node, ThemeData theme) {
    final text = node.properties['text'] as String? ?? 'Button';
    final onPressed = node.properties['onPressed'] != null ? () {} : null;

    switch (node.name) {
      case 'ElevatedButton':
        return ElevatedButton(
          onPressed: onPressed,
          child: Text(text),
        );
      case 'TextButton':
        return TextButton(
          onPressed: onPressed,
          child: Text(text),
        );
      case 'OutlinedButton':
        return OutlinedButton(
          onPressed: onPressed,
          child: Text(text),
        );
      default:
        return ElevatedButton(
          onPressed: onPressed,
          child: Text(text),
        );
    }
  }

  // ⌨️ **TEXTFIELD BUILDER**
  Widget _buildTextField(WidgetTreeNode node, ThemeData theme) {
    final hintText = node.properties['hintText'] as String? ?? '';
    final labelText = node.properties['labelText'] as String?;

    return TextField(
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
    );
  }

  // 🖼️ **IMAGE BUILDER**
  Widget _buildImage(WidgetTreeNode node, ThemeData theme) {
    final src = node.properties['src'] as String? ??
                node.properties['image'] as String?;

    if (src != null && src.startsWith('http')) {
      return Image.network(src, errorBuilder: (_, __, ___) {
        return Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.broken_image,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        );
      });
    }

    // Placeholder for local assets
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
      ),
    );
  }

  // 🎨 **ICON BUILDER**
  Widget _buildIcon(WidgetTreeNode node, ThemeData theme) {
    final iconName = node.properties['icon'] as String? ?? 'star';
    final color = _parseColor(node.properties['color'], theme.colorScheme.primary);
    final size = node.properties['size'] as double? ?? 24.0;

    return Icon(
      _parseIconData(iconName),
      color: color,
      size: size,
    );
  }

  // ➖ **DIVIDER BUILDER**
  Widget _buildDivider(WidgetTreeNode node, ThemeData theme) {
    return const Divider();
  }

  // ⏳ **PROGRESS INDICATOR BUILDER**
  Widget _buildProgressIndicator(WidgetTreeNode node, ThemeData theme) {
    return CircularProgressIndicator(
      color: theme.colorScheme.primary,
    );
  }

  // ❓ **UNKNOWN WIDGET BUILDER**
  Widget _buildUnknownWidget(WidgetTreeNode node, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.5),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning,
            color: theme.colorScheme.error,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Unknown Widget: ${node.name}',
            style: TextStyle(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (node.children.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...node.children.map((child) =>
              reconstructWidget(child, theme: theme)
            ),
          ],
        ],
      ),
    );
  }

  // 🛠️ **PARSING HELPERS**

  Color _parseColor(dynamic value, Color defaultColor) {
    if (value == null) return defaultColor;
    if (value is Color) return value;
    if (value is String) {
      try {
        if (value.startsWith('#')) {
          return Color(int.parse(value.substring(1), radix: 16) + 0xFF000000);
        } else if (value.startsWith('0x')) {
          return Color(int.parse(value));
        }
      } catch (e) {
        return defaultColor;
      }
    }
    return defaultColor;
  }

  EdgeInsets? _parseEdgeInsets(dynamic value) {
    if (value == null) return null;
    if (value is EdgeInsets) return value;
    if (value is num) return EdgeInsets.all(value.toDouble());
    if (value is Map) {
      final left = (value['left'] ?? 0).toDouble();
      final top = (value['top'] ?? 0).toDouble();
      final right = (value['right'] ?? 0).toDouble();
      final bottom = (value['bottom'] ?? 0).toDouble();
      return EdgeInsets.fromLTRB(left, top, right, bottom);
    }
    return null;
  }

  MainAxisAlignment _parseMainAxisAlignment(dynamic value) {
    if (value == null) return MainAxisAlignment.start;
    if (value is MainAxisAlignment) return value;
    switch (value.toString()) {
      case 'center':
        return MainAxisAlignment.center;
      case 'end':
        return MainAxisAlignment.end;
      case 'spaceBetween':
        return MainAxisAlignment.spaceBetween;
      case 'spaceAround':
        return MainAxisAlignment.spaceAround;
      case 'spaceEvenly':
        return MainAxisAlignment.spaceEvenly;
      default:
        return MainAxisAlignment.start;
    }
  }

  CrossAxisAlignment _parseCrossAxisAlignment(dynamic value) {
    if (value == null) return CrossAxisAlignment.center;
    if (value is CrossAxisAlignment) return value;
    switch (value.toString()) {
      case 'start':
        return CrossAxisAlignment.start;
      case 'end':
        return CrossAxisAlignment.end;
      case 'stretch':
        return CrossAxisAlignment.stretch;
      default:
        return CrossAxisAlignment.center;
    }
  }

  FontWeight _parseFontWeight(dynamic value) {
    if (value == null) return FontWeight.normal;
    if (value is FontWeight) return value;
    switch (value.toString()) {
      case 'bold':
        return FontWeight.bold;
      case 'w100':
        return FontWeight.w100;
      case 'w200':
        return FontWeight.w200;
      case 'w300':
        return FontWeight.w300;
      case 'w500':
        return FontWeight.w500;
      case 'w600':
        return FontWeight.w600;
      case 'w700':
        return FontWeight.w700;
      case 'w800':
        return FontWeight.w800;
      case 'w900':
        return FontWeight.w900;
      default:
        return FontWeight.normal;
    }
  }

  Alignment _parseAlignment(dynamic value) {
    if (value == null) return Alignment.center;
    if (value is Alignment) return value;
    switch (value.toString()) {
      case 'topLeft':
        return Alignment.topLeft;
      case 'topCenter':
        return Alignment.topCenter;
      case 'topRight':
        return Alignment.topRight;
      case 'centerLeft':
        return Alignment.centerLeft;
      case 'centerRight':
        return Alignment.centerRight;
      case 'bottomLeft':
        return Alignment.bottomLeft;
      case 'bottomCenter':
        return Alignment.bottomCenter;
      case 'bottomRight':
        return Alignment.bottomRight;
      default:
        return Alignment.center;
    }
  }

  IconData _parseIconData(String iconName) {
    // Map common icon names to IconData
    switch (iconName.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'star':
        return Icons.star;
      case 'favorite':
        return Icons.favorite;
      case 'settings':
        return Icons.settings;
      case 'search':
        return Icons.search;
      case 'menu':
        return Icons.menu;
      case 'add':
        return Icons.add;
      case 'edit':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'close':
        return Icons.close;
      case 'check':
        return Icons.check;
      case 'arrow_back':
        return Icons.arrow_back;
      case 'arrow_forward':
        return Icons.arrow_forward;
      case 'person':
        return Icons.person;
      case 'email':
        return Icons.email;
      case 'phone':
        return Icons.phone;
      default:
        return Icons.circle;
    }
  }
}
