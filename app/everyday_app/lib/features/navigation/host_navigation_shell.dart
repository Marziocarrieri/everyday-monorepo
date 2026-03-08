import 'package:everyday_app/legacy_app/screens/main_layout.dart';
import 'package:flutter/material.dart';

class HostNavigationShell extends StatelessWidget {
  const HostNavigationShell({super.key});

  @override
  Widget build(BuildContext context) {
    // Keep HOST flow identical by reusing the current main layout.
    return const MainLayout();
  }
}
