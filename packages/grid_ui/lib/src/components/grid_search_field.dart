import 'dart:async';

import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';

class GridSearchField<T> extends StatefulWidget {
  final GridController<T> controller;
  final String hintText;
  final Duration debounceDuration;

  const GridSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  @override
  State<GridSearchField<T>> createState() => _GridSearchFieldState<T>();
}

class _GridSearchFieldState<T> extends State<GridSearchField<T>> {
  late final TextEditingController _textController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.controller.state.globalFilter ?? '',
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      widget.controller.setGlobalFilter(value.isEmpty ? null : value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _textController,
      onChanged: _onChanged,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _textController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _textController.clear();
                  widget.controller.setGlobalFilter(null);
                },
              )
            : null,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
