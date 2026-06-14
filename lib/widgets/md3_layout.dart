import 'package:flutter/material.dart';

import '../app/app_theme.dart';

/// Shared scroll-safe content wrapper for Material 3 modal bottom sheets.
///
/// It prevents small-screen overflow by capping the sheet height and allowing
/// the inner content to scroll. Use it inside showModalBottomSheet builders.
class Md3BottomSheetContent extends StatelessWidget {
  const Md3BottomSheetContent({
    super.key,
    required this.children,
    this.maxHeightFactor = 0.82,
    this.horizontalPadding = 16,
    this.topPadding = 4,
    this.bottomPadding = 16,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> children;
  final double maxHeightFactor;
  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor,
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topPadding,
            horizontalPadding,
            bottomPadding + bottomInset,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: crossAxisAlignment,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// A consistent page container for all full-screen forms/pages.
class Md3PageBody extends StatelessWidget {
  const Md3PageBody({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.pageBackground(context),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
