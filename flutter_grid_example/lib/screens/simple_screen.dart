import 'package:flutter/material.dart';
import 'package:flutter_grid/flutter_grid.dart';

import '../data/employee.dart';

/// Basic table: sort, filter, column visibility, pagination, hover, fillWidth.
class SimpleScreen extends StatefulWidget {
  const SimpleScreen({super.key});

  @override
  State<SimpleScreen> createState() => _SimpleScreenState();
}

class _SimpleScreenState extends State<SimpleScreen> {
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
        ColumnDef<Employee, int>.accessor(
          id: 'years',
          accessorFn: (e) => e.yearsAtCompany,
          header: 'Years',
          size: 80,
          columnType: ColumnType.number,
          textAlignIndex: 1,
        ),
        ColumnDef<Employee, bool>.accessor(
          id: 'active',
          accessorFn: (e) => e.isActive,
          header: 'Active',
          size: 80,
          columnType: ColumnType.boolean,
          textAlignIndex: 2,
        ),
        ColumnDef<Employee, double>.accessor(
          id: 'performance',
          accessorFn: (e) => e.performance,
          header: 'Performance',
          size: 140,
          columnType: ColumnType.progress,
        ),
      ],
    ),
    initialState: const GridState(
      pagination: PaginationState(pageSize: 8),
    ),
  )..setData(Employee.sample);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Table'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset sort & filters',
            onPressed: () {
              _controller.resetSort();
              _controller.clearAllFilters();
            },
          ),
        ],
      ),
      body: FlutterGrid<Employee>(
        controller: _controller,
        fillWidth: true,
        striped: true,
        showToolbar: true,
        showFilterBar: true,
        showPagination: true,
      ),
    );
  }
}
