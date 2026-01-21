import 'package:flutter/material.dart';
import 'dart:ui';

/// Shows a modal bottom sheet with spring/bouncy animation
Future<T?> showBouncyBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  Color? backgroundColor,
  ShapeBorder? shape,
  bool isScrollControlled = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? const Color(0xFF2C2C2C),
            borderRadius: shape != null 
                ? null 
                : const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: child!,
              );
            },
            child: builder(context),
          ),
        ),
      );
    },
  );
}
