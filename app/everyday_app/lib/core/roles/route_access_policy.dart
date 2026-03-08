import 'package:everyday_app/core/app_route_names.dart';

import 'app_role.dart';
import 'role_capabilities.dart';

class RouteAccessPolicy {
  static bool canAccessRoute(AppRole role, String routeName) {
    final capabilities = RoleCapabilities.forRole(role);

    switch (routeName) {
      case AppRouteNames.roleShell:
      case AppRouteNames.login2:
      case AppRouteNames.welcome:
        return true;

      case AppRouteNames.hostTabUtilities:
      case AppRouteNames.hostTabPersonnel:
      case AppRouteNames.hostTabHome:
      case AppRouteNames.hostTabFamily:
      case AppRouteNames.hostTabProfile:
        return role == AppRole.HOST;

      case AppRouteNames.cohostTabHome:
      case AppRouteNames.cohostTabUtilities:
      case AppRouteNames.cohostTabProfile:
        return role == AppRole.COHOST;

      case AppRouteNames.personnelTabHome:
      case AppRouteNames.personnelTabUtilities:
      case AppRouteNames.personnelTabProfile:
        return role == AppRole.PERSONNEL;

      case AppRouteNames.mainLayout:
        return role == AppRole.HOST;

      case AppRouteNames.addTask:
        return capabilities.canCreateTask;

      case AppRouteNames.dailyTask:
      case AppRouteNames.householdOnboarding:
      case AppRouteNames.petActivities:
      case AppRouteNames.cohostDailyTask:
      case AppRouteNames.cohostAddTask:
      case AppRouteNames.cohostFamily:
      case AppRouteNames.cohostDiet:
      case AppRouteNames.cohostYourHome:
      case AppRouteNames.cohostFridgeKeeping:
      case AppRouteNames.cohostProvisionList:
        return true;

      case AppRouteNames.memberActivities:
        return role != AppRole.PERSONNEL;

      case AppRouteNames.createHousehold:
      case AppRouteNames.joinHousehold:
      case AppRouteNames.yourHome:
        return role == AppRole.HOST;

      case AppRouteNames.fridgeKeeping:
      case AppRouteNames.provisionList:
      case AppRouteNames.pets:
      case AppRouteNames.diet:
        return true;

      default:
        return true;
    }
  }
}
