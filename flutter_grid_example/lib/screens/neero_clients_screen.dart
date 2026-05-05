import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_grid/flutter_grid.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/client.dart';

// ── Brand tokens ─────────────────────────────────────────────────────────────

const _brand = Color(0xFF6B5AED);
const _brandSoft = Color(0xFFF1EEFE);
const _brandHover = Color(0xFFFAF9FF);
const _brandDark = Color(0xFF4B3BC6);

const _textPrimary = Color(0xFF404040);
const _textSecondary = Color(0xFF737373);
const _textMuted = Color(0xFFa3a3a3);

const _borderColor = Color(0xFFE2E8F0);
const _surfaceGray = Color(0xFFfafafa);
const _white = Color(0xFFFFFFFF);

const _green = Color(0xFF047857);
const _greenBg = Color(0xFFecfdf5);
const _grayBadgeBg = Color(0xFFF1F5F9);
const _grayBadgeFg = Color(0xFF475569);

// ── Status filter enum ────────────────────────────────────────────────────────

enum _StatusFilter { all, active, inactive }

// ── Screen ───────────────────────────────────────────────────────────────────

class NeeroClientsScreen extends StatefulWidget {
  const NeeroClientsScreen({super.key});

  @override
  State<NeeroClientsScreen> createState() => _NeeroClientsScreenState();
}

class _NeeroClientsScreenState extends State<NeeroClientsScreen> {
  final _searchCtrl = TextEditingController();
  final _personIdCtrl = TextEditingController();

  _StatusFilter _statusFilter = _StatusFilter.all;
  int _page = 1;
  int _pageSize = 10;

  late final GridController<Client> _controller;

  @override
  void initState() {
    super.initState();
    _controller = GridController<Client>(
      options: GridOptions(columns: _buildColumns()),
    );
    _controller.setData(_pageData);
    _searchCtrl.addListener(_onFilterChanged);
    _personIdCtrl.addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _personIdCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ── Derived data ──────────────────────────────────────────────────────────

  List<Client> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    final pid = _personIdCtrl.text.trim().toLowerCase();
    return Client.sample.where((c) {
      if (pid.isNotEmpty && !c.personId.toLowerCase().contains(pid)) {
        return false;
      }
      if (q.isNotEmpty) {
        final hit =
            c.firstName.toLowerCase().contains(q) ||
            c.lastName.toLowerCase().contains(q) ||
            c.email.toLowerCase().contains(q) ||
            c.phone.contains(q);
        if (!hit) return false;
      }
      return switch (_statusFilter) {
        _StatusFilter.active => c.isActive,
        _StatusFilter.inactive => !c.isActive,
        _StatusFilter.all => true,
      };
    }).toList();
  }

