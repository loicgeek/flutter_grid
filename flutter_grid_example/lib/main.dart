import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/animated_screen.dart';
import 'screens/export_screen.dart';
import 'screens/features_screen.dart';
import 'screens/neero_clients_screen.dart';
import 'screens/selection_screen.dart';
import 'screens/simple_screen.dart';
import 'screens/shrink_wrap_screen.dart';
import 'screens/todos_screen.dart';

void main() {
  runApp(const GridExampleApp());
}

class GridExampleApp extends StatelessWidget {
  const GridExampleApp({super.key});

  ThemeData _buildTheme(Brightness brightness) {
    final baseTheme = ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(baseTheme.textTheme),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_grid demo',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      home: const _Shell(),
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _index = 0;

  static const _tabs = [
    NavigationDestination(icon: Icon(Icons.table_rows), label: 'Basic'),
    NavigationDestination(icon: Icon(Icons.checklist), label: 'Selection'),
    NavigationDestination(icon: Icon(Icons.animation), label: 'Animated'),
    NavigationDestination(icon: Icon(Icons.download), label: 'Export'),
    NavigationDestination(icon: Icon(Icons.tune), label: 'Features'),
    NavigationDestination(
      icon: Icon(Icons.people_alt_outlined),
      label: 'Clients',
    ),
    NavigationDestination(
      icon: Icon(Icons.checklist_rounded),
      label: 'Todos',
    ),
    NavigationDestination(
      icon: Icon(Icons.unfold_more),
      label: 'Shrink',
    ),
  ];

  static const _screens = [
    SimpleScreen(),
    SelectionScreen(),
    AnimatedScreen(),
    ExportScreen(),
    FeaturesScreen(),
    NeeroClientsScreen(),
    TodosScreen(),
    ShrinkWrapScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _tabs,
      ),
    );
  }
}
