import 'package:flutter/material.dart';
import 'package:ntech_grid/ntech_grid.dart';
import 'package:grid_export/grid_export.dart';

import '../data/employee.dart';

/// Demonstrates CSV export and clipboard copy via GridExporter.
class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
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
      ],
    ),
  )..setData(Employee.sample);

  late final _exporter = GridExporter<Employee>(controller: _controller);

  String _preview = '';
  bool _allRows = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _copyToClipboard() async {
    final csv = await _exporter.copyToClipboard(allRows: _allRows);
    if (!mounted) return;
    setState(() => _preview = csv);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showPreview() {
    setState(() => _preview = _exporter.toCsv(allRows: _allRows));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CSV Export')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Switch(
                  value: _allRows,
                  onChanged: (v) => setState(() => _allRows = v),
                ),
                const SizedBox(width: 8),
                Text(_allRows ? 'All filtered rows' : 'Current page only'),
                const Spacer(),
                FilledButton.icon(
                  icon: const Icon(Icons.preview),
                  label: const Text('Preview CSV'),
                  onPressed: _showPreview,
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy to clipboard'),
                  onPressed: _copyToClipboard,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: FlutterGrid<Employee>(
              controller: _controller,
              fillWidth: true,
              showToolbar: true,
              showFilterBar: true,
              showPagination: true,
            ),
          ),
          if (_preview.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'CSV Preview',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SelectableText(
                  _preview,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
