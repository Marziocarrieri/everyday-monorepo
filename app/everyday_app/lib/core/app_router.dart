import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/features/fridge/presentation/screens/fridge_keeping_screen.dart';
import 'package:everyday_app/features/fridge/presentation/screens/provision_list_screen.dart';
import 'package:everyday_app/features/household/presentation/screens/create_household_screen.dart';
import 'package:everyday_app/features/household/presentation/screens/household_onboarding_screen.dart';
import 'package:everyday_app/features/household/presentation/screens/join_household_screen.dart';
import 'package:everyday_app/features/household/presentation/screens/your_home_screen.dart';
import 'package:everyday_app/features/navigation/role_shell_gate.dart';
import 'package:everyday_app/legacy_app/screens/diet_screen.dart';
import 'package:everyday_app/legacy_app/screens/family_screen.dart';
import 'package:everyday_app/legacy_app/screens/login2_screen.dart';
import 'package:everyday_app/features/pets/presentation/screens/pet_activities_screen.dart';
import 'package:everyday_app/features/pets/presentation/screens/pets_screen.dart';
import 'package:everyday_app/legacy_app/screens/welcome_screen.dart';
import 'package:everyday_app/features/personnel/presentation/screens/member_activities_screen.dart';
import 'package:everyday_app/features/tasks/data/models/task_with_details.dart';
import 'package:everyday_app/features/tasks/presentation/screens/add_task_screen.dart';
import 'package:everyday_app/features/tasks/presentation/screens/daily_task_screen.dart';
import 'package:flutter/material.dart';
import 'package:everyday_app/features/tasks/presentation/screens/week_tasks_screen.dart';
import 'package:everyday_app/features/fridge/presentation/screens/provision_history_screen.dart'; 


