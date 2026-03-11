import 'package:everyday_app/core/roles/app_role.dart';
import 'package:everyday_app/core/roles/route_access_policy.dart';
import 'package:flutter/material.dart';

import 'role_shell_scaffold.dart';
import 'role_tab_config.dart'; // Assicurati che l'import per RoleTabSets sia corretto

class HostNavigationShell extends StatelessWidget {
  const HostNavigationShell({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Recuperiamo le tab dell'Host da RoleTabSets e le filtriamo con la Policy
    final tabs = RoleTabSets.hostTabs()
        .where(
          (tab) => RouteAccessPolicy.canAccessRoute(
            AppRole.HOST,
            tab.routeName,
          ),
        )
        .toList();

    return RoleShellScaffold(
      initialIndex: 2, // L'Host parte dalla Home (indice 2)
      tabs: tabs,
      canAccessRoute: (routeName) =>
          RouteAccessPolicy.canAccessRoute(AppRole.HOST, routeName),
    );
  }
}