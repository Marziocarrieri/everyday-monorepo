import 'dart:ui';

import 'package:everyday_app/legacy_app/household_ui/profile_screen.dart';
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
      backgroundColor: Colors.white, // Sfondo bianco ripristinato
      // extendBody a false previene che il contenuto vada sotto la barra
      extendBody: false, 
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      // Sostituiamo il BottomNavigationBar nativo con la barra Premium
      bottomNavigationBar: _buildPremiumBottomNav(context),
    );
  }

  // --- BARRA PREMIUM STILE MAIN_LAYOUT ---
  Widget _buildPremiumBottomNav(BuildContext context) {
    const selectedColor = Color(0xFF243C4A);
    final unselectedColor = selectedColor.withValues(alpha: 0.35);

    return SafeArea(
      bottom: true,
      child: Container(
        height: 74,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.20),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.20),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              color: Colors.transparent,
              child: Row(
                children: List.generate(widget.tabs.length, (index) {
                  final tab = widget.tabs[index];
                  final isSelected = _selectedIndex == index;
                  final isProfileTab = index == widget.tabs.length - 1;
                  final iconColor = isSelected ? selectedColor : unselectedColor;
                  final labelOpacity = isSelected ? 1.0 : 0.45;

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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedScale(
                              scale: isSelected ? 1.1 : 1.0,
                              duration: const Duration(milliseconds: 160),
                              curve: Curves.easeOutCubic,
                              child: Icon(
                                tab.icon,
                                color: iconColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Opacity(
                              opacity: labelOpacity,
                              child: Text(
                                tab.label,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: selectedColor,
                                ),
                              ),
                            ),
                          ],
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