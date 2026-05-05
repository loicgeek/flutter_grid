import 'package:flutter/material.dart';
import 'package:flutter_grid_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders the shell with navigation bar', (tester) async {
    await tester.pumpWidget(const GridExampleApp());
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Basic'), findsOneWidget);
    expect(find.text('Selection'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);
  });
}
