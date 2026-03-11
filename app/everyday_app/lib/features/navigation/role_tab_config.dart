import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/features/home/presentation/screens/home_screen.dart';
import 'package:everyday_app/legacy_app/screens/family_screen.dart';
import 'package:everyday_app/legacy_app/screens/profile_screen.dart';
import 'package:everyday_app/legacy_app/screens/utilities_screen.dart';
import 'package:everyday_app/features/personnel/presentation/screens/personnel_screen.dart';
import 'package:flutter/material.dart';

typedef RoleTabBuilder = Widget Function(BuildContext context);

class RoleTabConfig {
  final String routeName;
  final String label;
  final IconData icon;
  final RoleTabBuilder builder;

  const RoleTabConfig({
    required this.routeName,
    required this.label,
    required this.icon,
    required this.builder,
  });
}

class RoleTabSets {
  static List<RoleTabConfig> hostTabs() {
    return [
      RoleTabConfig(
        routeName: AppRouteNames.hostTabUtilities,
        label: 'Utilities',
        icon: Icons.kitchen_rounded,
        // TODO(role-shell): replace legacy utilities wrapper with feature-native utilities tab.
        builder: (_) => const UtilitiesScreen(),
      ),
      RoleTabConfig(
        routeName: AppRouteNames.hostTabPersonnel,
        label: 'Personnel',
        icon: Icons.face_retouching_natural,
        builder: (_) => const PersonnelScreen(),
      ),
      RoleTabConfig(
        routeName: AppRouteNames.hostTabHome,
        label: 'Home',
        icon: Icons.home_filled,
        builder: (_) => const HomeScreen(),
      ),
      RoleTabConfig(
        routeName: AppRouteNames.hostTabFamily,
        label: 'Family',
        icon: Icons.public,
        // TODO(role-shell): replace legacy family wrapper with feature-native family/personnel view.
        builder: (_) => const FamilyScreen(),
      ),
      RoleTabConfig(
        routeName: AppRouteNames.hostTabProfile,
        label: 'Profile',
        icon: Icons.person_outline,
        // TODO(role-shell): replace legacy profile wrapper with role-native profile experience.
        builder: (_) => const ProfileScreen(),
      ),
    ];
  }

  static List<RoleTabConfig> cohostTabs() {
    return [
      RoleTabConfig(
        routeName: AppRouteNames.cohostTabUtilities,
        label: 'Utilities',
        icon: Icons.kitchen_rounded,
        // TODO(role-shell): replace legacy utilities wrapper with cohost-native utilities tab.
        builder: (_) => const UtilitiesScreen(),
      ),
      RoleTabConfig(
        routeName: AppRouteNames.cohostTabHome,
        label: 'Home',
        icon: Icons.home_filled,
        builder: (_) => const HomeScreen(),
      ),
      RoleTabConfig(
        routeName: AppRouteNames.cohostTabProfile,
        label: 'Profile',
        icon: Icons.person_outline,

        builder: (_) => const ProfileScreen(),
      ),
    ];
  }

  static List<RoleTabConfig> personnelTabs() {
    return [
      RoleTabConfig(
        routeName: AppRouteNames.personnelTabUtilities,
        label: 'Utilities',
        icon: Icons.kitchen_rounded,
        // TODO(role-shell): replace legacy utilities wrapper with personnel-native utilities tab.
        builder: (_) => const UtilitiesScreen(),
      ),
      RoleTabConfig(
        routeName: AppRouteNames.personnelTabHome,
        label: 'Home',
        icon: Icons.home_filled,
        builder: (_) => const HomeScreen(),
      ),
      RoleTabConfig(
        routeName: AppRouteNames.personnelTabProfile,
        label: 'Profile',
        icon: Icons.person_outline,
        // TODO(role-shell): replace legacy profile wrapper with personnel-native profile tab.
        builder: (_) => const ProfileScreen(),
      ),
    ];
  }
}
