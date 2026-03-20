import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:everyday_app/core/providers/app_state_providers.dart';
import 'package:everyday_app/features/fridge/data/models/shopping_item.dart';
import 'package:everyday_app/features/fridge/domain/services/shopping_service.dart';
import 'package:everyday_app/features/fridge/presentation/providers/fridge_providers.dart';

// --- COLORI DEL DESIGN SYSTEM ---
const _bgColor = Color(0xFFF4F1ED);
const _inkColor = Color(0xFF1F3A44);
const _appTeal = Color(0xFF5A8B9E); 
const _appCoral = Color(0xFFF28482); 
const _appOrange = Color(0xFFF4A261); 

class ProvisionHistoryScreen extends ConsumerStatefulWidget {
  const ProvisionHistoryScreen({super.key});

  @override
  ConsumerState<ProvisionHistoryScreen> createState() => _ProvisionHistoryScreenState();
}

class _ProvisionHistoryScreenState extends ConsumerState<ProvisionHistoryScreen> {
  String _searchQuery = '';
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  final Color primaryColor = const Color(0xFF5A8B9E); 
  final Color archiveColor = const Color(0xFFF4A261); 
  final Color expiredColor = const Color(0xFFF28482); // Rosso per hard delete
  final Color darkTextColor = const Color(0xFF3D342C);

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // RIPRISTINO
  Future<void> _restoreItem(String id, ShoppingService shoppingService) async {
    try {
      await shoppingService.restoreItem(id);
      _showSnackBar('Item restored to active list');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // HARD DELETE
  Future<void> _hardDeleteItem(String id, ShoppingService shoppingService) async {
    try {
      await shoppingService.deleteItem(id);
      _showSnackBar('Item permanently deleted');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // AZIONI DI GRUPPO
  Future<void> _restoreSelected(ShoppingService shoppingService) async {
    for (final id in _selectedIds) await shoppingService.restoreItem(id);
    if (!mounted) return;
    setState(() { _isSelectionMode = false; _selectedIds.clear(); });
    _showSnackBar('Items restored');
  }

  Future<void> _deleteSelected(ShoppingService shoppingService) async {
    for (final id in _selectedIds) await shoppingService.deleteItem(id);
    if (!mounted) return;
    setState(() { _isSelectionMode = false; _selectedIds.clear(); });
    _showSnackBar('Items permanently deleted');
  }

  @override
  Widget build(BuildContext context) {
    final shoppingService = ref.watch(shoppingServiceProvider);
    final householdId = ref.watch(currentHouseholdIdProvider);
    if (householdId == null || householdId.isEmpty) return const Scaffold();

    // USA IL PROVIDER DELLO STORICO
    final itemsAsync = ref.watch(historyShoppingItemsProvider(householdId));

    final currentItems = itemsAsync.valueOrNull ?? [];
    final filteredItems = currentItems.where((item) => _searchQuery.isEmpty || item.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 30),
                  _buildSearchBar(),
                  const SizedBox(height: 24),
                  // Tasto Select allineato a sinistra
                  Row(mainAxisAlignment: MainAxisAlignment.start, children: [_buildSelectionModeToggle()]),
                  const SizedBox(height: 16),
                  Expanded(
                    child: itemsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator(color: _appTeal)),
                      error: (err, _) => Center(child: Text(err.toString(), style: GoogleFonts.manrope(color: _appCoral))),
                      data: (_) {
                        if (filteredItems.isEmpty && _searchQuery.isNotEmpty) {
                          return Center(child: Text('No items found', style: GoogleFonts.manrope(color: _inkColor.withOpacity(0.5), fontWeight: FontWeight.w600, fontSize: 16)));
                        }
                        return filteredItems.isEmpty ? _buildEmptyState() : _buildGlassList(filteredItems, shoppingService);
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_isSelectionMode) Align(alignment: Alignment.bottomCenter, child: _buildBatchActionBar(filteredItems, shoppingService)),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // HEADER MINIMAL
  // ==========================================
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 44, height: 44,
                color: Colors.transparent,
                alignment: Alignment.centerLeft,
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: _inkColor, size: 24),
              ),
            ),
          ),
        ),
        Text(
          'History', 
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(fontSize: 26, fontWeight: FontWeight.w800, color: _inkColor, letterSpacing: -0.5)
        ),
        const Expanded(child: SizedBox()), // Spazio vuoto per bilanciare l'header
      ],
    );
  }

  // --- SEARCH BAR: VETRO CON PATINA BIANCA E LEGGERMENTE SCURO ---
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _inkColor.withOpacity(0.08), // Ombra morbida per elevare
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: _inkColor.withOpacity(0.03), // Scurisce leggermente lo sfondo
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.7), // Patina bianca
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search history...',
                      hintStyle: GoogleFonts.manrope(
                        color: _inkColor.withOpacity(0.4),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      border: InputBorder.none,
                    ),
                    style: GoogleFonts.manrope(
                      color: _inkColor, // Testi scuri
                      fontWeight: FontWeight.w600
                    ),
                  ),
                ),
                Icon(Icons.search_rounded, color: _inkColor.withOpacity(0.4), size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- TASTO SELECT MINIMAL ---
  Widget _buildSelectionModeToggle() {
    return GestureDetector(
      onTap: () => setState(() {
        _isSelectionMode = !_isSelectionMode;
        if (!_isSelectionMode) _selectedIds.clear(); 
      }),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isSelectionMode ? Icons.close_rounded : Icons.checklist_rounded,
              size: 20,
              color: _inkColor,
            ),
            const SizedBox(width: 6),
            Text(
              _isSelectionMode ? 'Cancel' : 'Select',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _inkColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BARRA IN BASSO (SELEZIONE) ---
  Widget _buildBatchActionBar(List<ShoppingItem> currentFilteredItems, ShoppingService shoppingService) {
    final count = _selectedIds.length;
    final total = currentFilteredItems.length;
    final hasSelection = count > 0;
    final allSelected = count == total && total > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _inkColor.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300), height: 72, padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85), // Per la barra in basso uso un bianco opaco per distinguerla
                borderRadius: BorderRadius.circular(24), 
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() {
                      if (allSelected) _selectedIds.clear();
                      else _selectedIds.addAll(currentFilteredItems.map((e) => e.id));
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: allSelected ? _inkColor.withOpacity(0.15) : (hasSelection ? _inkColor.withOpacity(0.05) : _inkColor.withOpacity(0.05)), 
                        shape: BoxShape.circle
                      ),
                      child: Icon(allSelected ? Icons.remove_done_rounded : Icons.done_all_rounded, color: hasSelection ? _inkColor : _inkColor.withOpacity(0.4), size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(count == 0 ? 'Select...' : '$count selected', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: hasSelection ? _inkColor : _inkColor.withOpacity(0.5))),
                  ),
                  if (hasSelection) ...[
                    // Bottone HARD DELETE (Rosso)
                    GestureDetector(
                      onTap: () => _deleteSelected(shoppingService),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: _appCoral.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.delete_forever_rounded, color: _appCoral, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Bottone RESTORE (Teal)
                    GestureDetector(
                      onTap: () => _restoreSelected(shoppingService), 
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _appTeal, 
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: _appTeal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.unarchive_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text('Restore', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassList(List<ShoppingItem> items, ShoppingService shoppingService) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(), padding: EdgeInsets.only(bottom: _isSelectionMode ? 100 : 20),
      itemCount: items.length, separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Dismissible(
          key: ValueKey(item.id),
          direction: _isSelectionMode ? DismissDirection.none : DismissDirection.horizontal,
          background: Container(
            decoration: BoxDecoration(color: _appTeal, borderRadius: BorderRadius.circular(24)),
            alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 24),
            child: const Icon(Icons.unarchive_rounded, color: Colors.white, size: 28),
          ),
          secondaryBackground: Container(
            decoration: BoxDecoration(color: _appCoral, borderRadius: BorderRadius.circular(24)),
            alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 24),
            child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 28),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              await _restoreItem(item.id, shoppingService);
            } else {
              await _hardDeleteItem(item.id, shoppingService);
            }
            return false;
          },
          child: _buildListItem(item),
        );
      },
    );
  }

  // --- ITEM STYLE: VETRO CON PATINA BIANCA E LEGGERMENTE SCURO ---
  Widget _buildListItem(ShoppingItem item) {
    final isSelected = _selectedIds.contains(item.id);
    Color currentBorderColor = _isSelectionMode && isSelected 
        ? _inkColor.withOpacity(0.3) 
        : Colors.white.withOpacity(0.7); // Patina bianca

    return GestureDetector(
      onTap: _isSelectionMode ? () => setState(() {
        if (_selectedIds.contains(item.id)) _selectedIds.remove(item.id);
        else _selectedIds.add(item.id);
      }) : null, 
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _inkColor.withOpacity(0.08), // Ombra per elevare
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200), height: 72, padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                // Scurisce leggermente il fondo per lo storico
                color: _isSelectionMode && isSelected ? _inkColor.withOpacity(0.08) : _inkColor.withOpacity(0.03),
                borderRadius: BorderRadius.circular(24), 
                border: Border.all(color: currentBorderColor, width: 1.5),
              ),
              child: Row(
                children: [
                  // Icona di selezione SOLO in Selection Mode (Nessun pallino!)
                  if (_isSelectionMode) ...[
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.circle_outlined, 
                      color: isSelected ? _inkColor : _inkColor.withOpacity(0.3), 
                      size: 26
                    ),
                    const SizedBox(width: 16),
                  ],
                  
                  Expanded(
                    child: Text(
                      item.name, 
                      style: GoogleFonts.manrope(
                        fontSize: 18, 
                        fontWeight: FontWeight.w700, 
                        // Nello storico il testo è leggermente sbiadito e barrato
                        color: _inkColor.withOpacity(0.5), 
                        decoration: TextDecoration.lineThrough, 
                        decorationColor: _inkColor.withOpacity(0.3)
                      ), 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis
                    )
                  ),
                  if (item.quantity > 1 && !_isSelectionMode)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
                      child: Text('Qty: ${item.quantity}', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: _inkColor.withOpacity(0.4))),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4), 
              shape: BoxShape.circle, 
              border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
            ),
            child: Icon(Icons.history_rounded, size: 64, color: _inkColor.withOpacity(0.15)),
          ),
          const SizedBox(height: 24),
          Text('History is clear.', style: GoogleFonts.manrope(color: _inkColor, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Archived items will appear here.', textAlign: TextAlign.center, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: _inkColor.withOpacity(0.5))),
        ],
      ),
    );
  }
}