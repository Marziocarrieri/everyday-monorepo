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
      // FONDAMENTALE: Fa scorrere il contenuto della pagina SOTTO la barra fluttuante!
      extendBody: true, 
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      // Sostituiamo il BottomNavigationBar nativo con la barra Premium
      bottomNavigationBar: _buildPremiumBottomNav(context),
    );
  }

  // --- NUOVA BARRA PREMIUM LIQUID GLASS ---
  Widget _buildPremiumBottomNav(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: Container(
        height: 65,
        margin: const EdgeInsets.only(left: 30, right: 30, bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white, width: 2), // Riflesso del vetro
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(widget.tabs.length, (index) {
            final tab = widget.tabs[index];
            final isSelected = _selectedIndex == index;
            
            // Verifichiamo se è l'ultimo tab (Profilo)
            final isProfileTab = index == widget.tabs.length - 1;
            
            // Colori premium
            final iconColor = isSelected 
                ? const Color(0xFF5A8B9E) 
                : const Color(0xFF3D342C).withValues(alpha: 0.4);

            return GestureDetector(
              behavior: HitTestBehavior.opaque, // Rende cliccabile tutto lo spazio interno
              onTap: () {
                final routeName = tab.routeName;
                
                // Controllo accessi originale intatto
                if (!_canAccess(routeName)) {
                  widget.onBlockedRoute?.call(context, routeName);
                  return;
                }
                
                setState(() {
                  _selectedIndex = index;
                });
              },
              
              // PRESSIONE PROLUNGATA: Apre il menu delle case se siamo sul Profilo
              // (usa Ctrl + Punto / Cmd + Punto per importare questa funzione!)
              onLongPress: isProfileTab 
                  ? () => showProfileHouseholdBottomSheet(context)
                  : null,
                  
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                // Effetto "Rimbalzo/Zoom" sull'icona selezionata
                child: AnimatedScale(
                  scale: isSelected ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    tab.icon,
                    color: iconColor,
                    size: 26,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}