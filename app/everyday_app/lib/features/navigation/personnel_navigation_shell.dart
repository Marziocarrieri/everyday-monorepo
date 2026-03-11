import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/core/roles/app_role.dart';
import 'package:everyday_app/core/roles/route_access_policy.dart';
import 'package:flutter/material.dart';

import 'role_shell_scaffold.dart';
import 'role_tab_config.dart';

class PersonnelNavigationShell extends StatelessWidget {
  const PersonnelNavigationShell({super.key});

  void _showBlockedRouteMessage(BuildContext context, String routeName) {
    String message = 'Route not allowed for personnel.';

    if (routeName == AppRouteNames.addTask) {
      message = 'Personnel cannot create tasks.';
    } else if (routeName == AppRouteNames.memberActivities ||
        routeName == AppRouteNames.hostTabPersonnel) {
      message = 'Personnel management is not available for this role.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = RoleTabSets.personnelTabs()
        .where(
          (tab) => RouteAccessPolicy.canAccessRoute(
            AppRole.PERSONNEL,
            tab.routeName,
          ),
        )
        .toList();

    return RoleShellScaffold(
      // Home is the first tab for personnel.
      initialIndex: 1,
      tabs: tabs,
      canAccessRoute: (routeName) =>
          RouteAccessPolicy.canAccessRoute(AppRole.PERSONNEL, routeName),
      onBlockedRoute: _showBlockedRouteMessage,
    );
  }
}
