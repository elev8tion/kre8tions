import 'package:flutter/material.dart';
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/models/project_file.dart';
import 'package:kre8tions/models/custom_template.dart';

enum ProjectTemplate {
  basic('Basic App', 'Simple counter app with Material Design', Icons.apps),
  material('Material App', 'Rich Material 3 design with navigation', Icons.design_services),
  cupertino('Cupertino App', 'iOS-style app with native look', Icons.phone_iphone),
  responsive('Responsive Web App', 'Cross-platform responsive design', Icons.devices),
  listView('ListView Demo', 'App with dynamic lists and cards', Icons.list),
  navigation('Bottom Navigation', 'Multi-page app with bottom nav', Icons.navigation),
  ecommerce('E-Commerce Starter', 'Shopping app template with cart', Icons.shopping_cart),
  social('Social Media Feed', 'Feed-based social app template', Icons.people);

  const ProjectTemplate(this.title, this.description, this.icon);
  
  final String title;
  final String description;
  final IconData icon;
}

class ProjectTemplateService {
  // Storage for custom templates (in-memory for now)
  static final List<CustomTemplate> _customTemplates = [];
  
  // Get all available templates (built-in + custom)
  static List<dynamic> getAllTemplates() {
    final List<dynamic> allTemplates = [];
    
    // Add built-in templates
    allTemplates.addAll(ProjectTemplate.values);
    
    // Add custom templates
    allTemplates.addAll(_customTemplates);
    
    return allTemplates;
  }
  
  // Get custom templates only
  static List<CustomTemplate> getCustomTemplates() {
    return List.from(_customTemplates);
  }
  
  // Create a new custom template from a project
  static CustomTemplate createCustomTemplate({
    required String name,
    required String description,
    required IconData icon,
    required FlutterProject sourceProject,
    List<String> tags = const [],
  }) {
    final template = CustomTemplate(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      icon: icon,
      createdAt: DateTime.now(),
      sourceProject: sourceProject,
      tags: tags,
    );
    
    _customTemplates.add(template);
    return template;
  }
  
  // Delete a custom template
  static bool deleteCustomTemplate(String templateId) {
    final index = _customTemplates.indexWhere((t) => t.id == templateId);
    if (index != -1) {
      _customTemplates.removeAt(index);
      return true;
    }
    return false;
  }
  
  // Create project from any template (built-in or custom)
  static FlutterProject createFromAnyTemplate(dynamic template, String projectName) {
    if (template is ProjectTemplate) {
      return createFromTemplate(template, projectName);
    } else if (template is CustomTemplate) {
      return template.createProject(projectName);
    } else {
      throw ArgumentError('Invalid template type');
    }
  }
  static FlutterProject createFromTemplate(ProjectTemplate template, String projectName) {
    switch (template) {
      case ProjectTemplate.basic:
        return _createBasicApp(projectName);
      case ProjectTemplate.material:
        return _createMaterialApp(projectName);
      case ProjectTemplate.cupertino:
        return _createCupertinoApp(projectName);
      case ProjectTemplate.responsive:
        return _createResponsiveApp(projectName);
      case ProjectTemplate.listView:
        return _createListViewApp(projectName);
      case ProjectTemplate.navigation:
        return _createNavigationApp(projectName);
      case ProjectTemplate.ecommerce:
        return _createECommerceApp(projectName);
      case ProjectTemplate.social:
        return _createSocialApp(projectName);
    }
  }

  static FlutterProject _createBasicApp(String projectName) {
    final files = [
      ProjectFile(
        path: 'lib/main.dart',
        content: '''import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$projectName',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: '$projectName Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '\$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}''',
        type: FileType.dart,
      ),
      ..._getCommonFiles(projectName),
    ];

    return FlutterProject(
      name: projectName,
      files: files,
      uploadedAt: DateTime.now(),
    );
  }

