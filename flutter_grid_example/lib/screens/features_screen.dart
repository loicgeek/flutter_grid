import 'package:flutter/material.dart';
import 'package:flutter_grid/flutter_grid.dart';

import '../data/employee.dart';

/// Showcases: column pinning, fill-width, custom cells, column chooser,
/// striped rows, row height, and custom theme.
class FeaturesScreen extends StatefulWidget {
  const FeaturesScreen({super.key});

  @override
  State<FeaturesScreen> createState() => _FeaturesScreenState();
}

class _FeaturesScreenState extends State<FeaturesScreen>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Features'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pinning'),
            Tab(text: 'Custom Cells'),
            Tab(text: 'Theming'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PinningTab(),
          _CustomCellsTab(),
          _ThemingTab(),
        ],
      ),
    );
  }
}

// ── Pinning ────────────────────────────────────────────────────────────────

class _PinningTab extends StatefulWidget {
  const _PinningTab();

  @override
  State<_PinningTab> createState() => _PinningTabState();
}

class _PinningTabState extends State<_PinningTab> {
  late final _controller = GridController<Employee>(
    options: GridOptions(
      columns: [
        ColumnDef<Employee, String>.accessor(
          id: 'name',
          accessorFn: (e) => e.name,
          header: 'Name',
          size: 180,
          enablePinning: true,
        ),
        ColumnDef<Employee, String>.accessor(
          id: 'role',
          accessorFn: (e) => e.role,
          header: 'Role',
          size: 160,
          enablePinning: true,
        ),
        ColumnDef<Employee, String>.accessor(
          id: 'department',
          accessorFn: (e) => e.department.name,
          header: 'Department',
          size: 140,
        ),
        ColumnDef<Employee, double>.accessor(
          id: 'salary',
          accessorFn: (e) => e.salary,
          header: 'Salary',
          size: 120,
          columnType: ColumnType.money,
          textAlignIndex: 1,
        ),
        ColumnDef<Employee, int>.accessor(
          id: 'years',
          accessorFn: (e) => e.yearsAtCompany,
          header: 'Years',
          size: 80,
          columnType: ColumnType.number,
          textAlignIndex: 1,
        ),
        ColumnDef<Employee, double>.accessor(
          id: 'perf',
          accessorFn: (e) => e.performance,
          header: 'Perf.',
          size: 120,
          columnType: ColumnType.progress,
        ),
      ],
    ),
  )..setData(Employee.sample);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('Pin Name left'),
                onPressed: () =>
                    _controller.pinColumn('name', ColumnPinPosition.left),
              ),
              ActionChip(
                label: const Text('Unpin Name'),
                onPressed: () => _controller.unpinColumn('name'),
              ),
              ActionChip(
                label: const Text('Pin Salary right'),
                onPressed: () =>
                    _controller.pinColumn('salary', ColumnPinPosition.right),
              ),
              ActionChip(
                label: const Text('Unpin Salary'),
                onPressed: () => _controller.unpinColumn('salary'),
              ),
            ],
          ),
        ),
        Expanded(
          child: FlutterGrid<Employee>(
            controller: _controller,
            fillWidth: true,
            showToolbar: true,
            showFilterBar: false,
            showPagination: false,
          ),
        ),
      ],
    );
  }
}

// ── Custom Cells ───────────────────────────────────────────────────────────

class _CustomCellsTab extends StatefulWidget {
  const _CustomCellsTab();

  @override
  State<_CustomCellsTab> createState() => _CustomCellsTabState();
}

