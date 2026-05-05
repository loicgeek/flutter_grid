import 'package:flutter/material.dart';
import 'package:ntech_grid/ntech_grid.dart';

import '../data/employee.dart';

/// Demonstrates AnimatedList: add and remove rows with slide/fade animation.
class AnimatedScreen extends StatefulWidget {
  const AnimatedScreen({super.key});

  @override
  State<AnimatedScreen> createState() => _AnimatedScreenState();
}

class _AnimatedScreenState extends State<AnimatedScreen> {
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
        ColumnDef<Employee, String>.accessor(
          id: 'department',
          accessorFn: (e) => e.department.name,
          header: 'Dept',
          size: 140,
          columnType: ColumnType.badge,
        ),
        ColumnDef<Employee, bool>.accessor(
          id: 'active',
          accessorFn: (e) => e.isActive,
          header: 'Active',
          size: 80,
          columnType: ColumnType.boolean,
          textAlignIndex: 2,
        ),
      ],
    ),
  );

  List<Employee> _data = Employee.sample.take(4).toList();
  int _nextId = Employee.sample.length + 1;

  @override
  void initState() {
    super.initState();
    _controller.setData(_data);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addRow() {
    final id = _nextId++;
    final newEmployee = Employee(
      id: id,
      name: 'New Employee $id',
      email: 'new$id@acme.com',
      department: Department.engineering,
      role: 'Engineer',
      salary: 100000,
      yearsAtCompany: 0,
      isActive: true,
      startDate: DateTime.now(),
      performance: 0.75,
    );
    setState(() {
      _data = [..._data, newEmployee];
    });
    _controller.setData(_data);
  }

  void _removeFirst() {
    if (_data.isEmpty) return;
    setState(() {
      _data = _data.sublist(1);
    });
    _controller.setData(_data);
  }

  void _removeLast() {
    if (_data.isEmpty) return;
    setState(() {
      _data = _data.sublist(0, _data.length - 1);
    });
    _controller.setData(_data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animated Insert / Remove'),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            tooltip: 'Remove first row',
            onPressed: _data.isEmpty ? null : _removeFirst,
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            tooltip: 'Remove last row',
            onPressed: _data.isEmpty ? null : _removeLast,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add row',
            onPressed: _addRow,
          ),
        ],
      ),
      body: FlutterGrid<Employee>(
        controller: _controller,
        fillWidth: true,
        showToolbar: false,
        showFilterBar: false,
        showPagination: false,
      ),
    );
  }
}
