import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:everyday_app/core/providers/app_state_providers.dart';
import 'package:everyday_app/features/fridge/data/models/shopping_item.dart';
import 'package:everyday_app/features/fridge/domain/services/shopping_service.dart';
import 'package:everyday_app/features/fridge/presentation/providers/fridge_providers.dart';

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
        content: Text(message, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
      backgroundColor: Colors.white,
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
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [_buildSelectionModeToggle()]),
                  const SizedBox(height: 20),
                  Expanded(
                    child: itemsAsync.when(
                      loading: () => Center(child: CircularProgressIndicator(color: archiveColor)),
                      error: (err, _) => Center(child: Text(err.toString())),
                      data: (_) {
                        if (filteredItems.isEmpty && _searchQuery.isNotEmpty) {
                          return Center(child: Text('No items found', style: GoogleFonts.poppins(color: darkTextColor.withOpacity(0.5))));
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: archiveColor.withOpacity(0.2), width: 1.5), boxShadow: [BoxShadow(color: archiveColor.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 6))]),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: archiveColor, size: 20),
          ),
        ),
        Text('History', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: archiveColor)),
        const SizedBox(width: 48), // Spazio vuoto per bilanciare
      ],
    );
  }

  Widget _buildSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          height: 55, padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: archiveColor.withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: archiveColor.withOpacity(0.2), width: 1.2)),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(hintText: 'Search history...', hintStyle: GoogleFonts.poppins(color: archiveColor.withOpacity(0.5), fontSize: 15), border: InputBorder.none),
                  style: GoogleFonts.poppins(color: darkTextColor),
                ),
              ),
              Icon(Icons.search_rounded, color: archiveColor, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionModeToggle() {
    return GestureDetector(
      onTap: () => setState(() {
        _isSelectionMode = !_isSelectionMode;
        if (!_isSelectionMode) _selectedIds.clear(); 
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isSelectionMode ? archiveColor : Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _isSelectionMode ? archiveColor : archiveColor.withOpacity(0.1), width: 1.2),
        ),
        child: Icon(Icons.checklist_rounded, size: 22, color: _isSelectionMode ? Colors.white : archiveColor.withOpacity(0.5)),
      ),
    );
  }

  Widget _buildBatchActionBar(List<ShoppingItem> currentFilteredItems, ShoppingService shoppingService) {
    final count = _selectedIds.length;
    final total = currentFilteredItems.length;
    final hasSelection = count > 0;
    final allSelected = count == total && total > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300), height: 70, padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(24), border: Border.all(color: archiveColor.withOpacity(0.5), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() {
                    if (allSelected) _selectedIds.clear();
                    else _selectedIds.addAll(currentFilteredItems.map((e) => e.id));
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: allSelected ? archiveColor.withOpacity(0.2) : archiveColor.withOpacity(0.05), shape: BoxShape.circle),
                    child: Icon(allSelected ? Icons.remove_done_rounded : Icons.done_all_rounded, color: archiveColor, size: 22),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(count == 0 ? 'Select...' : '$count selected', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: darkTextColor)),
                ),
                if (hasSelection) ...[
                  // Bottone RESTORE
                  GestureDetector(
                    onTap: () => _restoreSelected(shoppingService),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.restore_rounded, color: primaryColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bottone HARD DELETE
                  GestureDetector(
                    onTap: () => _deleteSelected(shoppingService),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: expiredColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.delete_forever_rounded, color: expiredColor),
                    ),
                  ),
                ]
              ],
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
          // Se non è in selection mode, permetti lo swipe da entrambe le parti!
          direction: _isSelectionMode ? DismissDirection.none : DismissDirection.horizontal,
          background: Container(
            decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(20)),
            alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 24),
            child: const Icon(Icons.restore_rounded, color: Colors.white, size: 28),
          ),
          secondaryBackground: Container(
            decoration: BoxDecoration(color: expiredColor, borderRadius: BorderRadius.circular(20)),
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

  Widget _buildListItem(ShoppingItem item) {
    final isSelected = _selectedIds.contains(item.id);
    Color currentBorderColor = _isSelectionMode && isSelected ? archiveColor : Colors.white.withOpacity(0.8);
    
    return GestureDetector(
      onTap: _isSelectionMode ? () => setState(() {
        if (_selectedIds.contains(item.id)) _selectedIds.remove(item.id);
        else _selectedIds.add(item.id);
      }) : null, // Se non in selezione, non fa nulla (è read-only)
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200), height: 70, padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: _isSelectionMode && isSelected ? archiveColor.withOpacity(0.15) : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20), border: Border.all(color: currentBorderColor, width: isSelected ? 2.0 : 1.5),
            ),
            child: Row(
              children: [
                if (_isSelectionMode) Icon(isSelected ? Icons.check_circle_rounded : Icons.circle_outlined, color: isSelected ? archiveColor : Colors.grey.withOpacity(0.5), size: 28)
                else Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.withOpacity(0.3), width: 2))),
                const SizedBox(width: 16),
                Expanded(child: Text(item.name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: darkTextColor, decoration: TextDecoration.lineThrough, decorationColor: darkTextColor.withOpacity(0.3)), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
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
          Icon(Icons.history_rounded, size: 60, color: archiveColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('Your history is empty.', style: GoogleFonts.poppins(color: darkTextColor.withOpacity(0.5), fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}