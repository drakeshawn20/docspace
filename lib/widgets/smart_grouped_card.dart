import 'package:flutter/material.dart';

enum CardPosition { single, top, middle, bottom }

class SmartGroupedCard extends StatelessWidget {
  final Widget child;
  final CardPosition position;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const SmartGroupedCard({
    super.key,
    required this.child,
    required this.position,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = _getBorderRadius();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: borderRadius,
        ),
        child: child,
      ),
    );
  }

  BorderRadius _getBorderRadius() {
    switch (position) {
      case CardPosition.single:
        return BorderRadius.circular(25);
      case CardPosition.top:
        return const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
          bottomLeft: Radius.circular(13),
          bottomRight: Radius.circular(13),
        );
      case CardPosition.middle:
        return BorderRadius.circular(13);
      case CardPosition.bottom:
        return const BorderRadius.only(
          topLeft: Radius.circular(13),
          topRight: Radius.circular(13),
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        );
    }
  }
}

/// Helper widget to build a list of grouped cards with proper spacing
class SmartGroupedCardList extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const SmartGroupedCardList({
    super.key,
    required this.children,
    this.spacing = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: List.generate(
        children.length * 2 - 1,
        (index) {
          if (index.isOdd) {
            // Spacing
            return SizedBox(height: spacing);
          } else {
            // Card
            final itemIndex = index ~/ 2;
            return children[itemIndex];
          }
        },
      ),
    );
  }
}

/// Helper method to determine card position in a list
CardPosition getCardPosition(int index, int totalCount) {
  if (totalCount == 1) {
    return CardPosition.single;
  } else if (index == 0) {
    return CardPosition.top;
  } else if (index == totalCount - 1) {
    return CardPosition.bottom;
  } else {
    return CardPosition.middle;
  }
}