  static FlutterProject _createMaterialApp(String projectName) {
    final files = [
      ProjectFile(
        path: 'lib/main.dart',
        content: '''import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$projectName',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}''',
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/screens/home_screen.dart',
        content: '''import 'package:flutter/material.dart';
import '../widgets/feature_card.dart';
import '../widgets/custom_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  static const List<Widget> _pages = <Widget>[
    _HomePage(),
    _ExplorePage(),
    _ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: '$projectName'),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.explore),
            icon: Icon(Icons.explore_outlined),
            label: 'Explore',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.person),
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to $projectName',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          const FeatureCard(
            title: 'Get Started',
            description: 'Begin your journey with our amazing features',
            icon: Icons.rocket_launch,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          const FeatureCard(
            title: 'Explore',
            description: 'Discover new content and possibilities',
            icon: Icons.explore,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          const FeatureCard(
            title: 'Settings',
            description: 'Customize your experience',
            icon: Icons.settings,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}

class _ExplorePage extends StatelessWidget {
  const _ExplorePage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Explore Page', style: TextStyle(fontSize: 24)),
          Text('Add your content here'),
        ],
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Profile Page', style: TextStyle(fontSize: 24)),
          Text('User profile content goes here'),
        ],
      ),
    );
  }
}''',
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/widgets/feature_card.dart',
        content: '''import 'package:flutter/material.dart';

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}''',
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/widgets/custom_app_bar.dart',
        content: '''import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}''',
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/theme/app_theme.dart',
        content: '''import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}''',
        type: FileType.dart,
      ),
      ..._getCommonFiles(projectName),
    ];

    return FlutterProject(
      name: projectName,
      files: files,
      uploadedAt: DateTime.now(),
    );
  }

  static FlutterProject _createCupertinoApp(String projectName) {
    final files = [
      ProjectFile(
        path: 'lib/main.dart',
        content: '''import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: '$projectName',
      theme: const CupertinoThemeData(
        primaryColor: CupertinoColors.systemBlue,
        brightness: Brightness.light,
      ),
      home: const HomeScreen(),
    );
  }
}''',
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/screens/home_screen.dart',
        content: '''import 'package:flutter/cupertino.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            label: 'Profile',
          ),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        return CupertinoTabView(
          builder: (BuildContext context) {
            switch (index) {
              case 0:
                return const _HomePage();
              case 1:
                return const _SearchPage();
              case 2:
                return const _ProfilePage();
              default:
                return const _HomePage();
            }
          },
        );
      },
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('$projectName'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'iOS-style app with Cupertino design',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _buildSettingsTile(
                      context,
                      'Notifications',
                      CupertinoIcons.bell,
                      () {},
                    ),
                    _buildSettingsTile(
                      context,
                      'Privacy',
                      CupertinoIcons.lock,
                      () {},
                    ),
                    _buildSettingsTile(
                      context,
                      'Account',
                      CupertinoIcons.person_circle,
                      () {},
                    ),
                    _buildSettingsTile(
                      context,
                      'About',
                      CupertinoIcons.info_circle,
                      () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: CupertinoListTile(
        leading: Icon(icon, color: CupertinoColors.systemBlue),
        title: Text(title),
        trailing: const Icon(CupertinoIcons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _SearchPage extends StatelessWidget {
  const _SearchPage();

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Search'),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.search,
              size: 80,
              color: CupertinoColors.secondaryLabel,
            ),
            SizedBox(height: 16),
            Text(
              'Search Page',
              style: TextStyle(fontSize: 24),
            ),
            Text('Add search functionality here'),
          ],
        ),
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Profile'),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.person_circle,
              size: 80,
              color: CupertinoColors.secondaryLabel,
            ),
            SizedBox(height: 16),
            Text(
              'Profile Page',
              style: TextStyle(fontSize: 24),
            ),
            Text('User profile content goes here'),
          ],
        ),
      ),
    );
  }
}''',
        type: FileType.dart,
      ),
      ..._getCommonFiles(projectName, isCupertino: true),
    ];

    return FlutterProject(
      name: projectName,
      files: files,
      uploadedAt: DateTime.now(),
    );
  }

