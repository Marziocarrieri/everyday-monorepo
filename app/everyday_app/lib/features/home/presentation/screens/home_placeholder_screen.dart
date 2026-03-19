import 'dart:ui';

import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/core/app_router.dart';
import 'package:everyday_app/core/providers/app_state_providers.dart';
import 'package:everyday_app/features/fridge/data/models/area_type.dart';
import 'package:everyday_app/features/personnel/data/models/household_member.dart';
import 'package:everyday_app/features/pets/data/models/pet.dart';
import 'package:everyday_app/features/pets/presentation/providers/pets_providers.dart';
import 'package:everyday_app/features/pets/presentation/sheets/select_pet_sheet.dart';
import 'package:everyday_app/legacy_app/utilities_ui/family_screen.dart'
    show openFamilyMemberSelectionSheet, FamilyMemberSelectionFlowMode;
import 'package:everyday_app/shared/widgets/main_tab_screen_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _homeInk = Color(0xFF1F3A44);
const _maxActiveQuickActions = 6;
const _quickActionsPrefsKey = 'home.quick_actions.active.v1';

const _actionAddTask = 'add_task';
const _actionViewMemberActivity = 'view_member_activity';
const _actionAddPantry = 'add_pantry';
const _actionAddFridge = 'add_fridge';
const _actionAddFreezer = 'add_freezer';
const _actionAddShoppingList = 'add_shopping_list';
const _actionAddHomeBar = 'add_home_bar';
const _actionAddHousehold = 'add_household';
const _actionAddPersonalCare = 'add_personal_care';
const _actionAddPetActivity = 'add_pet_activity';
const _actionViewPetActivity = 'view_pet_activity';

const _defaultQuickActionIds = <String>[
  _actionAddTask,
  _actionViewMemberActivity,
  _actionAddPantry,
  _actionAddFridge,
  _actionAddFreezer,
  _actionAddShoppingList,
];

const _quickActionCatalog = <_QuickActionCatalogEntry>[
  _QuickActionCatalogEntry(
    id: _actionAddTask,
    title: 'Add a task',
    icon: Icons.add_task_rounded,
  ),
  _QuickActionCatalogEntry(
    id: _actionViewMemberActivity,
    title: 'View member activity',
    icon: Icons.groups_2_rounded,
  ),
  _QuickActionCatalogEntry(
    id: _actionAddPantry,
    title: 'Add to pantry',
    icon: Icons.inventory_2_rounded,
  ),
  _QuickActionCatalogEntry(
    id: _actionAddFridge,
    title: 'Add to fridge',
    icon: Icons.kitchen_rounded,
  ),
  _QuickActionCatalogEntry(
    id: _actionAddFreezer,
    title: 'Add to freezer',
    icon: Icons.ac_unit_rounded,
  ),
  _QuickActionCatalogEntry(
    id: _actionAddShoppingList,
    title: 'Add to shopping list',
    icon: Icons.shopping_cart_checkout_rounded,
  ),
  _QuickActionCatalogEntry(
    id: _actionAddHomeBar,
    title: 'Add to home bar',
    icon: Icons.wine_bar_rounded,
  ),
  _QuickActionCatalogEntry(
    id: _actionAddHousehold,
    title: 'Add to household',
    icon: Icons.cleaning_services_rounded,
  ),
  _QuickActionCatalogEntry(
    id: _actionAddPersonalCare,
    title: 'Add to personal care',
    icon: Icons.spa_rounded,
  ),
  _QuickActionCatalogEntry(
    id: _actionAddPetActivity,
    title: 'Add pet activity',
    icon: Icons.pets_rounded,
  ),
  _QuickActionCatalogEntry(
    id: _actionViewPetActivity,
    title: 'View pet activity',
    icon: Icons.pets_outlined,
  ),
];

class HomePlaceholderScreen extends ConsumerStatefulWidget {
  const HomePlaceholderScreen({super.key});

  @override
  ConsumerState<HomePlaceholderScreen> createState() =>
      _HomePlaceholderScreenState();
}

class _HomePlaceholderScreenState extends ConsumerState<HomePlaceholderScreen> {
  Set<String> _selectedActionIds = _defaultQuickActionIds.toSet();

  @override
  void initState() {
    super.initState();
    _loadQuickActionSelection();
  }

