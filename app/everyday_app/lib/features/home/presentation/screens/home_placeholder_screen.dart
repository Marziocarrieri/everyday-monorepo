import 'dart:ui';

import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/core/app_router.dart';
import 'package:everyday_app/core/providers/app_state_providers.dart';
import 'package:everyday_app/features/fridge/data/models/area_type.dart';
import 'package:everyday_app/features/personnel/data/models/household_member.dart';
import 'package:everyday_app/legacy_app/utilities_ui/family_screen.dart'
    show openFamilyMemberSelectionSheet, FamilyMemberSelectionFlowMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

const _homeBackground = Color(0xFFF4F1ED);
const _homeInk = Color(0xFF1F3A44);

class HomePlaceholderScreen extends ConsumerWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(householdMembersStreamProvider);

    return Scaffold(
      backgroundColor: _homeBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAgentReportCard(),
                      const SizedBox(height: 20),
                      _buildQuickActionsCard(context, membersAsync),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const SizedBox(height: 46, child: _HomeHeader());
  }

  Widget _buildAgentReportCard() {
    return _GlassSectionCard(
      gradientColors: const [Color(0xCC809AAA), Color(0xB35A7484)],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 210),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agent Report',
              style: GoogleFonts.manrope(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your household summary will appear here.',
              style: GoogleFonts.manrope(
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Insights, trends, and daily highlights are coming soon.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () =>
                    debugPrint('Regenerate report placeholder tapped'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.58)),
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(
                  'Regenerate report',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(
    BuildContext context,
    AsyncValue<List<HouseholdMember>> membersAsync,
  ) {
    final actions = <_QuickActionData>[
      _QuickActionData(
        title: 'Add a task',
        icon: Icons.add_task_rounded,
        onTap: () => openFamilyMemberSelectionSheet(
          context,
          membersAsync,
          flowMode: FamilyMemberSelectionFlowMode.addTask,
        ),
      ),
      _QuickActionData(
        title: 'View member activity',
        icon: Icons.groups_2_rounded,
        onTap: () => openFamilyMemberSelectionSheet(
          context,
          membersAsync,
          flowMode: FamilyMemberSelectionFlowMode.viewActivity,
        ),
      ),
      _QuickActionData(
        title: 'Add to pantry',
        icon: Icons.inventory_2_rounded,
        onTap: () => AppRouter.navigate<void>(
          context,
          AppRouteNames.fridgeKeeping,
          arguments: const FridgeKeepingRouteArgs(
            initialArea: AreaType.pantry,
            openAddOnLaunch: true,
          ),
        ),
      ),
      _QuickActionData(
        title: 'Add to fridge',
        icon: Icons.kitchen_rounded,
        onTap: () => AppRouter.navigate<void>(
          context,
          AppRouteNames.fridgeKeeping,
          arguments: const FridgeKeepingRouteArgs(
            initialArea: AreaType.fridge,
            openAddOnLaunch: true,
          ),
        ),
      ),
      _QuickActionData(
        title: 'Add to freezer',
        icon: Icons.ac_unit_rounded,
        onTap: () => AppRouter.navigate<void>(
          context,
          AppRouteNames.fridgeKeeping,
          arguments: const FridgeKeepingRouteArgs(
            initialArea: AreaType.freezer,
            openAddOnLaunch: true,
          ),
        ),
      ),
      _QuickActionData(
        title: 'Add to shopping list',
        icon: Icons.shopping_cart_checkout_rounded,
        onTap: () => AppRouter.navigate<void>(
          context,
          AppRouteNames.provisionList,
          arguments: const ProvisionListRouteArgs(openAddOnLaunch: true),
        ),
      ),
    ];

    return _GlassSectionCard(
      gradientColors: const [Color(0xCCE7C6B1), Color(0xB3A0D2CB)],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 260),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: GoogleFonts.manrope(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2E3E46),
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [
                for (final action in actions) _QuickActionTile(action: action),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 42),
        Expanded(
          child: Center(
            child: Text(
              'Home',
              style: GoogleFonts.manrope(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _homeInk,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_none_rounded,
            size: 26,
            color: _homeInk,
          ),
          splashRadius: 22,
        ),
      ],
    );
  }
}

class _GlassSectionCard extends StatelessWidget {
  final List<Color> gradientColors;
  final Widget child;

  const _GlassSectionCard({required this.gradientColors, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.14),
                blurRadius: 10,
                offset: const Offset(-4, -4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _QuickActionData {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

class _QuickActionTile extends StatelessWidget {
  final _QuickActionData action;

  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.58),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.62),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    action.icon,
                    size: 17,
                    color: const Color(0xFF2E3E46),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    action.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E3E46),
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