  static FlutterProject _createResponsiveApp(String projectName) {
    final files = [
      ProjectFile(
        path: 'lib/main.dart',
        content: '''import 'package:flutter/material.dart';
import 'screens/responsive_home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$projectName',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const ResponsiveHome(),
    );
  }
}''',
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/screens/responsive_home.dart',
        content: '''import 'package:flutter/material.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/sidebar.dart';
import '../widgets/main_content.dart';

class ResponsiveHome extends StatefulWidget {
  const ResponsiveHome({super.key});

  @override
  State<ResponsiveHome> createState() => _ResponsiveHomeState();
}

class _ResponsiveHomeState extends State<ResponsiveHome> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveLayout.isMobile(context)
          ? AppBar(
              title: const Text('$projectName'),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            )
          : null,
      drawer: ResponsiveLayout.isMobile(context)
          ? Sidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) {
                setState(() => _selectedIndex = index);
                Navigator.of(context).pop();
              },
            )
          : null,
      body: ResponsiveLayout(
        mobile: MainContent(selectedIndex: _selectedIndex),
        tablet: Row(
          children: [
            SizedBox(
              width: 250,
              child: Sidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: (index) => setState(() => _selectedIndex = index),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: MainContent(selectedIndex: _selectedIndex)),
          ],
        ),
        desktop: Row(
          children: [
            SizedBox(
              width: 300,
              child: Sidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: (index) => setState(() => _selectedIndex = index),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: MainContent(selectedIndex: _selectedIndex)),
          ],
        ),
      ),
    );
  }
}''',
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/widgets/responsive_layout.dart',
        content: '''import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  });

  final Widget mobile;
  final Widget tablet;
  final Widget desktop;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 768 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return desktop;
        } else if (constraints.maxWidth >= 768) {
          return tablet;
        } else {
          return mobile;
        }
      },
    );
  }
}''',
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/widgets/sidebar.dart',
        content: '''import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  final int selectedIndex;
  final Function(int) onItemSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          if (!Scaffold.of(context).hasAppBar)
            Container(
              height: 80,
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '$projectName',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _buildSidebarItem(
                  context,
                  0,
                  Icons.dashboard,
                  'Dashboard',
                ),
                _buildSidebarItem(
                  context,
                  1,
                  Icons.analytics,
                  'Analytics',
                ),
                _buildSidebarItem(
                  context,
                  2,
                  Icons.people,
                  'Users',
                ),
                _buildSidebarItem(
                  context,
                  3,
                  Icons.settings,
                  'Settings',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    int index,
    IconData icon,
    String title,
  ) {
    final isSelected = selectedIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: () => onItemSelected(index),
      ),
    );
  }
}''',
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/widgets/main_content.dart',
        content: '''import 'package:flutter/material.dart';

class MainContent extends StatelessWidget {
  const MainContent({
    super.key,
    required this.selectedIndex,
  });

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getPageTitle(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _buildPageContent(context),
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Analytics';
      case 2:
        return 'Users';
      case 3:
        return 'Settings';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildPageContent(BuildContext context) {
    switch (selectedIndex) {
      case 0:
        return _buildDashboard(context);
      case 1:
        return _buildAnalytics(context);
      case 2:
        return _buildUsers(context);
      case 3:
        return _buildSettings(context);
      default:
        return _buildDashboard(context);
    }
  }

  Widget _buildDashboard(BuildContext context) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildDashboardCard(
          context,
          'Total Users',
          '1,234',
          Icons.people,
          Colors.blue,
        ),
        _buildDashboardCard(
          context,
          'Revenue',
          '\\\$12,345',
          Icons.monetization_on,
          Colors.green,
        ),
        _buildDashboardCard(
          context,
          'Orders',
          '567',
          Icons.shopping_cart,
          Colors.orange,
        ),
        _buildDashboardCard(
          context,
          'Growth',
          '+12%',
          Icons.trending_up,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalytics(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Analytics Page', style: TextStyle(fontSize: 24)),
          Text('Add charts and graphs here'),
        ],
      ),
    );
  }

  Widget _buildUsers(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Users Page', style: TextStyle(fontSize: 24)),
          Text('User management interface goes here'),
        ],
      ),
    );
  }

  Widget _buildSettings(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Settings Page', style: TextStyle(fontSize: 24)),
          Text('Application settings go here'),
        ],
      ),
    );
  }
}''',
        type: FileType.dart,
      ),
      ..._getCommonFiles(projectName),
    ];

    return FlutterProject(
      name: projectName,
      files: files,
      uploadedAt: DateTime.now(),
    );
  }