class _CustomCellsTabState extends State<_CustomCellsTab> {
  late final _controller = GridController<Employee>(
    options: GridOptions(
      columns: [
        ColumnDef<Employee, String>.accessor(
          id: 'name',
          accessorFn: (e) => e.name,
          header: 'Employee',
          size: 200,
          cell: (ctx) {
            final emp =
                (ctx as CellContext).cell.row.original as Employee;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor:
                      _deptColor(emp.department).withValues(alpha: 0.2),
                  child: Text(
                    emp.name[0],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _deptColor(emp.department),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(emp.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                      Text(emp.email,
                          style: const TextStyle(fontSize: 11),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        ColumnDef<Employee, String>.accessor(
          id: 'dept',
          accessorFn: (e) => e.department.name,
          header: 'Department',
          size: 130,
          cell: (ctx) {
            final emp =
                (ctx as CellContext).cell.row.original as Employee;
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _deptColor(emp.department).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                emp.department.name,
                style: TextStyle(
                  color: _deptColor(emp.department),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
        ColumnDef<Employee, double>.accessor(
          id: 'perf',
          accessorFn: (e) => e.performance,
          header: 'Performance',
          size: 150,
          cell: (ctx) {
            final value = (ctx as CellContext).cell.value as double? ?? 0.0;
            final color = value >= 0.9
                ? Colors.green
                : value >= 0.7
                    ? Colors.orange
                    : Colors.red;
            return Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: value,
                      backgroundColor: color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text('${(value * 100).round()}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ],
            );
          },
        ),
        ColumnDef<Employee, bool>.accessor(
          id: 'active',
          accessorFn: (e) => e.isActive,
          header: 'Status',
          size: 90,
          textAlignIndex: 2,
          cell: (ctx) {
            final active = (ctx as CellContext).cell.value as bool? ?? false;
            return Chip(
              label: Text(active ? 'Active' : 'Inactive',
                  style: const TextStyle(fontSize: 11)),
              backgroundColor: active
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.15),
              side: BorderSide.none,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            );
          },
        ),
      ],
    ),
  )..setData(Employee.sample);

  Color _deptColor(Department d) => switch (d) {
        Department.engineering => Colors.blue,
        Department.product => Colors.purple,
        Department.design => Colors.pink,
        Department.marketing => Colors.orange,
        Department.sales => Colors.green,
        Department.support => Colors.teal,
      };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterGrid<Employee>(
      controller: _controller,
      fillWidth: true,
      showToolbar: false,
      showFilterBar: false,
      showPagination: false,
      rowHeight: 64,
    );
  }
}

Color _deptColor(Department d) => switch (d) {
      Department.engineering => Colors.blue,
      Department.product => Colors.purple,
      Department.design => Colors.pink,
      Department.marketing => Colors.orange,
      Department.sales => Colors.green,
      Department.support => Colors.teal,
    };

// ── Theming ────────────────────────────────────────────────────────────────

class _ThemingTab extends StatefulWidget {
  const _ThemingTab();

  @override
  State<_ThemingTab> createState() => _ThemingTabState();
}

class _ThemingTabState extends State<_ThemingTab> {
  late final _controller = GridController<Employee>(
    options: GridOptions(
      columns: [
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
        ColumnDef<Employee, double>.accessor(
          id: 'salary',
          accessorFn: (e) => e.salary,
          header: 'Salary',
          size: 120,
          columnType: ColumnType.money,
          textAlignIndex: 1,
        ),
      ],
    ),
  )..setData(Employee.sample);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridTheme(
      data: GridThemeData(
        headerBackground: const Color(0xFF1E1E2E),
        headerForeground: const Color(0xFFCDD6F4),
        rowBackground: const Color(0xFF313244),
        alternateRowBackground: const Color(0xFF1E1E2E),
        selectedRowBackground: const Color(0xFF45475A),
        hoverRowBackground: const Color(0xFF585B70),
        borderColor: const Color(0xFF45475A),
        headerTextStyle: const TextStyle(
          color: Color(0xFFCDD6F4),
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        cellTextStyle: const TextStyle(
          color: Color(0xFFCDD6F4),
          fontSize: 13,
        ),
        rowHeight: 48,
        headerHeight: 44,
      ),
      child: FlutterGrid<Employee>(
        controller: _controller,
        fillWidth: true,
        showToolbar: false,
        showFilterBar: false,
        showPagination: false,
        striped: true,
        showColumnBorders: true,
      ),
    );
  }
}
