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
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          final routeName = widget.tabs[index].routeName;
          if (!_canAccess(routeName)) {
            widget.onBlockedRoute?.call(context, routeName);
            return;
          }

          setState(() {
            _selectedIndex = index;
          });
        },
        items: widget.tabs
            .map(
              (tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