  static FlutterProject _createListViewApp(String projectName) {
    final files = [
      ProjectFile(
        path: 'lib/main.dart',
        content: '''import 'package:flutter/material.dart';
import 'screens/item_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$projectName',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ItemListScreen(),
    );
  }
}''',
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/screens/item_list_screen.dart',
        content: '''import 'package:flutter/material.dart';
import '../models/item.dart';
import '../widgets/item_card.dart';
import '../widgets/search_bar.dart' as custom;

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  List<Item> _items = [];
  List<Item> _filteredItems = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSampleData();
  }

  void _loadSampleData() {
    _items = [
      Item(
        id: '1',
        title: 'Flutter Development',
        description: 'Learn to build beautiful cross-platform apps',
        imageUrl: 'https://picsum.photos/300/200?random=1',
        price: 49.99,
        category: 'Technology',
      ),
      Item(
        id: '2',
        title: 'UI/UX Design',
        description: 'Master the art of user interface design',
        imageUrl: 'https://picsum.photos/300/200?random=2',
        price: 39.99,
        category: 'Design',
      ),
      Item(
        id: '3',
        title: 'Mobile Photography',
        description: 'Capture stunning photos with your smartphone',
        imageUrl: 'https://picsum.photos/300/200?random=3',
        price: 29.99,
        category: 'Photography',
      ),
      Item(
        id: '4',
        title: 'Digital Marketing',
        description: 'Grow your business online with proven strategies',
        imageUrl: 'https://picsum.photos/300/200?random=4',
        price: 59.99,
        category: 'Business',
      ),
      Item(
        id: '5',
        title: 'Data Science',
        description: 'Analyze data and build machine learning models',
        imageUrl: 'https://picsum.photos/300/200?random=5',
        price: 79.99,
        category: 'Technology',
      ),
      Item(
        id: '6',
        title: 'Content Writing',
        description: 'Create engaging content that converts',
        imageUrl: 'https://picsum.photos/300/200?random=6',
        price: 34.99,
        category: 'Writing',
      ),
    ];
    _filteredItems = _items;
  }

  void _filterItems(String query) {
    setState(() {
      _searchQuery = query;
      _filteredItems = _items
          .where((item) =>
              item.title.toLowerCase().contains(query.toLowerCase()) ||
              item.description.toLowerCase().contains(query.toLowerCase()) ||
              item.category.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$projectName'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: custom.SearchBar(
              onSearchChanged: _filterItems,
            ),
          ),
          Expanded(
            child: _filteredItems.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      return ItemCard(
                        item: _filteredItems[index],
                        onTap: () => _showItemDetails(_filteredItems[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewItem,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No items found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search query',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  void _showItemDetails(Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(item.description),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(label: Text(item.category)),
                Text(
                  '\\\${item.price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added \${item.title} to cart')),
              );
            },
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    final categories = _items.map((e) => e.category).toSet().toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: categories
              .map((category) => ListTile(
                    title: Text(category),
                    onTap: () {
                      Navigator.of(context).pop();
                      _filterByCategory(category);
                    },
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _filteredItems = _items;
              });
            },
            child: const Text('Show All'),
          ),
        ],
      ),
    );
  }

  void _filterByCategory(String category) {
    setState(() {
      _filteredItems = _items.where((item) => item.category == category).toList();
    });
  }

  void _addNewItem() {
    // Simulate adding a new item
    final newItem = Item(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Item \${_items.length + 1}',
      description: 'This is a new item added to the list',
      imageUrl: 'https://picsum.photos/300/200?random=\${_items.length + 10}',
      price: 19.99 + (_items.length * 5),
      category: 'New',
    );
    
    setState(() {
      _items.add(newItem);
      _filteredItems = _items;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('New item added!')),
    );
  }
}''',
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/models/item.dart',
        content: '''class Item {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double price;
  final String category;

  Item({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.category,
  });
}''',
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/widgets/item_card.dart',
        content: '''import 'package:flutter/material.dart';
import '../models/item.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final Item item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
                          label: Text(
                            item.category,
                            style: const TextStyle(fontSize: 12),
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        Text(
                          '\\\${item.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}''',
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/widgets/search_bar.dart',
        content: '''import 'package:flutter/material.dart';

class SearchBar extends StatefulWidget {
  const SearchBar({
    super.key,
    required this.onSearchChanged,
    this.hintText = 'Search items...',
  });

  final Function(String) onSearchChanged;
  final String hintText;

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onSearchChanged,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  widget.onSearchChanged('');
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}''',
        type: FileType.dart,
      ),
      ..._getCommonFiles(projectName),
    ];

    return FlutterProject(
      name: projectName,
      files: files,
      uploadedAt: DateTime.now(),
    );
  }

