import 'package:flutter/material.dart';

/// Material 3 bottom-sheet body that never overflows on small screens.
///
/// It constrains the sheet height, scrolls long content, and keeps enough bottom
/// safe-area / keyboard padding so action rows are not hidden by system UI.
class SafeBottomSheet extends StatelessWidget {
  const SafeBottomSheet({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 24),
    this.maxHeightFactor = 0.86,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.keyboardAware = false,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final double maxHeightFactor;
  final CrossAxisAlignment crossAxisAlignment;
  final bool keyboardAware;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardInset = keyboardAware ? media.viewInsets.bottom : 0.0;
    final maxHeight = media.size.height * maxHeightFactor;

    return SafeArea(
      top: false,
      bottom: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            padding.left,
            padding.top,
            padding.right,
            padding.bottom + media.padding.bottom + keyboardInset,
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
