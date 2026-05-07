import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ntech_grid/ntech_grid.dart';

import '../data/todo.dart';
import '../data/todos_data_source.dart';

// ── Brand tokens ─────────────────────────────────────────────────────────────

const _brand = Color(0xFF6B5AED);
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

// ── Status filter values ──────────────────────────────────────────────────────

enum _StatusFilter { all, completed, pending }

// ── Screen ───────────────────────────────────────────────────────────────────

class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  late final GridController<Todo> _controller;
  final _dataSource = TodosDataSource();

  // Local mirror of external filters so the UI can rebuild without reading
  // back from controller.state each time.
  _StatusFilter _activeStatus = _StatusFilter.all;
  final _userIdController = TextEditingController();
  int? _activeUserId;

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
    _userIdController.dispose();
    super.dispose();
  }

  // ── External filter helpers ───────────────────────────────────────────────

  void _setStatus(_StatusFilter status) {
    setState(() => _activeStatus = status);

    if (status == _StatusFilter.all) {
      _controller.clearExternalFilter('completed');
    } else {
      _controller.setExternalFilter(
        'completed',
        ExternalFilter.eq(status == _StatusFilter.completed),
      );
    }
  }

  void _setUserId(int? userId) {
    setState(() => _activeUserId = userId);

    if (userId == null) {
      _controller.clearExternalFilter('userId');
    } else {
      _controller.setExternalFilter('userId', ExternalFilter.eq(userId));
    }
  }

  void _resetAllFilters() {
    setState(() {
      _activeStatus = _StatusFilter.all;
      _activeUserId = null;
    });
    _userIdController.clear();
    _controller.clearAllExternalFilters();
  }

  bool get _hasActiveFilters =>
      _activeStatus != _StatusFilter.all || _activeUserId != null;

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
        child: ListView(
          children: [
            _PageHeader(
              hasActiveFilters: _hasActiveFilters,
              onReset: _resetAllFilters,
            ),
            // ── External filter controls ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status toggle
                  _SectionLabel(label: 'Statut'),
                  const SizedBox(height: 8),
                  _StatusToggle(value: _activeStatus, onChanged: _setStatus),
                  const SizedBox(height: 16),
                  // User ID filter
                  _SectionLabel(label: 'User ID'),
                  const SizedBox(height: 8),
                  _UserIdFilter(
                    controller: _userIdController,
                    activeUserId: _activeUserId,
                    onApply: _setUserId,
                  ),
                ],
              ),
            ),
            // ── Grid ─────────────────────────────────────────────────────
            Padding(
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
                    shrinkWrap: true,
                    fillWidth: true,
                    showColumnBorders: true,
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
  final bool hasActiveFilters;
  final VoidCallback onReset;

  const _PageHeader({required this.hasActiveFilters, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
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
                  'dummyjson.com · pagination + filtres serveur',
                  style: TextStyle(fontSize: 13, color: _textSecondary),
                ),
              ],
            ),
          ),
          if (hasActiveFilters)
            TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.filter_list_off, size: 16),
              label: const Text('Réinitialiser'),
              style: TextButton.styleFrom(foregroundColor: _textSecondary),
            ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: _textSecondary,
        letterSpacing: 0.4,
      ),
    );
  }
}

// ── Status toggle ─────────────────────────────────────────────────────────────

class _StatusToggle extends StatelessWidget {
  final _StatusFilter value;
  final ValueChanged<_StatusFilter> onChanged;

  const _StatusToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _StatusFilter.values.map((s) {
        final selected = s == value;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _ToggleChip(
            label: switch (s) {
              _StatusFilter.all => 'Tous',
              _StatusFilter.completed => 'Terminés',
              _StatusFilter.pending => 'En cours',
            },
            selected: selected,
            onTap: () => onChanged(s),
          ),
        );
      }).toList(),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _brand : _white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _brand : _borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? _white : _textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── User ID filter ────────────────────────────────────────────────────────────

class _UserIdFilter extends StatelessWidget {
  final TextEditingController controller;
  final int? activeUserId;
  final ValueChanged<int?> onApply;

  const _UserIdFilter({
    required this.controller,
    required this.activeUserId,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Input
        SizedBox(
          width: 120,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'ex: 5',
              hintStyle: TextStyle(fontSize: 13, color: _textMuted),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _brand, width: 1.5),
              ),
            ),
            style: const TextStyle(fontSize: 13),
            onSubmitted: (v) => _submit(v),
          ),
        ),
        const SizedBox(width: 8),
        // Apply button
        FilledButton(
          onPressed: () => _submit(controller.text),
          style: FilledButton.styleFrom(
            backgroundColor: _brand,
            foregroundColor: _white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Filtrer'),
        ),
        // Clear button — shown only when a userId is active
        if (activeUserId != null) ...[
          const SizedBox(width: 6),
          IconButton(
            onPressed: () {
              controller.clear();
              onApply(null);
            },
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Effacer le filtre user',
            style: IconButton.styleFrom(foregroundColor: _textSecondary),
          ),
          Text(
            'U-$activeUserId actif',
            style: const TextStyle(fontSize: 12, color: _brand),
          ),
        ],
      ],
    );
  }

  void _submit(String raw) {
    final userId = int.tryParse(raw.trim());
    onApply(userId); // null if empty/invalid → clears the filter
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