  static FlutterProject _createNavigationApp(String projectName) {
    final files = [
      ProjectFile(
        path: 'lib/main.dart',
        content: '''import 'package:flutter/material.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$projectName',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}''',
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/screens/main_screen.dart',
        content: '''import 'package:flutter/material.dart';
import 'home_tab.dart';
import 'explore_tab.dart';
import 'favorites_tab.dart';
import 'profile_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  static const List<Widget> _pages = <Widget>[
    HomeTab(),
    ExploreTab(),
    FavoritesTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.explore),
            icon: Icon(Icons.explore_outlined),
            label: 'Explore',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.favorite),
            icon: Icon(Icons.favorite_border),
            label: 'Favorites',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.person),
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}''',
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/screens/home_tab.dart',
        content: '''import 'package:flutter/material.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$projectName'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Here are your recent activities',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 24),
            _buildQuickActions(context),
            const SizedBox(height: 24),
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ..._buildActivityList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  'Create New',
                  Icons.add_circle_outline,
                  () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context,
                  'Share',
                  Icons.share_outlined,
                  () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context,
                  'Settings',
                  Icons.settings_outlined,
                  () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActivityList() {
    final activities = [
      {'title': 'Project completed', 'time': '2 hours ago', 'icon': Icons.check_circle},
      {'title': 'New message received', 'time': '4 hours ago', 'icon': Icons.message},
      {'title': 'Update available', 'time': '1 day ago', 'icon': Icons.system_update},
      {'title': 'Backup completed', 'time': '2 days ago', 'icon': Icons.backup},
    ];

    return activities.map((activity) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(
            activity['icon'] as IconData,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(activity['title'] as String),
          subtitle: Text(activity['time'] as String),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
      );
    }).toList();
  }
}''',
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/screens/explore_tab.dart',
        content: '''import 'package:flutter/material.dart';

class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Card(
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        Icons.star,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Item \${index + 1}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Description for item \${index + 1}',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}''',
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/screens/favorites_tab.dart',
        content: '''import 'package:flutter/material.dart';

class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.favorite,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Text('Favorite Item \${index + 1}'),
              subtitle: Text('Added \${index + 1} days ago'),
              trailing: const Icon(Icons.more_vert),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}''',
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/screens/profile_tab.dart',
        content: '''import 'package:flutter/material.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 50,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'John Doe',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'john.doe@example.com',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 32),
            _buildProfileOption(
              context,
              'Account Settings',
              Icons.settings,
              () {},
            ),
            _buildProfileOption(
              context,
              'Notifications',
              Icons.notifications,
              () {},
            ),
            _buildProfileOption(
              context,
              'Privacy',
              Icons.privacy_tip,
              () {},
            ),
            _buildProfileOption(
              context,
              'Help & Support',
              Icons.help,
              () {},
            ),
            _buildProfileOption(
              context,
              'About',
              Icons.info,
              () {},
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Sign Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}''',
        type: FileType.dart,
      ),
      ..._getCommonFiles(projectName),
    ];

    return FlutterProject(
      name: projectName,
      files: files,
      uploadedAt: DateTime.now(),
    );
  }

