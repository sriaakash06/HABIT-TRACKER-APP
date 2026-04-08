import 'package:flutter/material.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Color? backgroundColor;

  const ResponsiveWrapper({
    Key? key,
    required this.child,
    this.maxWidth = 600.0,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > maxWidth;

    return Container(
      color: backgroundColor ?? (isWide ? Colors.black : Theme.of(context).scaffoldBackgroundColor),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              if (isWide)
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
