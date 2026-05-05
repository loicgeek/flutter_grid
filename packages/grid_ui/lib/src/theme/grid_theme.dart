import 'package:flutter/material.dart';

/// Visual configuration for the grid.
///
/// Provide via [GridTheme] to override the default Material-derived values:
///
/// ```dart
/// GridTheme(
///   data: GridThemeData(
///     headerBackground: Colors.indigo.shade800,
///     hoverRowBackground: Colors.indigo.withValues(alpha: 0.08),
///   ),
///   child: FlutterGrid(controller: controller),
/// )
/// ```
class GridThemeData {
  final Color? headerBackground;
  final Color? headerForeground;
  final Color? rowBackground;
  final Color? alternateRowBackground;
  final Color? selectedRowBackground;
  final Color? borderColor;
  final Color? pinnedColumnBackground;
  final Color? hoverRowBackground;
  final double borderWidth;
  final double headerHeight;
  final double rowHeight;
  final double defaultColumnWidth;
  final TextStyle? headerTextStyle;
  final TextStyle? cellTextStyle;
  final EdgeInsets cellPadding;
  final EdgeInsets headerPadding;
  final BorderRadius? headerBorderRadius;
  final bool? pinnedHeader;

  const GridThemeData({
    this.headerBackground,
    this.headerForeground,
    this.rowBackground,
    this.alternateRowBackground,
    this.selectedRowBackground,
    this.borderColor,
    this.pinnedColumnBackground,
    this.hoverRowBackground,
    this.borderWidth = 1.0,
    this.headerHeight = 48.0,
    this.rowHeight = 52.0,
    this.defaultColumnWidth = 150.0,
    this.headerTextStyle,
    this.cellTextStyle,
    this.cellPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.headerPadding =
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.headerBorderRadius,
    this.pinnedHeader = true,
  });

  factory GridThemeData.fromTheme(ThemeData theme) {
    return GridThemeData(
      headerBackground: theme.colorScheme.surfaceContainerHighest,
      headerForeground: theme.colorScheme.onSurface,
      rowBackground: theme.colorScheme.surface,
      alternateRowBackground: theme.colorScheme.surfaceContainerLowest,
      selectedRowBackground:
          theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      borderColor: theme.dividerColor,
      pinnedColumnBackground: theme.colorScheme.surface,
      hoverRowBackground: theme.colorScheme.onSurface.withValues(alpha: 0.04),
      headerTextStyle:
          theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      cellTextStyle: theme.textTheme.bodyMedium,
      pinnedHeader: true,
    );
  }

  GridThemeData copyWith({
    Color? headerBackground,
    Color? headerForeground,
    Color? rowBackground,
    Color? alternateRowBackground,
    Color? selectedRowBackground,
    Color? borderColor,
    Color? pinnedColumnBackground,
    Color? hoverRowBackground,
    double? borderWidth,
    double? headerHeight,
    double? rowHeight,
    double? defaultColumnWidth,
    TextStyle? headerTextStyle,
    TextStyle? cellTextStyle,
    EdgeInsets? cellPadding,
    EdgeInsets? headerPadding,
    BorderRadius? headerBorderRadius,
    bool? pinnedHeader,
  }) {
    return GridThemeData(
      headerBackground: headerBackground ?? this.headerBackground,
      headerForeground: headerForeground ?? this.headerForeground,
      rowBackground: rowBackground ?? this.rowBackground,
      alternateRowBackground:
          alternateRowBackground ?? this.alternateRowBackground,
      selectedRowBackground:
          selectedRowBackground ?? this.selectedRowBackground,
      borderColor: borderColor ?? this.borderColor,
      pinnedColumnBackground:
          pinnedColumnBackground ?? this.pinnedColumnBackground,
      hoverRowBackground: hoverRowBackground ?? this.hoverRowBackground,
      borderWidth: borderWidth ?? this.borderWidth,
      headerHeight: headerHeight ?? this.headerHeight,
      rowHeight: rowHeight ?? this.rowHeight,
      defaultColumnWidth: defaultColumnWidth ?? this.defaultColumnWidth,
      headerTextStyle: headerTextStyle ?? this.headerTextStyle,
      cellTextStyle: cellTextStyle ?? this.cellTextStyle,
      cellPadding: cellPadding ?? this.cellPadding,
      headerPadding: headerPadding ?? this.headerPadding,
      headerBorderRadius: headerBorderRadius ?? this.headerBorderRadius,
      pinnedHeader: pinnedHeader ?? this.pinnedHeader,
    );
  }
}

/// Provides [GridThemeData] down the widget tree.
class GridTheme extends InheritedWidget {
  final GridThemeData data;

  const GridTheme({
    super.key,
    required this.data,
    required super.child,
  });

  static GridThemeData of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<GridTheme>();
    return theme?.data ?? GridThemeData.fromTheme(Theme.of(context));
  }

  static GridThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GridTheme>()?.data;
  }

  @override
  bool updateShouldNotify(GridTheme oldWidget) => data != oldWidget.data;
}