  static FlutterProject _createECommerceApp(String projectName) {
    final files = [
      ProjectFile(
        path: 'lib/main.dart',
        content: '''import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$projectName',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}''',
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/screens/home_screen.dart',
        content: '''import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = _getSampleProducts();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('$projectName'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          Badge(
            label: const Text('3'),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildCategoriesSection(context),
            _buildProductsSection(context, products),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,  // Flat surface - no gradient
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to $projectName!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover amazing products at great prices',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Shop Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    final categories = [
      {'name': 'Electronics', 'icon': Icons.phone_android},
      {'name': 'Fashion', 'icon': Icons.checkroom},
      {'name': 'Home', 'icon': Icons.home},
      {'name': 'Sports', 'icon': Icons.sports_soccer},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Categories',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        category['icon'] as IconData,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category['name'] as String,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductsSection(BuildContext context, List<Product> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Featured Products',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCard(product: products[index]);
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  List<Product> _getSampleProducts() {
    return [
      Product(
        id: '1',
        name: 'Wireless Headphones',
        description: 'High-quality wireless headphones with noise cancellation',
        price: 99.99,
        imageUrl: 'https://picsum.photos/300/300?random=1',
        category: 'Electronics',
      ),
      Product(
        id: '2',
        name: 'Running Shoes',
        description: 'Comfortable running shoes for daily exercise',
        price: 79.99,
        imageUrl: 'https://picsum.photos/300/300?random=2',
        category: 'Sports',
      ),
      Product(
        id: '3',
        name: 'Coffee Maker',
        description: 'Automatic coffee maker for perfect morning coffee',
        price: 149.99,
        imageUrl: 'https://picsum.photos/300/300?random=3',
        category: 'Home',
      ),
      Product(
        id: '4',
        name: 'Designer T-Shirt',
        description: 'Premium cotton t-shirt with modern design',
        price: 29.99,
        imageUrl: 'https://picsum.photos/300/300?random=4',
        category: 'Fashion',
      ),
      Product(
        id: '5',
        name: 'Smartphone',
        description: 'Latest smartphone with advanced camera features',
        price: 699.99,
        imageUrl: 'https://picsum.photos/300/300?random=5',
        category: 'Electronics',
      ),
      Product(
        id: '6',
        name: 'Yoga Mat',
        description: 'Non-slip yoga mat for comfortable workouts',
        price: 39.99,
        imageUrl: 'https://picsum.photos/300/300?random=6',
        category: 'Sports',
      ),
    ];
  }
}''',
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/models/product.dart',
        content: '''class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final double? rating;
  final int? reviewCount;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.rating,
    this.reviewCount,
  });
}''',
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/widgets/product_card.dart',
        content: '''import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap ?? () => _showProductDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 40,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\\\${product.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        Icon(
                          Icons.add_shopping_cart,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(product.description),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(label: Text(product.category)),
                Text(
                  '\\\${product.price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added \${product.name} to cart')),
              );
            },
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }
}''',
        type: FileType.dart,
      ),
      ..._getCommonFiles(projectName),
    ];

    return FlutterProject(
      name: projectName,
      files: files,
      uploadedAt: DateTime.now(),
    );
  }

