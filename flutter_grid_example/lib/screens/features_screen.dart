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
  late final _tabController = TabController(length: 6, vsync: this);

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
          isScrollable: true,
          tabs: const [
            Tab(text: 'Pinning'),
            Tab(text: 'Custom Cells'),
            Tab(text: 'Theming'),
            Tab(text: 'Grouping'),
            Tab(text: 'Expanding'),
            Tab(text: 'Columns'),
          ],
        ),
      ),
      body: TabBarView(
        physics: NeverScrollableScrollPhysics(),
        controller: _tabController,
        children: const [
          _PinningTab(),
          _CustomCellsTab(),
          _ThemingTab(),
          _GroupingTab(),
          _ExpandingTab(),
          _ColumnsTab(),
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
          // size: 180,
          enablePinning: true,
        ),
        ColumnDef<Employee, String>.accessor(
          id: 'role',
          accessorFn: (e) => e.role,
          header: 'Role',
          // size: 160,
          enablePinning: true,
        ),
        ColumnDef<Employee, String>.accessor(
          id: 'department',
          accessorFn: (e) => e.department.name,
          header: 'Department',
          // size: 140,
        ),
        ColumnDef<Employee, double>.accessor(
          id: 'salary',
          accessorFn: (e) => e.salary,
          header: 'Salary',
          // size: 120,
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
          // size: 200,
          cell: (ctx) {
            final emp = (ctx as CellContext).cell.row.original as Employee;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: _deptColor(
                    emp.department,
                  ).withValues(alpha: 0.2),
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
                      Text(
                        emp.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        emp.email,
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
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
          // size: 130,
          cell: (ctx) {
            final emp = (ctx as CellContext).cell.row.original as Employee;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
          // size: 150,
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
                Text(
                  '${(value * 100).round()}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            );
          },
        ),
        ColumnDef<Employee, bool>.accessor(
          id: 'active',
          accessorFn: (e) => e.isActive,
          header: 'Status',
          // size: 90,
          textAlignIndex: 2,
          cell: (ctx) {
            final active = (ctx as CellContext).cell.value as bool? ?? false;
            return Chip(
              label: Text(
                active ? 'Active' : 'Inactive',
                style: const TextStyle(fontSize: 11),
              ),
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
          // size: 180,
        ),
        ColumnDef<Employee, String>.accessor(
          id: 'role',
          accessorFn: (e) => e.role,
          header: 'Role',
          // size: 160,
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
        cellTextStyle: const TextStyle(color: Color(0xFFCDD6F4), fontSize: 13),
        rowHeight: 48,
        headerHeight: 44,
      ),
      child: FlutterGrid<Employee>(
        controller: _controller,
        fillWidth: false,
        showToolbar: false,
        showFilterBar: false,
        showPagination: false,
        striped: true,
        showColumnBorders: true,
      ),
    );
  }
}

// ── Grouping ────────────────────────────────────────────────────────────────

class _GroupingTab extends StatefulWidget {
  const _GroupingTab();

  @override
  State<_GroupingTab> createState() => _GroupingTabState();
}

class _GroupingTabState extends State<_GroupingTab> {
  late final _controller = GridController<Employee>(
    options: GridOptions(
      columns: [
        ColumnDef<Employee, String>.accessor(
          id: 'name',
          accessorFn: (e) => e.name,
          header: 'Name',
        ),
        ColumnDef<Employee, String>.accessor(
          id: 'department',
          accessorFn: (e) => e.department.name,
          header: 'Department',
        ),
        ColumnDef<Employee, String>.accessor(
          id: 'role',
          accessorFn: (e) => e.role,
          header: 'Role',
        ),
        ColumnDef<Employee, double>.accessor(
          id: 'salary',
          accessorFn: (e) => e.salary,
          header: 'Salary',
          columnType: ColumnType.money,
          textAlignIndex: 1,
        ),
      ],
      features: const [GroupingFeature()],
    ),
  )..setData(Employee.sample);

  String? _activeGroup;

  void _setGrouping(String? columnId) {
    setState(() => _activeGroup = columnId);
    if (columnId == null) {
      _controller.dispatch(const SetGroupingCommand([]));
    } else {
      _controller.dispatch(SetGroupingCommand([columnId]));
    }
  }

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
                label: const Text('Group by Department'),
                backgroundColor: _activeGroup == 'department'
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                onPressed: () => _setGrouping(
                    _activeGroup == 'department' ? null : 'department'),
              ),
              ActionChip(
                label: const Text('Group by Role'),
                backgroundColor: _activeGroup == 'role'
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                onPressed: () =>
                    _setGrouping(_activeGroup == 'role' ? null : 'role'),
              ),
              ActionChip(
                label: const Text('Clear Grouping'),
                onPressed: () => _setGrouping(null),
              ),
            ],
          ),
        ),
        if (_activeGroup != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              'Tap a group row to expand/collapse it.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Expanded(
          child: FlutterGrid<Employee>(
            controller: _controller,
            fillWidth: true,
            showToolbar: false,
            showFilterBar: false,
            showPagination: false,
            onRowTap: (row) {
              if (row.isGrouped) {
                _controller.dispatch(
                  SetRowExpandedCommand(row.id, !row.isExpanded),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

// ── Expanding ──────────────────────────────────────────────────────────────

class _TreeEmployee {
  final Employee employee;
  final List<_TreeEmployee> reports;

  const _TreeEmployee(this.employee, [this.reports = const []]);
}

class _ExpandingTab extends StatefulWidget {
  const _ExpandingTab();

  @override
  State<_ExpandingTab> createState() => _ExpandingTabState();
}

class _ExpandingTabState extends State<_ExpandingTab> {
  static final _treeData = [
    _TreeEmployee(
      Employee.sample[9], // James Wright — Principal Engineer
      [
        _TreeEmployee(Employee.sample[0]), // Alice Martin
        _TreeEmployee(Employee.sample[3]), // David Kim
        _TreeEmployee(Employee.sample[6]), // Grace Okafor
      ],
    ),
    _TreeEmployee(
      Employee.sample[1], // Bob Chen — Product Manager
      [
        _TreeEmployee(Employee.sample[8]), // Isabel Ferreira
      ],
    ),
    _TreeEmployee(
      Employee.sample[2], // Clara Dupont — Lead Designer
      [
        _TreeEmployee(Employee.sample[10]), // Karen Levi
      ],
    ),
    _TreeEmployee(Employee.sample[5]), // Frank Müller — no reports
    _TreeEmployee(Employee.sample[11]), // Luca Bianchi — no reports
  ];

  late final _controller = GridController<_TreeEmployee>(
    options: GridOptions<_TreeEmployee>(
      columns: [
        ColumnDef<_TreeEmployee, String>.accessor(
          id: 'name',
          accessorFn: (e) => e.employee.name,
          header: 'Name',
        ),
        ColumnDef<_TreeEmployee, String>.accessor(
          id: 'role',
          accessorFn: (e) => e.employee.role,
          header: 'Role',
        ),
        ColumnDef<_TreeEmployee, String>.accessor(
          id: 'department',
          accessorFn: (e) => e.employee.department.name,
          header: 'Department',
        ),
        ColumnDef<_TreeEmployee, double>.accessor(
          id: 'salary',
          accessorFn: (e) => e.employee.salary,
          header: 'Salary',
          columnType: ColumnType.money,
          textAlignIndex: 1,
        ),
      ],
      features: const [ExpandingFeature()],
      getSubRows: (e) => e.reports,
      getRowId: (e, i) => e.employee.id.toString(),
    ),
  )..setData(_treeData);

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
                label: const Text('Expand All'),
                onPressed: () =>
                    _controller.dispatch(const ToggleAllExpandedCommand(value: true)),
              ),
              ActionChip(
                label: const Text('Collapse All'),
                onPressed: () =>
                    _controller.dispatch(const ToggleAllExpandedCommand(value: false)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            'Tap a row with reports to expand/collapse its sub-rows.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: FlutterGrid<_TreeEmployee>(
            controller: _controller,
            fillWidth: true,
            showToolbar: false,
            showFilterBar: false,
            showPagination: false,
            onRowTap: (row) {
              if (row.subRows.isNotEmpty || row.depth > 0) {
                _controller.dispatch(
                  SetRowExpandedCommand(row.id, !row.isExpanded),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

// ── Columns (visibility, ordering, sizing) ─────────────────────────────────

class _ColumnsTab extends StatefulWidget {
  const _ColumnsTab();

  @override
  State<_ColumnsTab> createState() => _ColumnsTabState();
}

class _ColumnsTabState extends State<_ColumnsTab> {
  static const _colIds = ['name', 'role', 'department', 'salary', 'years'];

  late final _controller = GridController<Employee>(
    options: GridOptions(
      columns: [
        ColumnDef<Employee, String>.accessor(
          id: 'name',
          accessorFn: (e) => e.name,
          header: 'Name',
        ),
        ColumnDef<Employee, String>.accessor(
          id: 'role',
          accessorFn: (e) => e.role,
          header: 'Role',
        ),
        ColumnDef<Employee, String>.accessor(
          id: 'department',
          accessorFn: (e) => e.department.name,
          header: 'Department',
        ),
        ColumnDef<Employee, double>.accessor(
          id: 'salary',
          accessorFn: (e) => e.salary,
          header: 'Salary',
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
      ],
      features: [
        ColumnVisibilityFeature(),
        ColumnOrderingFeature(),
        ColumnSizingFeature(),
      ],
    ),
  )..setData(Employee.sample);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onStateChanged);
  }

  void _onStateChanged() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibility = _controller.state.columnVisibility;
    final order = _controller.state.columnOrder;
    final sizing = _controller.state.columnSizing;
    final displayOrder = order.isNotEmpty ? order : _colIds;

    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Text('Visibility',
                  style: Theme.of(context).textTheme.labelLarge),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                children: _colIds.map((id) {
                  final visible = visibility[id] ?? true;
                  return FilterChip(
                    label: Text(id),
                    selected: visible,
                    onSelected: (_) => _controller.dispatch(
                      ToggleColumnVisibilityCommand(id),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: Text('Order',
                  style: Theme.of(context).textTheme.labelLarge),
            ),
            SizedBox(
              height: 56,
              child: ReorderableListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: displayOrder.length,
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex--;
                  final newOrder = List<String>.from(displayOrder);
                  final item = newOrder.removeAt(oldIndex);
                  newOrder.insert(newIndex, item);
                  _controller.dispatch(SetColumnOrderCommand(newOrder));
                },
                itemBuilder: (context, i) {
                  final id = displayOrder[i];
                  return Padding(
                    key: ValueKey(id),
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(id),
                      avatar: const Icon(Icons.drag_handle, size: 16),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: Text('Sizing',
                  style: Theme.of(context).textTheme.labelLarge),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Name → 80'),
                    onPressed: () => _controller.dispatch(
                        const SetColumnSizeCommand('name', 80)),
                  ),
                  ActionChip(
                    label: const Text('Name → 200'),
                    onPressed: () => _controller.dispatch(
                        const SetColumnSizeCommand('name', 200)),
                  ),
                  ActionChip(
                    label: Text(
                        'Reset sizing${sizing.isNotEmpty ? ' (${sizing.length} custom)' : ''}'),
                    onPressed: () => _controller.dispatch(
                        const ResetColumnSizingCommand()),
                  ),
                ],
              ),
            ),
            const Divider(height: 16),
            Expanded(
              child: FlutterGrid<Employee>(
                controller: _controller,
                fillWidth: true,
                showToolbar: false,
                showFilterBar: false,
                showPagination: false,
              ),
            ),
          ],
        );
  }
}
