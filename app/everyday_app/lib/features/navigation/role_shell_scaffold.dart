import 'dart:ui';

import 'package:everyday_app/features/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'role_tab_config.dart';

class RoleShellScaffold extends StatefulWidget {
  final List<RoleTabConfig> tabs;
  final int initialIndex;
  final bool Function(String routeName)? canAccessRoute;
  final void Function(BuildContext context, String routeName)? onBlockedRoute;

  const RoleShellScaffold({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
    this.canAccessRoute,
    this.onBlockedRoute,
  });

  @override
  State<RoleShellScaffold> createState() => _RoleShellScaffoldState();
}

class _RoleShellScaffoldState extends State<RoleShellScaffold> {
  late final List<Widget> _pages;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _resolveInitialIndex();
    _pages = widget.tabs
        .map((tab) => Builder(builder: (context) => tab.builder(context)))
        .toList();
  }

  bool _canAccess(String routeName) {
    return widget.canAccessRoute?.call(routeName) ?? true;
  }

  int _resolveInitialIndex() {
    if (widget.tabs.isEmpty) return 0;

    final rawIndex = widget.initialIndex;
    final clampedIndex = rawIndex < 0
        ? 0
        : rawIndex >= widget.tabs.length
            ? widget.tabs.length - 1
            : rawIndex;

    if (_canAccess(widget.tabs[clampedIndex].routeName)) {
      return clampedIndex;
    }

    final firstAccessible = widget.tabs.indexWhere(
      (tab) => _canAccess(tab.routeName),
    );

    return firstAccessible >= 0 ? firstAccessible : 0;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tabs.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No tabs configured')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildPremiumBottomNav(context),
    );
  }

  IconData _refinedIcon(IconData icon) {
    if (icon == Icons.home_filled) return Icons.home_rounded;
    if (icon == Icons.person_outline) return Icons.person_rounded;
    return icon;
  }

  Widget _buildPremiumBottomNav(BuildContext context) {
    const selectedColor = Color(0xFF243C4A);
    final unselectedColor = selectedColor.withValues(alpha: 0.42);

    return SafeArea(
      bottom: true,
      child: Container(
        height: 62,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withValues(alpha: 0.18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              color: Colors.transparent,
              child: Row(
                children: List.generate(widget.tabs.length, (index) {
                  final tab = widget.tabs[index];
                  final isSelected = _selectedIndex == index;
                  final isProfileTab = index == widget.tabs.length - 1;
                  final iconColor = isSelected ? selectedColor : unselectedColor;
                  final displayIcon = _refinedIcon(tab.icon);

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        final routeName = tab.routeName;

                        if (!_canAccess(routeName)) {
                          widget.onBlockedRoute?.call(context, routeName);
                          return;
                        }

                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      onLongPress: isProfileTab
                          ? () => showProfileHouseholdBottomSheet(context)
                          : null,
                      child: Center(
                        child: Semantics(
                          label: tab.label,
                          selected: isSelected,
                          button: true,
                          child: AnimatedScale(
                            scale: isSelected ? 1.08 : 1.0,
                            duration: const Duration(milliseconds: 160),
                            curve: Curves.easeOutCubic,
                            child: Icon(
                              displayIcon,
                              color: iconColor,
                              size: 23,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}