  static FlutterProject _createSocialApp(String projectName) {
    final files = [
      ProjectFile(
        path: 'lib/main.dart',
        content: '''import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$projectName',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}''',
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/screens/home_screen.dart',
        content: '''import 'package:flutter/material.dart';
import '../models/post.dart';
import '../widgets/post_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Post> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadSamplePosts();
  }

  void _loadSamplePosts() {
    _posts.addAll([
      Post(
        id: '1',
        authorName: 'Alice Johnson',
        authorAvatar: 'https://i.pravatar.cc/150?img=1',
        content: 'Just finished my morning workout! 💪 Ready to tackle the day ahead.',
        imageUrl: 'https://picsum.photos/400/300?random=1',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        likes: 42,
        comments: 8,
      ),
      Post(
        id: '2',
        authorName: 'Bob Smith',
        authorAvatar: 'https://i.pravatar.cc/150?img=2',
        content: 'Beautiful sunset from my balcony 🌅 Nature never fails to amaze me!',
        imageUrl: 'https://picsum.photos/400/300?random=2',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        likes: 87,
        comments: 15,
      ),
      Post(
        id: '3',
        authorName: 'Carol Wilson',
        authorAvatar: 'https://i.pravatar.cc/150?img=3',
        content: 'Trying out a new recipe today. Homemade pizza with fresh ingredients! 🍕',
        imageUrl: 'https://picsum.photos/400/300?random=3',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        likes: 124,
        comments: 23,
      ),
      Post(
        id: '4',
        authorName: 'David Brown',
        authorAvatar: 'https://i.pravatar.cc/150?img=4',
        content: 'Weekend coding session with Flutter. Building something amazing! 🚀',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        likes: 156,
        comments: 31,
      ),
      Post(
        id: '5',
        authorName: 'Eva Martinez',
        authorAvatar: 'https://i.pravatar.cc/150?img=5',
        content: 'Coffee shop vibes ☕️ Perfect place to read a good book and relax.',
        imageUrl: 'https://picsum.photos/400/300?random=5',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        likes: 73,
        comments: 12,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$projectName'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: ListView.builder(
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            return PostWidget(
              post: _posts[index],
              onLike: () => _toggleLike(_posts[index]),
              onComment: () => _showComments(_posts[index]),
              onShare: () => _sharePost(_posts[index]),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewPost,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _refreshPosts() async {
    await Future.delayed(const Duration(seconds: 1));
    // Simulate loading new posts
    setState(() {
      // In a real app, you would fetch new posts from an API
    });
  }

  void _toggleLike(Post post) {
    setState(() {
      post.isLiked = !post.isLiked;
      if (post.isLiked) {
        post.likes++;
      } else {
        post.likes--;
      }
    });
  }

  void _showComments(Post post) {
    showBottomSheet(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comments',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: 3, // Sample comments
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        'https://i.pravatar.cc/150?img=\${index + 10}',
                      ),
                    ),
                    title: Text('User \${index + 1}'),
                    subtitle: const Text('This is a sample comment!'),
                    trailing: Text(
                      '\${index + 1}h',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Row(
              children: [
                const CircleAvatar(
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=99'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sharePost(Post post) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shared post by \${post.authorName}'),
      ),
    );
  }

  void _createNewPost() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Post'),
        content: const TextField(
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'What\\'s on your mind?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post created!')),
              );
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}''',
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/models/post.dart',
        content: '''class Post {
  final String id;
  final String authorName;
  final String authorAvatar;
  final String content;
  final String? imageUrl;
  final DateTime timestamp;
  int likes;
  final int comments;
  bool isLiked;

  Post({
    required this.id,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    this.imageUrl,
    required this.timestamp,
    required this.likes,
    required this.comments,
    this.isLiked = false,
  });
}''',
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/widgets/post_widget.dart',
        content: '''import 'package:flutter/material.dart';
import '../models/post.dart';

class PostWidget extends StatelessWidget {
  const PostWidget({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  final Post post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPostHeader(context),
            const SizedBox(height: 12),
            _buildPostContent(context),
            if (post.imageUrl != null) ...[
              const SizedBox(height: 12),
              _buildPostImage(context),
            ],
            const SizedBox(height: 12),
            _buildPostActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPostHeader(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage(post.authorAvatar),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.authorName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                _formatTimestamp(post.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildPostContent(BuildContext context) {
    return Text(
      post.content,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _buildPostImage(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        post.imageUrl!,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: 200,
            color: Colors.grey[300],
            child: const Icon(Icons.image_not_supported),
          );
        },
      ),
    );
  }

  Widget _buildPostActions(BuildContext context) {
    return Row(
      children: [
        _buildActionButton(
          context,
          icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
          label: post.likes.toString(),
          onPressed: onLike,
          color: post.isLiked ? Colors.red : null,
        ),
        const SizedBox(width: 16),
        _buildActionButton(
          context,
          icon: Icons.comment_outlined,
          label: post.comments.toString(),
          onPressed: onComment,
        ),
        const SizedBox(width: 16),
        _buildActionButton(
          context,
          icon: Icons.share_outlined,
          label: 'Share',
          onPressed: onShare,
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.bookmark_border),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    Color? color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '\${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '\${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '\${difference.inDays}d';
    } else {
      return '\${timestamp.day}/\${timestamp.month}/\${timestamp.year}';
    }
  }
}''',
        type: FileType.dart,
      ),
      ..._getCommonFiles(projectName),
    ];

    return FlutterProject(
      name: projectName,
      files: files,
      uploadedAt: DateTime.now(),
    );
  }

