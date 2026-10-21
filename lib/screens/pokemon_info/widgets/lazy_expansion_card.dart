import 'package:flutter/material.dart';

/// A performance-optimized [Card] containing an [ExpansionTile] that defers building
/// its inner content until explicitly expanded by the user.
///
/// When collapsed, the inner subtree is neither built nor maintained in the element tree,
/// preventing off-screen bitmap decodes, database queries, and redundant state allocations.
class LazyExpansionCard extends StatefulWidget {
  final Widget? leading;
  final Widget title;
  final Widget? trailing;
  final WidgetBuilder builder;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;
  final EdgeInsetsGeometry margin;
  final double elevation;
  final ShapeBorder? shape;
  final Color? backgroundColor;

  const LazyExpansionCard({
    super.key,
    this.leading,
    required this.title,
    this.trailing,
    required this.builder,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    this.margin = const EdgeInsets.only(bottom: 16),
    this.elevation = 2,
    this.shape,
    this.backgroundColor,
  });

  @override
  State<LazyExpansionCard> createState() => _LazyExpansionCardState();
}

class _LazyExpansionCardState extends State<LazyExpansionCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: widget.margin,
      elevation: widget.elevation,
      color: widget.backgroundColor,
      shape: widget.shape ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        maintainState: false,
        initiallyExpanded: widget.initiallyExpanded,
        leading: widget.leading,
        title: widget.title,
        trailing: widget.trailing,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
          if (widget.onExpansionChanged != null) {
            widget.onExpansionChanged!(expanded);
          }
        },
        children: [
          if (_isExpanded) Builder(builder: widget.builder),
        ],
      ),
    );
  }
}
