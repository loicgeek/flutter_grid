import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';

import '../cells/cell_renderer_registry.dart';

/// A single animated skeleton bar.
class SkeletonBar extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonBar({
    super.key,
    this.width = 100,
    this.height = 14,
    this.borderRadius,
  });

  @override
  State<SkeletonBar> createState() => _SkeletonBarState();
}

class _SkeletonBarState extends State<SkeletonBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => Opacity(
        opacity: _animation.value,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class SkeletonBadge extends StatelessWidget {
  const SkeletonBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      width: 60,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  final double size;
  const SkeletonCircle({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }
}

class SkeletonAvatarRow extends StatelessWidget {
  const SkeletonAvatarRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SkeletonCircle(size: 32),
        const SizedBox(width: 8),
        Container(
          height: 14,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }
}

/// A full skeleton grid loader.
class GridSkeletonLoader extends StatelessWidget {
  final List<ColumnDef<dynamic, dynamic>> columns;
  final int rowCount;

  const GridSkeletonLoader({
    super.key,
    required this.columns,
    this.rowCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header skeleton
        Container(
          color: Colors.grey[100],
          child: Row(
            children: columns.map((col) {
              return SizedBox(
                width: col.size ?? 150,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                  child: SkeletonBar(
                    width: (col.size ?? 150) * 0.5,
                    height: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Data rows skeleton
        ...List.generate(rowCount, (i) {
          return Container(
            decoration: BoxDecoration(
              color: i.isOdd ? Colors.grey[50] : Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: columns.map((col) {
                return SizedBox(
                  width: col.size ?? 150,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    child: CellRendererRegistry.instance.renderSkeleton(col),
                  ),
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }
}
