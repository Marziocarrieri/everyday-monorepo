import 'package:everyday_app/core/roles/app_role.dart';
import 'package:everyday_app/core/roles/route_access_policy.dart';
import 'package:flutter/material.dart';

import 'role_shell_scaffold.dart';
import 'role_tab_config.dart';

class CohostNavigationShell extends StatelessWidget {
  const CohostNavigationShell({super.key});

  @override
  Widget build(BuildContext context) {
    final tabs = RoleTabSets.cohostTabs()
        .where(
          (tab) => RouteAccessPolicy.canAccessRoute(
            AppRole.COHOST,
            tab.routeName,
          ),
        )
        .toList();

    return RoleShellScaffold(
      initialIndex: 1,
      tabs: tabs,
      canAccessRoute: (routeName) =>
          RouteAccessPolicy.canAccessRoute(AppRole.COHOST, routeName),
    );
  }
}
