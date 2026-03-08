import 'package:everyday_app/core/app_context.dart';

import 'app_role.dart';

class RoleResolver {
  static AppRole resolveCurrentRole() {
    final role = AppContext.instance.activeMembership?.role;
    return resolveFromString(role);
  }

  static AppRole resolveFromString(String? role) {
    switch (role?.toUpperCase()) {
      case 'COHOST':
        return AppRole.COHOST;
      case 'PERSONNEL':
        return AppRole.PERSONNEL;
      case 'HOST':
      default:
        return AppRole.HOST;
    }
  }
}