  static List<ProjectFile> _getCommonFiles(String projectName, {bool isCupertino = false}) {
    return [
      ProjectFile(
        path: 'pubspec.yaml',
        content: '''name: ${projectName.toLowerCase().replaceAll(' ', '_')}
description: $projectName - A Flutter application

publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.1.0 <4.0.0'
  flutter: ">=3.13.0"

dependencies:
  flutter:
    sdk: flutter
  ${isCupertino ? '' : 'material_color_utilities: ^0.5.0'}
  cupertino_icons: ^1.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  
  # To add assets to your application, add an assets section, like this:
  # assets:
  #   - images/a_dot_burr.jpeg
  #   - images/a_dot_ham.jpeg

  # To add custom fonts to your application, add a fonts section here,
  # in this "flutter" section. Each entry in this list should have a
  # "family" key with the font family name, and a "fonts" key with a
  # list giving the asset and other descriptors for the font.
  # fonts:
  #   - family: Schyler
  #     fonts:
  #       - asset: fonts/Schyler-Regular.ttf
  #       - asset: fonts/Schyler-Italic.ttf
  #         style: italic''',
        type: FileType.yaml,
      ),
      ProjectFile(
        path: 'README.md',
        content: '''# $projectName

A new Flutter project created with CodeWhisper templates.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Features

- Modern Flutter architecture
- Material 3 design system
- Responsive layouts
- Sample data for testing

## How to Run

1. Ensure you have Flutter installed
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the application

Created with ❤️ using CodeWhisper IDE
''',
        type: FileType.other,
      ),
      ProjectFile(
        path: 'analysis_options.yaml',
        content: '''include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    avoid_unnecessary_containers: true
    use_key_in_widget_constructors: true
''',
        type: FileType.yaml,
      ),
    ];
  }
}