class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRouteNames.roleShell:
        return MaterialPageRoute(
          builder: (_) => const RoleShellGate(),
          settings: settings,
        );

      case AppRouteNames.weekTasks:
        return MaterialPageRoute(builder: (_) => const WeekTasksScreen());

      case AppRouteNames.addTask:
        final args = settings.arguments as AddTaskRouteArgs?;
        final initialTask = args?.initialTask;
        return MaterialPageRoute(
          builder: (_) => AddTaskScreen(
            assignedMemberIds: args?.assignedMemberIds,
            preselectedAssigneeUserId: args?.preselectedAssigneeUserId,
            supervisionCreationMode: args?.supervisionCreationMode ?? false,
            multiAssignMode: args?.multiAssignMode ?? false,
            initialDate: args?.initialDate,
            personalOnly: args?.personalOnly ?? false,
            initialTask: initialTask is TaskWithDetails ? initialTask : null,
          ),
          settings: settings,
        );

      case AppRouteNames.dailyTask:
        final args = settings.arguments as DailyTaskRouteArgs?;
        if (args == null) {
          return _missingArgsRoute(
            routeName: AppRouteNames.dailyTask,
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => UserTaskTimelineScreen(
            date: args.date,
            targetUserId: args.targetUserId ?? AppContext.instance.userId ?? '',
            readOnlyChecklist: args.readOnlyChecklist,
          ),
          settings: settings,
        );

      case AppRouteNames.userTaskHistory:
        final args = settings.arguments as UserTaskHistoryRouteArgs?;
        if (args == null) {
          return _missingArgsRoute(
            routeName: AppRouteNames.userTaskHistory,
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => WeekTasksScreen(
            viewMode: WeekTasksViewMode.delegated,
            targetMemberId: args.targetMemberId,
            targetUserId: args.targetUserId,
          ),
          settings: settings,
        );

      case AppRouteNames.fridgeKeeping:
        return MaterialPageRoute(
          builder: (_) => const FridgeKeepingScreen(),
          settings: settings,
        );

      case AppRouteNames.provisionList:
        return MaterialPageRoute(
          builder: (_) => const ProvisionListScreen(),
          settings: settings,
        );

      case AppRouteNames.provisionHistory:
        return MaterialPageRoute(
          builder: (_) => const ProvisionHistoryScreen(),
        );

      case AppRouteNames.memberActivities:
        final args = settings.arguments as MemberActivitiesRouteArgs?;
        if (args == null) {
          return _missingArgsRoute(
            routeName: AppRouteNames.memberActivities,
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => MemberActivitiesScreen(
            memberId: args.memberId,
            memberName: args.memberName,
            themeColor: args.themeColor,
            isPersonnel: args.isPersonnel,
          ),
          settings: settings,
        );

      case AppRouteNames.pets:
        return MaterialPageRoute(
          builder: (_) => const PetsScreen(),
          settings: settings,
        );

      case AppRouteNames.petActivities:
        final args = settings.arguments as PetActivitiesRouteArgs?;
        if (args == null) {
          return _missingArgsRoute(
            routeName: AppRouteNames.petActivities,
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) =>
              PetActivitiesScreen(petId: args.petId, petColor: args.petColor),
          settings: settings,
        );

      case AppRouteNames.yourHome:
        return MaterialPageRoute(
          builder: (_) => const YourHomeScreen(),
          settings: settings,
        );

      case AppRouteNames.householdOnboarding:
        return MaterialPageRoute(
          builder: (_) => const HouseholdOnboardingScreen(),
          settings: settings,
        );

      case AppRouteNames.createHousehold:
        return MaterialPageRoute(
          builder: (_) => const CreateHouseholdScreen(),
          settings: settings,
        );

      case AppRouteNames.joinHousehold:
        return MaterialPageRoute(
          builder: (_) => const JoinHouseholdScreen(),
          settings: settings,
        );

      case AppRouteNames.welcome:
        final args = settings.arguments as WelcomeRouteArgs?;
        return MaterialPageRoute(
          builder: (_) =>
              WelcomeScreen(fromProfile: args?.fromProfile ?? false),
          settings: settings,
        );

      case AppRouteNames.login2:
        return MaterialPageRoute(
          builder: (_) => const Login2Screen(),
          settings: settings,
        );

      //case AppRouteNames.mainLayout:
      //return MaterialPageRoute(
      //builder: (_) => const MainLayout(),
      //settings: settings,
      //);

      case AppRouteNames.diet:
        return MaterialPageRoute(
          builder: (_) => const DietScreen(),
          settings: settings,
        );

      case AppRouteNames.cohostDailyTask:
        final args = settings.arguments as CohostDailyTaskRouteArgs?;
        if (args == null) {
          return _missingArgsRoute(
            routeName: AppRouteNames.cohostDailyTask,
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => DailyTaskScreen(date: args.date),
          settings: settings,
        );

      case AppRouteNames.cohostAddTask:
        final args = settings.arguments as CohostAddTaskRouteArgs?;
        return MaterialPageRoute(
          builder: (_) => AddTaskScreen(initialDate: args?.initialDate),
          settings: settings,
        );

      case AppRouteNames.cohostFamily:
        return MaterialPageRoute(
          builder: (_) => const FamilyScreen(),
          settings: settings,
        );

      case AppRouteNames.cohostDiet:
        return MaterialPageRoute(
          builder: (_) => const DietScreen(),
          settings: settings,
        );

      case AppRouteNames.cohostYourHome:
        return MaterialPageRoute(
          builder: (_) => const YourHomeScreen(),
          settings: settings,
        );

      case AppRouteNames.cohostFridgeKeeping:
        return MaterialPageRoute(
          builder: (_) => const FridgeKeepingScreen(),
          settings: settings,
        );

      case AppRouteNames.cohostProvisionList:
        return MaterialPageRoute(
          builder: (_) => const ProvisionListScreen(),
          settings: settings,
        );

      default:
        return null;
    }
  }

  static Future<T?> navigate<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool rootNavigator = false,
  }) {
    return Navigator.of(
      context,
      rootNavigator: rootNavigator,
    ).pushNamed<T>(routeName, arguments: arguments);
  }

  static Future<T?> replace<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool rootNavigator = false,
    TO? result,
  }) {
    return Navigator.of(
      context,
      rootNavigator: rootNavigator,
    ).pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  static Future<T?> navigateAndRemoveUntil<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool rootNavigator = false,
    RoutePredicate? predicate,
  }) {
    return Navigator.of(
      context,
      rootNavigator: rootNavigator,
    ).pushNamedAndRemoveUntil<T>(
      routeName,
      predicate ?? (route) => false,
      arguments: arguments,
    );
  }

  static Route<dynamic> _missingArgsRoute({
    required String routeName,
    RouteSettings? settings,
  }) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) {
        return Scaffold(
          appBar: AppBar(title: const Text('Navigation error')),
          body: Center(child: Text('Missing arguments for route: $routeName')),
        );
      },
    );
  }
}
