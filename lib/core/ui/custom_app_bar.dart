import 'package:flutter/material.dart';
import 'glass_box.dart';

class FloatingGlassAppBar extends StatelessWidget {
  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final double height;
  final EdgeInsets margin;

  const FloatingGlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.height = 60,
    this.margin = const EdgeInsets.fromLTRB(16, 8, 16, 0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      height: height,
      child: GlassBox(
        borderRadius: BorderRadius.circular(30),
        opacity: 0.1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 8),
              ],
              Expanded(
                child: DefaultTextStyle(
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  child: title,
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}
