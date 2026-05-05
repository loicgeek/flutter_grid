import 'package:flutter/material.dart';
import 'package:ntech_grid/ntech_grid.dart';

import '../data/employee.dart';

/// Demonstrates multi-row selection, bulk actions, and haptic feedback.
class SelectionScreen extends StatefulWidget {
  const SelectionScreen({super.key});

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  late final _controller = _buildController();

  GridController<Employee> _buildController() {
    // Keep a reference so header widget closures can access it.
    late GridController<Employee> c;
    c = GridController<Employee>(
      options: GridOptions(
        columns: [
          // Checkbox column: uses headerWidget for select-all, cell for per-row.
          ColumnDef<Employee, bool>.display(
            id: 'select',
            size: 52,
            headerWidget: (_) => _SelectAllCheckbox(controller: c),
            cell: (ctx) {
              final row =
                  (ctx as CellContext).cell.row as RowModel<Employee>;
              return Checkbox(
                value: row.isSelected,
                onChanged: (_) => row.toggleSelected(),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            },
          ),
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
            header: 'Dept',
            size: 120,
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
        ],
      ),
    );
    c.setData(Employee.sample);
    return c;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selection + Bulk Actions')),
      body: FlutterGrid<Employee>(
        controller: _controller,
        fillWidth: true,
        showToolbar: false,
        showFilterBar: false,
        showPagination: false,
        enableHapticFeedback: true,
        onRowTap: (row) => _controller.toggleRowSelection(row.id),
        slots: GridSlots<Employee>(
          bulkActionBar: (ctx, table) => _BulkBar(
            controller: _controller,
            table: table,
          ),
        ),
      ),
    );
  }
}

// ── Select-all checkbox for header ────────────────────────────────────────

class _SelectAllCheckbox extends StatefulWidget {
  final GridController<Employee> controller;
  const _SelectAllCheckbox({required this.controller});

  @override
  State<_SelectAllCheckbox> createState() => _SelectAllCheckboxState();
}

class _SelectAllCheckboxState extends State<_SelectAllCheckbox> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final rows = widget.controller.getRowModels().pageRows;
    final allSelected =
        rows.isNotEmpty && rows.every((r) => r.isSelected);
    final someSelected = !allSelected && rows.any((r) => r.isSelected);

    return Checkbox(
      value: someSelected ? null : allSelected,
      tristate: true,
      onChanged: (_) =>
          widget.controller.toggleAllRowsSelected(value: !allSelected),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

// ── Bulk action bar ────────────────────────────────────────────────────────

class _BulkBar extends StatelessWidget {
  final GridController<Employee> controller;
  final GridTableState<Employee> table;

  const _BulkBar({required this.controller, required this.table});

  @override
  Widget build(BuildContext context) {
    final count = controller.state.selectedCount;
    if (count == 0) return const SizedBox.shrink();

    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '$count selected',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: const Text('Activate'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Activated $count employees'),
                  duration: const Duration(seconds: 2),
                ),
              );
              controller.clearRowSelection();
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.delete_outline,
                size: 16, color: Colors.red),
            label: const Text('Remove',
                style: TextStyle(color: Colors.red)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed $count employees'),
                  duration: const Duration(seconds: 2),
                ),
              );
              controller.clearRowSelection();
            },
          ),
          const Spacer(),
          TextButton(
            onPressed: controller.clearRowSelection,
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
