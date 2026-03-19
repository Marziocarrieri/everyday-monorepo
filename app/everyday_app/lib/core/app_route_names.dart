import 'package:flutter/material.dart';

class AppRouteNames {
  static const String roleShell = '/app/role-shell';

  static const String hostTabUtilities = '/tabs/host/utilities';
  static const String hostTabPersonnel = '/tabs/host/personnel';
  static const String hostTabHome = '/tabs/host/home';
  static const String hostTabFamily = '/tabs/host/family';
  static const String hostTabProfile = '/tabs/host/profile';

  static const String cohostTabHome = '/tabs/cohost/home';
  static const String cohostTabUtilities = '/tabs/cohost/utilities';
  static const String cohostTabProfile = '/tabs/cohost/profile';

  static const String personnelTabHome = '/tabs/personnel/home';
  static const String personnelTabUtilities = '/tabs/personnel/utilities';
  static const String personnelTabProfile = '/tabs/personnel/profile';

  static const String addTask = '/tasks/add';
  static const String dailyTask = '/tasks/daily';
  static const String weekTasks = '/week-tasks';
  static const String userTaskHistory = '/tasks/history/user';
  static const String fridgeKeeping = '/fridge/keeping';
  static const String provisionList = '/fridge/provision-list';
  static const String memberActivities = '/personnel/member-activities';
  static const String pets = '/legacy/pets';
  static const String petActivities = '/legacy/pets/activities';
  static const String yourHome = '/household/your-home';
  static const String householdOnboarding = '/household/onboarding';
  static const String createHousehold = '/household/create';
  static const String joinHousehold = '/household/join';
  static const String profileSettings = '/settings/profile';
  static const String welcome = '/legacy/welcome';
  static const String login2 = '/legacy/login2';
  static const String mainLayout = '/legacy/main-layout';
  static const String diet = '/legacy/diet';
  static const String provisionHistory = '/provision-history';

  static const String cohostDailyTask = '/legacy/cohost/daily-task';
  static const String cohostAddTask = '/legacy/cohost/add-task';
  static const String cohostFamily = '/legacy/cohost/family';
  static const String cohostDiet = '/legacy/cohost/diet';
  static const String cohostYourHome = '/legacy/cohost/your-home';
  static const String cohostFridgeKeeping = '/legacy/cohost/fridge-keeping';
  static const String cohostProvisionList = '/legacy/cohost/provision-list';
}

class WeekTasksRouteArgs {
  final String? initialMemberId;
  final String? initialUserId;

  const WeekTasksRouteArgs({this.initialMemberId, this.initialUserId});
}

class AddTaskRouteArgs {
  final Set<String>? assignedMemberIds;
  final String? preselectedAssigneeUserId;
  final bool supervisionCreationMode;
  final bool multiAssignMode;
  final DateTime? initialDate;
  final bool personalOnly;
  final Object? initialTask;

  const AddTaskRouteArgs({
    this.assignedMemberIds,
    this.preselectedAssigneeUserId,
    this.supervisionCreationMode = false,
    this.multiAssignMode = false,
    this.initialDate,
    this.personalOnly = false,
    this.initialTask,
  });
}

class DailyTaskRouteArgs {
  final DateTime date;
  final String? targetUserId;
  final bool readOnlyChecklist;

  const DailyTaskRouteArgs({
    required this.date,
    this.targetUserId,
    this.readOnlyChecklist = false,
  });
}

class UserTaskHistoryRouteArgs {
  final String targetMemberId;
  final String? targetUserId;

  const UserTaskHistoryRouteArgs({
    required this.targetMemberId,
    this.targetUserId,
  });
}

class MemberActivitiesRouteArgs {
  final String memberId;
  final String memberName;
  final Color themeColor;
  final bool isPersonnel;

  const MemberActivitiesRouteArgs({
    required this.memberId,
    required this.memberName,
    required this.themeColor,
    this.isPersonnel = false,
  });
}

class WelcomeRouteArgs {
  final bool fromProfile;

  const WelcomeRouteArgs({this.fromProfile = false});
}

class PetActivitiesRouteArgs {
  final String petId;
  final Color petColor;

  const PetActivitiesRouteArgs({required this.petId, required this.petColor});
}

class CohostDailyTaskRouteArgs {
  final DateTime date;

  const CohostDailyTaskRouteArgs({required this.date});
}

class CohostAddTaskRouteArgs {
  final DateTime? initialDate;

  const CohostAddTaskRouteArgs({this.initialDate});
}

class FridgeKeepingRouteArgs {
  final Object
  initialArea; // Passiamo Object per non importare AreaType qui creando dipendenze strane, faremo il cast dopo
  final bool openAddOnLaunch;

  const FridgeKeepingRouteArgs({
    required this.initialArea,
    this.openAddOnLaunch = false,
  });
}

class ProvisionListRouteArgs {
  final bool openAddOnLaunch;

  const ProvisionListRouteArgs({this.openAddOnLaunch = false});
}
