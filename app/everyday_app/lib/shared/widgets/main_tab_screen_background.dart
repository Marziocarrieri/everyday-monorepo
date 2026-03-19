import 'package:flutter/material.dart';

const mainTabScreenSoftGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFF7F3EE), Color(0xFFE7E0D8), Color(0xFFD2CBC2)],
  stops: [0.0, 0.58, 1.0],
);

class MainTabScreenBackground extends StatelessWidget {
  const MainTabScreenBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: mainTabScreenSoftGradient),
      child: child,
    );
  }
}