  List<Client> get _pageData {
    final f = _filtered;
    final start = (_page - 1) * _pageSize;
    if (start >= f.length) return [];
    return f.skip(start).take(_pageSize).toList();
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  void _onFilterChanged() {
    setState(() => _page = 1);
    _controller.setData(_pageData);
  }

  void _applyFilter(_StatusFilter f) {
    setState(() {
      _statusFilter = f;
      _page = 1;
    });
    _controller.setData(_pageData);
  }

  void _goToPage(int p) {
    setState(() => _page = p);
    _controller.setData(_pageData);
  }

  void _changePageSize(int size) {
    setState(() {
      _pageSize = size;
      _page = 1;
    });
    _controller.setData(_pageData);
  }

  // ── Column definitions ────────────────────────────────────────────────────

  // Helper: safely extract the Client from any cell context.
  static Client _client(Object ctx) =>
      (ctx as CellContext<Client, Object?>).row.original;

  List<ColumnDef<Client, dynamic>> _buildColumns() => [
    ColumnDef<Client, String>.accessor(
      id: 'personId',
      accessorFn: (c) => c.personId,
      header: 'PERSON ID',
      size: 148,
      enableSorting: false,
      cell: (ctx) => Text(
        _client(ctx).personId,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 13,
          color: _brandDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    ColumnDef<Client, String>.accessor(
      id: 'phone',
      accessorFn: (c) => c.phone,
      header: 'TÉLÉPHONE',
      size: 160,
      enableSorting: false,
      cell: (ctx) => SelectableText(
        _client(ctx).phone,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 13,
          color: _textPrimary,
          fontWeight: FontWeight.w500,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    ),
    ColumnDef<Client, String>.accessor(
      id: 'email',
      accessorFn: (c) => c.email,
      header: 'EMAIL',
      size: 220,
      enableSorting: false,
      cell: (ctx) => SelectableText(
        _client(ctx).email,
        style: const TextStyle(fontSize: 13, color: _textPrimary),
        // overflow: TextOverflow.ellipsis,
      ),
    ),
    ColumnDef<Client, String>.accessor(
      id: 'lastName',
      accessorFn: (c) => c.lastName,
      header: 'NOM',
      size: 130,
      cell: (ctx) => SelectableText(
        _client(ctx).lastName.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        // overflow: TextOverflow.ellipsis,
      ),
    ),
    ColumnDef<Client, String>.accessor(
      id: 'firstName',
      accessorFn: (c) => c.firstName,
      header: 'PRÉNOM',
      size: 120,
      enableSorting: false,
      cell: (ctx) => SelectableText(
        _client(ctx).firstName,
        style: const TextStyle(fontSize: 13, color: _textPrimary),
        //  overflow: TextOverflow.ellipsis,
      ),
    ),
    ColumnDef<Client, bool>.accessor(
      id: 'status',
      accessorFn: (c) => c.isActive,
      header: 'STATUT',
      size: 112,
      enableSorting: false,
      cell: (ctx) => _StatusBadge(active: _client(ctx).isActive),
    ),
    ColumnDef<Client, String>.accessor(
      id: 'plan',
      accessorFn: (c) => c.plan.name,
      header: 'PLAN',
      size: 108,
      enableSorting: false,
      cell: (ctx) => _PlanBadge(plan: _client(ctx).plan),
    ),
    ColumnDef<Client, DateTime?>.accessor(
      id: 'lastLogin',
      accessorFn: (c) => c.lastLogin,
      header: 'DERNIÈRE CONNEXION',
      size: 172,
      enableSorting: false,
      cell: (ctx) => _LastLoginCell(dateTime: _client(ctx).lastLogin),
    ),
    ColumnDef<Client, String>.display(
      id: 'col_1',
      header: '',
      size: 172,
      // textAlignIndex: 2,
      cell: (ctx) => _ActionButton(client: _client(ctx)),
    ),
  ];

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final activeCount = Client.sample.where((c) => c.isActive).length;
    final inactiveCount = Client.sample.where((c) => !c.isActive).length;

    return Scaffold(
      backgroundColor: _white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Page header ────────────────────────────────────────────────
            _PageHeader(totalCount: filtered.length),
            // ── Search panel ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: _SearchPanel(
                searchCtrl: _searchCtrl,
                personIdCtrl: _personIdCtrl,
              ),
            ),
            const SizedBox(height: 14),
            // ── Status filter chips ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _FilterChips(
                current: _statusFilter,
                onChanged: _applyFilter,
                allCount: Client.sample.length,
                activeCount: activeCount,
                inactiveCount: inactiveCount,
              ),
            ),
            const SizedBox(height: 16),
            // ── Table + pagination ─────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Column(
                  children: [
                    Expanded(child: _ClientTable(controller: _controller)),
                    const SizedBox(height: 12),
                    _Pagination(
                      totalItems: filtered.length,
                      currentPage: _page,
                      pageSize: _pageSize,
                      onPageChanged: _goToPage,
                      onPageSizeChanged: _changePageSize,
                    ),
                    const SizedBox(height: 20),
                  ],
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
  final int totalCount;
  const _PageHeader({required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Clients',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$totalCount clients au total',
                style: const TextStyle(fontSize: 13, color: _textSecondary),
              ),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            icon: const Icon(Icons.download_outlined, size: 15),
            label: const Text('Exporter CSV'),
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: _textSecondary,
              side: const BorderSide(color: _borderColor),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 15),
            label: const Text('Nouveau client'),
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: _brand,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search panel ─────────────────────────────────────────────────────────────

class _SearchPanel extends StatelessWidget {
  final TextEditingController searchCtrl;
  final TextEditingController personIdCtrl;

  const _SearchPanel({required this.searchCtrl, required this.personIdCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceGray,
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _SearchField(
              controller: searchCtrl,
              hint: 'Rechercher par nom, email, téléphone…',
              icon: Icons.search_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _SearchField(
              controller: personIdCtrl,
              hint: 'Rechercher par Person ID…',
              icon: Icons.badge_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;

  const _SearchField({
    required this.controller,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 13, color: _textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: _textMuted),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 10, right: 6),
          child: Icon(icon, size: 16, color: _textMuted),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: _white,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
      ),
    );
  }
}

// ── Filter chips ──────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final _StatusFilter current;
  final void Function(_StatusFilter) onChanged;
  final int allCount;
  final int activeCount;
  final int inactiveCount;

  const _FilterChips({
    required this.current,
    required this.onChanged,
    required this.allCount,
    required this.activeCount,
    required this.inactiveCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChip(
          label: 'Tous',
          count: allCount,
          selected: current == _StatusFilter.all,
          onTap: () => onChanged(_StatusFilter.all),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Actifs',
          count: activeCount,
          selected: current == _StatusFilter.active,
          onTap: () => onChanged(_StatusFilter.active),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Inactifs',
          count: inactiveCount,
          selected: current == _StatusFilter.inactive,
          onTap: () => onChanged(_StatusFilter.inactive),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _brandSoft : _white,
          border: Border.all(
            color: selected ? _brand : _borderColor,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? _brand : _textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 130),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: selected ? _brand : _grayBadgeBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? _white : _grayBadgeFg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Table container ───────────────────────────────────────────────────────────

class _ClientTable extends StatelessWidget {
  final GridController<Client> controller;

  const _ClientTable({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _textSecondary,
            letterSpacing: 0.6,
          ),
          headerHeight: 55,
          rowHeight: 60,
          rowBackground: _white,
          alternateRowBackground: _white,
          selectedRowBackground: _brandSoft,
          hoverRowBackground: _brandHover,
          borderColor: _borderColor,
          borderWidth: 1,
          cellPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          headerPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 0,
          ),
        ),
        child: GridBuilder<Client>(
          controller: controller,
          builder: (ctx, table) => GridDataTable<Client>(
            controller: controller,
            table: table,
            fillWidth: true,
            striped: false,
            showColumnBorders: true,
          ),
        ),
      ),
    );
  }
}

// ── Cell widgets ──────────────────────────────────────────────────────────────

/// Person ID pill with inline copy button.
class _PersonIdChip extends StatefulWidget {
  final String id;
  const _PersonIdChip({required this.id});

  @override
  State<_PersonIdChip> createState() => _PersonIdChipState();
}

class _PersonIdChipState extends State<_PersonIdChip> {
  bool _copied = false;

  void _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.id));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _copy,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _grayBadgeBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.id,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _textSecondary,
                fontFeatures: [FontFeature.tabularFigures()],
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              _copied ? Icons.check_rounded : Icons.copy_outlined,
              size: 12,
              color: _copied ? _green : _textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Colored dot + label status badge.
class _StatusBadge extends StatelessWidget {
  final bool active;
  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? _greenBg : _grayBadgeBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? _green : _textMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            active ? 'Actif' : 'Inactif',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? _green : _textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Plan badge with tier-specific colors.
class _PlanBadge extends StatelessWidget {
  final ClientPlan plan;
  const _PlanBadge({required this.plan});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (plan) {
      ClientPlan.standard => (
        const Color(0xFFF1F5F9),
        _grayBadgeFg,
        'Standard',
      ),
      ClientPlan.plus => (
        const Color(0xFFEFF6FF),
        const Color(0xFF1D4ED8),
        'Plus',
      ),
      ClientPlan.premium => (_brandSoft, _brandDark, 'Premium'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

/// Two-line cell showing relative and absolute last-login time.
class _LastLoginCell extends StatelessWidget {
  final DateTime? dateTime;
  const _LastLoginCell({required this.dateTime});

  String _relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return "Aujourd'hui";
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) {
      return 'il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
    }
    if (diff.inDays < 30) {
      final w = diff.inDays ~/ 7;
      return 'il y a $w semaine${w > 1 ? 's' : ''}';
    }
    if (diff.inDays < 365) {
      final mo = diff.inDays ~/ 30;
      return 'il y a $mo mois';
    }
    final y = diff.inDays ~/ 365;
    return 'il y a $y an${y > 1 ? 's' : ''}';
  }

  String _exact(DateTime dt) {
    const months = [
      '',
      'jan.',
      'fév.',
      'mar.',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sep.',
      'oct.',
      'nov.',
      'déc.',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month]} ${dt.year} · $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    if (dateTime == null) {
      return const Text(
        'Jamais connecté',
        style: TextStyle(
          fontSize: 12,
          color: _textMuted,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _relative(dateTime!),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _textPrimary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          _exact(dateTime!),
          style: const TextStyle(fontSize: 11, color: _textMuted, height: 1.3),
        ),
      ],
    );
  }
}

/// Eye (view) icon button per row.
class _ActionButton extends StatelessWidget {
  final Client client;
  const _ActionButton({required this.client});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Voir le profil',
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 32,
          height: 32,

