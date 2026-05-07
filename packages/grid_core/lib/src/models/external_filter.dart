/// Operators for external (server-side) filters.
///
/// Used by [ExternalFilter] and serialized into query parameters by
/// [GridQuery.toQueryParameters].
enum FilterOperator {
  /// Exact match: `field=value`
  eq,

  /// Not equal: `field[neq]=value`
  neq,

  /// Greater than: `field[gt]=value`
  gt,

  /// Greater than or equal: `field[gte]=value`
  gte,

  /// Less than: `field[lt]=value`
  lt,

  /// Less than or equal: `field[lte]=value`
  lte,

  /// Case-insensitive contains: `field[contains]=value`
  contains,

  /// Starts with: `field[startsWith]=value`
  startsWith,

  /// Ends with: `field[endsWith]=value`
  endsWith,

  /// Value is in a list — [value] must be a [List]: `field[in]=a,b,c`
  in_,

  /// Value is not in a list — [value] must be a [List]: `field[notIn]=a,b,c`
  notIn,

  /// Between two values — [value] must be a two-element [List]: `field[gte]=a&field[lte]=b`
  between,

  /// Field is null: `field[isNull]=true`
  isNull,

  /// Field is not null: `field[isNotNull]=true`
  isNotNull,
}

/// A single typed filter applied externally (outside the grid's built-in
/// column filter UI).
///
/// External filters are stored in [GridState.externalFilters] and passed
/// to every [GridDataSource.fetch] call via [GridQuery.externalFilters].
///
/// ```dart
/// // From a DatePicker outside the grid:
/// controller.setExternalFilter(
///   'createdAt',
///   ExternalFilter(value: date, operator: FilterOperator.gte),
/// );
///
/// // Date range:
/// controller.setExternalFilter(
///   'createdAt',
///   ExternalFilter.dateRange(from: startDate, to: endDate),
/// );
/// ```
class ExternalFilter {
  /// The filter value. For [FilterOperator.in_] / [FilterOperator.notIn], pass
  /// a [List]. For [FilterOperator.between], pass a two-element [List].
  final dynamic value;

  /// The comparison operator. Defaults to [FilterOperator.eq].
  final FilterOperator operator;

  const ExternalFilter({
    required this.value,
    this.operator = FilterOperator.eq,
  });

  // ---------------------------------------------------------------------------
  // Named constructors / factory helpers
  // ---------------------------------------------------------------------------

  /// Exact match.
  const ExternalFilter.eq(dynamic value)
      : this(value: value, operator: FilterOperator.eq);

  /// `>=` (greater than or equal).
  const ExternalFilter.gte(dynamic value)
      : this(value: value, operator: FilterOperator.gte);

  /// `>` (strictly greater than).
  const ExternalFilter.gt(dynamic value)
      : this(value: value, operator: FilterOperator.gt);

  /// `<=` (less than or equal).
  const ExternalFilter.lte(dynamic value)
      : this(value: value, operator: FilterOperator.lte);

  /// `<` (strictly less than).
  const ExternalFilter.lt(dynamic value)
      : this(value: value, operator: FilterOperator.lt);

  /// Contains (case-insensitive substring match).
  const ExternalFilter.contains(String value)
      : this(value: value, operator: FilterOperator.contains);

  /// Value is one of the provided list.
  const ExternalFilter.inList(List<dynamic> values)
      : this(value: values, operator: FilterOperator.in_);

  /// Null check.
  const ExternalFilter.isNull()
      : this(value: null, operator: FilterOperator.isNull);

  /// Not-null check.
  const ExternalFilter.isNotNull()
      : this(value: null, operator: FilterOperator.isNotNull);

  /// A half-open date/time range `[from, to]`.
  ///
  /// Either bound can be null (open range). When both bounds exist the
  /// [GridQuery] serializer emits **two** parameters for the same field:
  /// `field[gte]=from&field[lte]=to`. Use [FilterOperator.between] to get
  /// this behaviour with a single [ExternalFilter].
  factory ExternalFilter.dateRange({DateTime? from, DateTime? to}) {
    return ExternalFilter(
      value: [from?.toIso8601String(), to?.toIso8601String()],
      operator: FilterOperator.between,
    );
  }

