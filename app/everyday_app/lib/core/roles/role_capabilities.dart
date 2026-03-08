import 'app_role.dart';

class RoleCapabilities {
  final bool canCreateTask;
  final bool canAssignTask;
  final bool canManagePersonnel;
  final bool canEditTasks;
  final bool canSelfAssignTasks;

  const RoleCapabilities({
    required this.canCreateTask,
    required this.canAssignTask,
    required this.canManagePersonnel,
    required this.canEditTasks,
    required this.canSelfAssignTasks,
  });

  factory RoleCapabilities.forRole(AppRole role) {
    switch (role) {
      case AppRole.HOST:
        return const RoleCapabilities(
          canCreateTask: true,
          canAssignTask: true,
          canManagePersonnel: true,
          canEditTasks: true,
          canSelfAssignTasks: true,
        );
      case AppRole.COHOST:
        return const RoleCapabilities(
          canCreateTask: true,
          canAssignTask: false,
          canManagePersonnel: false,
          canEditTasks: true,
          canSelfAssignTasks: true,
        );
      case AppRole.PERSONNEL:
        return const RoleCapabilities(
          canCreateTask: false,
          canAssignTask: false,
          canManagePersonnel: false,
          canEditTasks: false,
          canSelfAssignTasks: false,
        );
    }
  }
}
