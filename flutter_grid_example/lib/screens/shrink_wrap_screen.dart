import 'package:flutter/material.dart';
import 'package:ntech_grid/ntech_grid.dart';

import '../data/employee.dart';

/// Demonstrates embedding two grids inside a parent [SingleChildScrollView]
/// using [FlutterGrid.shrinkWrap].
///
/// Both grids size themselves to their content height so the page scrolls
/// as a whole instead of each table maintaining its own internal viewport.
class ShrinkWrapScreen extends StatefulWidget {
  const ShrinkWrapScreen({super.key});

  @override
  State<ShrinkWrapScreen> createState() => _ShrinkWrapScreenState();
}

class _ShrinkWrapScreenState extends State<ShrinkWrapScreen> {
  late final GridController<Employee> _activeController;
  late final GridController<Employee> _inactiveController;

  @override
  void initState() {
    super.initState();

    final active = Employee.sample.where((e) => e.isActive).toList();
    final inactive = Employee.sample.where((e) => !e.isActive).toList();

    _activeController = GridController<Employee>(
      options: GridOptions(
        columns: _columns(),
      ),
      initialState: const GridState(
        pagination: PaginationState(pageSize: 100),
      ),
    )..setData(active);

    _inactiveController = GridController<Employee>(
      options: GridOptions(
        columns: _columns(),
      ),
      initialState: const GridState(
        pagination: PaginationState(pageSize: 100),
      ),
    )..setData(inactive);
  }

  @override
  void dispose() {
    _activeController.dispose();
    _inactiveController.dispose();
    super.dispose();
  }

  List<ColumnDef<Employee, dynamic>> _columns() => [
        ColumnDef<Employee, String>.accessor(
          id: 'name',
          accessorFn: (e) => e.name,
          header: 'Name',
          size: 180,
        ),
        ColumnDef<Employee, String>.accessor(
          id: 'role',
          accessorFn: (e) => e.role,
          header: 'Role',
          size: 160,
        ),
        ColumnDef<Employee, String>.accessor(
          id: 'department',
          accessorFn: (e) => e.department.name,
          header: 'Department',
          size: 140,
          columnType: ColumnType.badge,
        ),
        ColumnDef<Employee, double>.accessor(
          id: 'salary',
          accessorFn: (e) => e.salary,
          header: 'Salary',
          size: 120,
          columnType: ColumnType.money,
          textAlignIndex: 1,
        ),
        ColumnDef<Employee, double>.accessor(
          id: 'performance',
          accessorFn: (e) => e.performance,
          header: 'Performance',
          size: 140,
          columnType: ColumnType.progress,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Shrink Wrap')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: 'Active employees',
              subtitle: 'Both grids live inside a SingleChildScrollView. '
                  'The page scrolls as a whole.',
              color: theme.colorScheme.primaryContainer,
            ),
            const SizedBox(height: 8),
            Card(
              clipBehavior: Clip.antiAlias,
              child: FlutterGrid<Employee>(
                controller: _activeController,
                shrinkWrap: true,
                fillWidth: true,
                striped: true,
                showToolbar: false,
                showFilterBar: false,
                showPagination: false,
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Inactive employees',
              color: theme.colorScheme.secondaryContainer,
            ),
            const SizedBox(height: 8),
            Card(
              clipBehavior: Clip.antiAlias,
              child: FlutterGrid<Employee>(
                controller: _inactiveController,
                shrinkWrap: true,
                fillWidth: true,
                striped: true,
                showToolbar: false,
                showFilterBar: false,
                showPagination: false,
              ),
            ),
            const SizedBox(height: 24),
            _InfoCard(
              title: 'How it works',
              body: 'Setting shrinkWrap: true on FlutterGrid disables '
                  'the internal scroll view and sizes the table to its '
                  'content height. The sticky header is also disabled so '
                  'the parent scroll view controls the viewport.',
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color color;

  const _SectionHeader({
    required this.title,
    this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String body;

  const _InfoCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(body, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