  Future<void> _loadQuickActionSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final storedIds = prefs.getStringList(_quickActionsPrefsKey);
    final normalized = storedIds == null
        ? List<String>.from(_defaultQuickActionIds)
        : _normalizeSelectedActionIds(storedIds);

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedActionIds = normalized.toSet();
    });
  }

  Future<void> _persistQuickActionSelection(List<String> selectedIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_quickActionsPrefsKey, selectedIds);
  }

  List<String> _normalizeSelectedActionIds(Iterable<String> source) {
    final selectedSet = source.toSet();
    final normalized = <String>[];

    for (final entry in _quickActionCatalog) {
      if (!selectedSet.contains(entry.id)) {
        continue;
      }
      normalized.add(entry.id);
      if (normalized.length >= _maxActiveQuickActions) {
        break;
      }
    }

    return normalized;
  }

  void _showMaxQuickActionsSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'You can select up to $_maxActiveQuickActions quick actions.',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _openQuickActionsEditor(BuildContext context) async {
    final selectedFromEditor = await showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _QuickActionsCustomizationSheet(
        catalog: _quickActionCatalog,
        initialSelectedIds: _selectedActionIds,
        maxSelected: _maxActiveQuickActions,
        onMaxSelectedReached: () => _showMaxQuickActionsSnackBar(context),
      ),
    );

    if (selectedFromEditor == null) {
      return;
    }

    final normalized = _normalizeSelectedActionIds(selectedFromEditor);
    setState(() {
      _selectedActionIds = normalized.toSet();
    });
    await _persistQuickActionSelection(normalized);
  }

  void _openAgentChatEntry(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Agent chat entry will be available soon.',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),
    );
    debugPrint('Agent chat entry placeholder tapped');
  }

  List<String> _activeSelectedIds() {
    return _normalizeSelectedActionIds(_selectedActionIds);
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(householdMembersStreamProvider);
    final householdId = ref.watch(currentHouseholdIdProvider);
    final petsAsync = (householdId == null || householdId.isEmpty)
        ? const AsyncValue<List<Pet>>.data(<Pet>[])
        : ref.watch(petsStreamProvider(householdId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MainTabScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
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
                        _buildAgentReportCard(context),
                        const SizedBox(height: 20),
                        _buildQuickActionsCard(
                          context,
                          membersAsync,
                          petsAsync,
                        ),
                      ],
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

  Widget _buildHeader() {
    return const SizedBox(height: 46, child: _HomeHeader());
  }

  Widget _buildAgentReportCard(BuildContext context) {
    return _GlassSectionCard(
      gradientColors: const [Color(0xFF6B8EA5), Color(0xFF3D5D72)],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 210),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Agent Report',
                  style: GoogleFonts.manrope(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _openAgentChatEntry(context),
                    child: Ink(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.48),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
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
    AsyncValue<List<Pet>> petsAsync,
  ) {
    final actionById = <String, _QuickActionData>{
      _actionAddTask: _QuickActionData(
        id: _actionAddTask,
        title: 'Add a task',
        icon: Icons.add_task_rounded,
        onTap: () => openFamilyMemberSelectionSheet(
          context,
          membersAsync,
          flowMode: FamilyMemberSelectionFlowMode.addTask,
        ),
      ),
      _actionViewMemberActivity: _QuickActionData(
        id: _actionViewMemberActivity,
        title: 'View member activity',
        icon: Icons.groups_2_rounded,
        onTap: () => openFamilyMemberSelectionSheet(
          context,
          membersAsync,
          flowMode: FamilyMemberSelectionFlowMode.viewActivity,
        ),
      ),
      _actionAddPantry: _QuickActionData(
        id: _actionAddPantry,
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
      _actionAddFridge: _QuickActionData(
        id: _actionAddFridge,
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
      _actionAddFreezer: _QuickActionData(
        id: _actionAddFreezer,
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
      _actionAddShoppingList: _QuickActionData(
        id: _actionAddShoppingList,
        title: 'Add to shopping list',
        icon: Icons.shopping_cart_checkout_rounded,
        onTap: () => AppRouter.navigate<void>(
          context,
          AppRouteNames.provisionList,
          arguments: const ProvisionListRouteArgs(openAddOnLaunch: true),
        ),
      ),
      _actionAddHomeBar: _QuickActionData(
        id: _actionAddHomeBar,
        title: 'Add to home bar',
        icon: Icons.wine_bar_rounded,
        onTap: () => AppRouter.navigate<void>(
          context,
          AppRouteNames.fridgeKeeping,
          arguments: const FridgeKeepingRouteArgs(
            initialArea: AreaType.spirits,
            openAddOnLaunch: true,
          ),
        ),
      ),
      _actionAddHousehold: _QuickActionData(
        id: _actionAddHousehold,
        title: 'Add to household',
        icon: Icons.cleaning_services_rounded,
        onTap: () => AppRouter.navigate<void>(
          context,
          AppRouteNames.fridgeKeeping,
          arguments: const FridgeKeepingRouteArgs(
            initialArea: AreaType.household,
            openAddOnLaunch: true,
          ),
        ),
      ),
      _actionAddPersonalCare: _QuickActionData(
        id: _actionAddPersonalCare,
        title: 'Add to personal care',
        icon: Icons.spa_rounded,
        onTap: () => AppRouter.navigate<void>(
          context,
          AppRouteNames.fridgeKeeping,
          arguments: const FridgeKeepingRouteArgs(
            initialArea: AreaType.personalCare,
            openAddOnLaunch: true,
          ),
        ),
      ),
      _actionAddPetActivity: _QuickActionData(
        id: _actionAddPetActivity,
        title: 'Add pet activity',
        icon: Icons.pets_rounded,
        onTap: () => openPetSelectionSheet(
          context,
          petsAsync,
          flowMode: PetSelectionFlowMode.addActivity,
        ),
      ),
      _actionViewPetActivity: _QuickActionData(
        id: _actionViewPetActivity,
        title: 'View pet activity',
        icon: Icons.pets_outlined,
        onTap: () => openPetSelectionSheet(
          context,
          petsAsync,
          flowMode: PetSelectionFlowMode.viewActivity,
        ),
      ),
    };

    final activeIds = _activeSelectedIds();
    final activeActions = <_QuickActionData>[];
    for (final id in activeIds) {
      final action = actionById[id];
      if (action != null) {
        activeActions.add(action);
      }
    }

    return _GlassSectionCard(
      gradientColors: const [Color(0xFFDABBA4), Color(0xFF8FAFA8)],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 260),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Actions',
                  style: GoogleFonts.manrope(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2E3E46),
                  ),
                ),
                GestureDetector(
                  onTap: () => _openQuickActionsEditor(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.38),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.62),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.tune_rounded,
                          size: 14,
                          color: Color(0xFF2E3E46),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Edit',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2E3E46),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (activeActions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'No quick actions selected. Tap Edit to choose up to 6.',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2E3E46).withValues(alpha: 0.7),
                  ),
                ),
              )
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  for (final action in activeActions)
                    _QuickActionTile(action: action),
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
                color: gradientColors.first.withValues(alpha: 0.35),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.1),
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

class _QuickActionsCustomizationSheet extends StatefulWidget {
  final List<_QuickActionCatalogEntry> catalog;
  final Set<String> initialSelectedIds;
  final int maxSelected;
  final VoidCallback onMaxSelectedReached;

  const _QuickActionsCustomizationSheet({
    required this.catalog,
    required this.initialSelectedIds,
    required this.maxSelected,
    required this.onMaxSelectedReached,
  });

  @override
  State<_QuickActionsCustomizationSheet> createState() =>
      _QuickActionsCustomizationSheetState();
}

class _QuickActionsCustomizationSheetState
    extends State<_QuickActionsCustomizationSheet> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = <String>{};
    for (final entry in widget.catalog) {
      if (_selectedIds.length >= widget.maxSelected) {
        break;
      }
      if (widget.initialSelectedIds.contains(entry.id)) {
        _selectedIds.add(entry.id);
      }
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        return;
      }
      if (_selectedIds.length >= widget.maxSelected) {
        widget.onMaxSelectedReached();
        return;
      }
      _selectedIds.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    const titleInk = Color(0xFF1F3A44);
    const brandBlue = Color(0xFF5A8B9E);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.86,
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFF7F3EF).withValues(alpha: 0.95),
                Colors.white.withValues(alpha: 0.82),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: brandBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Customize Actions',
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: titleInk,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: brandBlue.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${_selectedIds.length}/${widget.maxSelected} selected',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: brandBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select up to ${widget.maxSelected} quick actions.',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: titleInk.withValues(alpha: 0.65),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      for (final entry in widget.catalog)
                        _buildCatalogItem(entry, brandBlue, titleInk),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => Navigator.pop(context, _selectedIds),
                child: Container(
                  width: double.infinity,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF5A8B9E), Color(0xFF3E6D81)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5A8B9E).withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Save Selection',
                      style: GoogleFonts.manrope(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogItem(
    _QuickActionCatalogEntry entry,
    Color brandBlue,
    Color titleInk,
  ) {
    final isSelected = _selectedIds.contains(entry.id);

    return GestureDetector(
      onTap: () => _toggleSelection(entry.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [const Color(0xFFE3EFF4), const Color(0xFFF7FAFC)]
                : [
                    Colors.white.withValues(alpha: 0.88),
                    Colors.white.withValues(alpha: 0.56),
                  ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? brandBlue.withValues(alpha: 0.42)
                : Colors.white.withValues(alpha: 0.9),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                shape: BoxShape.circle,
              ),
              child: Icon(entry.icon, size: 17, color: titleInk),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry.title,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: titleInk,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected ? brandBlue : titleInk.withValues(alpha: 0.35),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCatalogEntry {
  final String id;
  final String title;
  final IconData icon;

  const _QuickActionCatalogEntry({
    required this.id,
    required this.title,
    required this.icon,
  });
}

class _QuickActionData {
  final String id;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.id,
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