          child: const Icon(
            Icons.visibility_outlined,
            size: 15,
            color: _textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Pagination ────────────────────────────────────────────────────────────────

class _Pagination extends StatelessWidget {
  final int totalItems;
  final int currentPage;
  final int pageSize;
  final void Function(int) onPageChanged;
  final void Function(int) onPageSizeChanged;

  const _Pagination({
    required this.totalItems,
    required this.currentPage,
    required this.pageSize,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  int get _totalPages =>
      totalItems == 0 ? 1 : ((totalItems + pageSize - 1) ~/ pageSize);

  int get _from => totalItems == 0 ? 0 : (currentPage - 1) * pageSize + 1;
  int get _to => (currentPage * pageSize).clamp(0, totalItems);

  List<Object> _pageNumbers() {
    final total = _totalPages;
    if (total <= 7) return List.generate(total, (i) => i + 1);

    final result = <Object>[];
    result.add(1);
    if (currentPage > 3) result.add('…');

    final start = (currentPage - 1).clamp(2, total - 1);
    final end = (currentPage + 1).clamp(2, total - 1);
    for (int i = start; i <= end; i++) {
      result.add(i);
    }

    if (currentPage < total - 2) result.add('…');
    result.add(total);

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Page size selector
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _white,
            border: Border.all(color: _borderColor),
            borderRadius: BorderRadius.circular(7),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: pageSize,
              isDense: true,
              style: const TextStyle(fontSize: 13, color: _textSecondary),
              items: [10, 25, 50]
                  .map(
                    (n) => DropdownMenuItem(value: n, child: Text('$n / page')),
                  )
                  .toList(),
              onChanged: (v) => v != null ? onPageSizeChanged(v) : null,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$_from–$_to sur $totalItems',
          style: const TextStyle(fontSize: 13, color: _textSecondary),
        ),
        const Spacer(),
        // Prev button
        _NavBtn(
          icon: Icons.chevron_left_rounded,
          enabled: currentPage > 1,
          onTap: () => onPageChanged(currentPage - 1),
        ),
        const SizedBox(width: 4),
        // Page number chips
        ..._pageNumbers().map((item) {
          if (item is String) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                '…',
                style: const TextStyle(fontSize: 13, color: _textMuted),
              ),
            );
          }
          final page = item as int;
          final active = page == currentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: GestureDetector(
              onTap: active ? null : () => onPageChanged(page),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: active ? _brand : _white,
                  border: Border.all(color: active ? _brand : _borderColor),
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$page',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? _white : _textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 4),
        // Next button
        _NavBtn(
          icon: Icons.chevron_right_rounded,
          enabled: currentPage < _totalPages,
          onTap: () => onPageChanged(currentPage + 1),
        ),
      ],
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _white,
          border: Border.all(color: _borderColor),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? _textSecondary : _textMuted,
        ),
      ),
    );
  }
}
