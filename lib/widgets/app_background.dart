import 'package:flutter/material.dart';

/// The launcher icon is a light card on an orange gradient, sampled here from
/// `ic_launcher_background.png`. Wrapping a transparent [Scaffold] paints the
/// app bar too, so the gradient runs the full height of the screen.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) => ColoredBox(
        // The gradient is laid over white at 20%: the icon's orange is meant to
        // be seen for a second on a home screen, not for as long as it takes to
        // fill in a form.
        color: Colors.white,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x33FDA418), Color(0x33FB7C01)],
            ),
          ),
          child: child,
        ),
      );
}
