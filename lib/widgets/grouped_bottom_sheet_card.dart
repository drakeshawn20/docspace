import 'package:flutter/material.dart';

enum GroupedCardPosition {
  single,
  first,
  middle,
  last,
}

class GroupedBottomSheetCard extends StatelessWidget {
  final GroupedCardPosition position;
  final VoidCallback onTap;
  final Widget child;

  const GroupedBottomSheetCard({
    super.key,
    required this.position,
    required this.onTap,
    required this.child,
  });

  BorderRadius _getBorderRadius() {
    switch (position) {
      case GroupedCardPosition.single:
        return BorderRadius.circular(25);
      case GroupedCardPosition.first:
        return const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        );
      case GroupedCardPosition.middle:
        return BorderRadius.circular(10);
      case GroupedCardPosition.last:
        return const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black, // Pure black cards
      borderRadius: _getBorderRadius(),
      child: InkWell(
        onTap: onTap,
        borderRadius: _getBorderRadius(),
        child: child,
      ),
    );
  }
}

class GroupedBottomSheetCardList extends StatelessWidget {
  final List<Widget> children;

  const GroupedBottomSheetCardList({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        children.length * 2 - 1,
        (index) {
          if (index.isOdd) {
            // Gap between cards
            return const SizedBox(height: 3);
          }
          return children[index ~/ 2];
        },
      ),
    );
  }
}

GroupedCardPosition getGroupedCardPosition(int index, int total) {
  if (total == 1) return GroupedCardPosition.single;
  if (index == 0) return GroupedCardPosition.first;
  if (index == total - 1) return GroupedCardPosition.last;
  return GroupedCardPosition.middle;
}