  /// A numeric range `[min, max]`. Either bound can be null.
  factory ExternalFilter.range(num? min, num? max) {
    return ExternalFilter(
      value: [min, max],
      operator: FilterOperator.between,
    );
  }

  // ---------------------------------------------------------------------------
  // Serialisation helpers used by GridQuery
  // ---------------------------------------------------------------------------

  /// The operator suffix used in query parameter keys, e.g. `"gte"` for
  /// `filter[createdAt][gte]`.
  String get operatorKey => switch (operator) {
        FilterOperator.eq => 'eq',
        FilterOperator.neq => 'neq',
        FilterOperator.gt => 'gt',
        FilterOperator.gte => 'gte',
        FilterOperator.lt => 'lt',
        FilterOperator.lte => 'lte',
        FilterOperator.contains => 'contains',
        FilterOperator.startsWith => 'startsWith',
        FilterOperator.endsWith => 'endsWith',
        FilterOperator.in_ => 'in',
        FilterOperator.notIn => 'notIn',
        FilterOperator.between => 'between',
        FilterOperator.isNull => 'isNull',
        FilterOperator.isNotNull => 'isNotNull',
      };

  /// Serialises [value] to a query-parameter-safe string.
  String _encodeValue(dynamic v) {
    if (v == null) return '';
    if (v is DateTime) return v.toIso8601String();
    if (v is List) return v.map(_encodeValue).join(',');
    return v.toString();
  }

  /// Emits one or more `key → value` pairs for this filter.
  ///
  /// [field] is the column / API field name.
  /// [paramFormat] controls how the key is formatted (see [QueryParamFormat]).
  Map<String, String> toParams(
    String field, {
    QueryParamFormat format = QueryParamFormat.brackets,
  }) {
    switch (operator) {
      // `between` expands into two params: gte + lte
      case FilterOperator.between:
        final list = value as List?;
        final from = list != null && list.isNotEmpty ? list[0] : null;
        final to = list != null && list.length > 1 ? list[1] : null;
        final params = <String, String>{};
        if (from != null) {
          params[_formatKey(field, 'gte', format)] = _encodeValue(from);
        }
        if (to != null) {
          params[_formatKey(field, 'lte', format)] = _encodeValue(to);
        }
        return params;

      case FilterOperator.isNull:
        return {_formatKey(field, 'isNull', format): 'true'};

      case FilterOperator.isNotNull:
        return {_formatKey(field, 'isNotNull', format): 'true'};

      case FilterOperator.eq:
        // `eq` uses the bare field key for cleaner URLs: `field=value`
        return {
          format == QueryParamFormat.bare
              ? field
              : _formatKey(field, 'eq', format): _encodeValue(value),
        };

      default:
        return {_formatKey(field, operatorKey, format): _encodeValue(value)};
    }
  }

  static String _formatKey(
      String field, String op, QueryParamFormat format) {
    return switch (format) {
      QueryParamFormat.brackets => 'filter[$field][$op]',
      QueryParamFormat.dotNotation => 'filter.$field.$op',
      QueryParamFormat.bare => '$field[$op]',
    };
  }

  @override
  String toString() => 'ExternalFilter($operator, $value)';

  @override
  bool operator ==(Object other) =>
      other is ExternalFilter &&
      other.operator == operator &&
      other.value == value;

  @override
  int get hashCode => Object.hash(operator, value);
}

/// Controls how external filter keys are formatted in [GridQuery.toQueryParameters].
enum QueryParamFormat {
  /// `filter[field][op]=value` (default — works with most REST APIs)
  brackets,

  /// `filter.field.op=value` (dot notation)
  dotNotation,

  /// `field[op]=value` (bare — no `filter` prefix)
  bare,
}
