import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/core/roles/app_role.dart';
import 'package:everyday_app/core/roles/role_resolver.dart';
import 'package:flutter/material.dart';

import 'cohost_navigation_shell.dart';
import 'host_navigation_shell.dart';
import 'personnel_navigation_shell.dart';

class RoleShellGate extends StatelessWidget {
  const RoleShellGate({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppContext.instance,
      builder: (context, _) {
        final role = RoleResolver.resolveCurrentRole();
        return _buildShellForRole(role);
      },
    );
  }

  Widget _buildShellForRole(AppRole role) {
    switch (role) {
      case AppRole.HOST:
        return const HostNavigationShell();
      case AppRole.COHOST:
        return const CohostNavigationShell();
      case AppRole.PERSONNEL:
        return const PersonnelNavigationShell();
    }
  }
}
