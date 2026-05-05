import 'package:flutter/material.dart';
import 'package:ntech_grid/ntech_grid.dart';

import '../data/todo.dart';
import '../data/todos_data_source.dart';

// ── Brand tokens ─────────────────────────────────────────────────────────────

const _brand = Color(0xFF6B5AED);
const _brandSoft = Color(0xFFF1EEFE);
const _brandHover = Color(0xFFF9FAFB);
const _brandDark = Color(0xFF4B3BC6);

const _textPrimary = Color(0xFF171717);
const _textSecondary = Color(0xFF737373);
const _textMuted = Color(0xFFa3a3a3);

const _borderColor = Color(0xFFE5E7EB);
const _surfaceGray = Color(0xFFfafafa);
const _white = Color(0xFFFFFFFF);

const _green = Color(0xFF15803D);
const _greenBg = Color(0xFFecfdf5);
const _greenBorder = Color(0xFFD1FAE5);
const _grayBadgeBg = Color(0xFFF3F4F6);
const _grayBadgeFg = Color(0xFF525252);
const _grayBadgeBorder = Color(0xFFE5E7EB);

// ── Screen ───────────────────────────────────────────────────────────────────

class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  late final GridController<Todo> _controller;
  final _dataSource = TodosDataSource();

  @override
  void initState() {
    super.initState();
    _controller = GridController<Todo>(
      options: GridOptions(
        columns: _buildColumns(),
        features: [PaginationFeature(mode: PaginationMode.serverSide)],
      ),
      initialState: const GridState(
        manualPagination: true,
        pagination: PaginationState(pageSize: 10),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Columns ───────────────────────────────────────────────────────────────

  static Todo _todo(Object ctx) =>
      (ctx as CellContext<Todo, Object?>).row.original;

  List<ColumnDef<Todo, dynamic>> _buildColumns() => [
    ColumnDef<Todo, int>.accessor(
      id: 'id',
      accessorFn: (t) => t.id,
      header: '#',
      size: 90,
      enableSorting: false,
      cell: (ctx) => Text(
        '${_todo(ctx).id}',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _brandDark,
        ),
      ),
    ),
    ColumnDef<Todo, String>.accessor(
      id: 'todo',
      accessorFn: (t) => t.todo,
      header: 'TÂCHE',
      enableSorting: false,
      cell: (ctx) => Text(
        _todo(ctx).todo,
        style: const TextStyle(fontSize: 13, color: _textPrimary),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    ),
    ColumnDef<Todo, bool>.accessor(
      id: 'completed',
      accessorFn: (t) => t.completed,
      header: 'STATUT',
      size: 120,
      enableSorting: false,
      cell: (ctx) => _StatusBadge(completed: _todo(ctx).completed),
    ),
    ColumnDef<Todo, int>.accessor(
      id: 'userId',
      accessorFn: (t) => t.userId,
      header: 'USER ID',
      size: 90,
      enableSorting: false,
      cell: (ctx) => Text(
        'U-${_todo(ctx).userId}',
        style: const TextStyle(fontSize: 13, color: _textSecondary),
      ),
    ),
  ];

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PageHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: _white,
                    border: Border.all(color: _borderColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: GridTheme(
                    data: GridThemeData(
                      headerBackground: _surfaceGray,
                      headerForeground: _textSecondary,
                      headerTextStyle: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                        letterSpacing: 0.5,
                      ),
                      headerHeight: 44,
                      rowHeight: 56,
                      rowBackground: _white,
                      alternateRowBackground: _white,
                      hoverRowBackground: _brandHover,
                      borderColor: _borderColor,
                      borderWidth: 1,
                      cellPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      headerPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: FlutterGrid<Todo>(
                      controller: _controller,
                      dataSource: _dataSource,
                      showToolbar: false,
                      showFilterBar: false,
                      showPagination: true,
                      fillWidth: true,
                      showColumnBorders: true,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page header ──────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Todos',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              height: 1.2,
            ),
          ),
          SizedBox(height: 3),
          Text(
            'dummyjson.com · pagination serveur',
            style: TextStyle(fontSize: 13, color: _textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool completed;
  const _StatusBadge({required this.completed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: completed ? _greenBg : _grayBadgeBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: completed ? _greenBorder : _grayBadgeBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: completed
                  ? const Color(0xFF10B981)
                  : const Color(0xFF9CA3AF),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            completed ? 'Terminé' : 'En cours',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: completed ? _green : _grayBadgeFg,
            ),
          ),
        ],
      ),
    );
  }
}
