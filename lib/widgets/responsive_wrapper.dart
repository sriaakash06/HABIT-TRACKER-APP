import 'package:flutter/material.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Color? backgroundColor;

  const ResponsiveWrapper({
    Key? key,
    required this.child,
    this.maxWidth = 800.0,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > maxWidth;
        
        return Container(
          color: backgroundColor ?? (isWide ? const Color(0xFF0F0F12) : Theme.of(context).scaffoldBackgroundColor),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                boxShadow: [
                  if (isWide)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 40,
                      spreadRadius: 2,
                      offset: const Offset(0, 20),
                    ),
                ],
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Container(
                  width: double.infinity,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
