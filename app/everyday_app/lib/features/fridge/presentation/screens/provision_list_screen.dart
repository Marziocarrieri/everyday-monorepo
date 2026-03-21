// TODO migrate to features/fridge
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/core/providers/app_state_providers.dart';
import 'package:everyday_app/features/fridge/data/models/shopping_item.dart';
import 'package:everyday_app/features/fridge/domain/services/shopping_service.dart';
import 'package:everyday_app/features/fridge/presentation/providers/fridge_providers.dart';
import 'package:everyday_app/shared/utils/status_color_utils.dart';
import 'package:everyday_app/features/fridge/data/models/recommended_item.dart';
import 'package:everyday_app/features/fridge/data/repositories/recommended_item_repository.dart';

// --- COLORI DEL DESIGN SYSTEM ---
const _bgColor = Color(0xFFF4F1ED);
const _inkColor = Color(0xFF1F3A44);
const _appTeal = Color(0xFF5A8B9E);
const _appCoral = Color(0xFFF28482);
const _appOrange = Color(0xFFF4A261);

class ProvisionListScreen extends ConsumerStatefulWidget {
  final bool openAddOnLaunch;

  const ProvisionListScreen({super.key, this.openAddOnLaunch = false});

  @override
  ConsumerState<ProvisionListScreen> createState() =>
      _ProvisionListScreenState();
}

class _ProvisionListScreenState extends ConsumerState<ProvisionListScreen> {
  String _searchQuery = '';
  bool _isDeleteMode = false;
  bool _didOpenAddOnLaunch = false;
  final Set<String> _selectedIdsForDeletion = {};

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _appTeal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --- DIALOG DI CONFERMA ARCHIVIAZIONE SINGOLA ---
  Future<bool?> _confirmMoveToHistory(ShoppingItem item) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: _appOrange.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _appOrange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.archive_outlined,
                    color: _appOrange,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Move to History?',
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _inkColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This will move "${item.name}" to your history. You can restore it later.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _inkColor.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(false),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _inkColor.withOpacity(0.1),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _inkColor.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(true),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: _appOrange,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _appOrange.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Move',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- DIALOG DI CONFERMA ARCHIVIAZIONE MULTIPLA ---
  Future<bool?> _confirmBatchArchive(int count) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: _appOrange.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _appOrange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.archive_outlined,
                    color: _appOrange,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Archive Items?',
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _inkColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to move $count items to your history?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _inkColor.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(false),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _inkColor.withOpacity(0.1),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _inkColor.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(true),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: _appOrange,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _appOrange.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Move',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _moveToHistoryItem(String id, ShoppingService shoppingService) async {
    try {
      await shoppingService.moveToHistory(id);
      _showSuccessSnackBar('Moved to history');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _moveToHistorySelectedItems(ShoppingService shoppingService) async {
    if (_selectedIdsForDeletion.isEmpty) return;

    final confirmed = await _confirmBatchArchive(_selectedIdsForDeletion.length);
    if (confirmed != true) return;

    try {
      for (final id in _selectedIdsForDeletion) {
        await shoppingService.moveToHistory(id);
      }
      if (!mounted) return;
      setState(() {
        _isDeleteMode = false;
        _selectedIdsForDeletion.clear();
      });
      _showSuccessSnackBar('Items moved to history');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _toggleSelection(String itemId) {
    setState(() {
      if (_selectedIdsForDeletion.contains(itemId)) {
        _selectedIdsForDeletion.remove(itemId);
      } else {
        _selectedIdsForDeletion.add(itemId);
      }
    });
  }

  Future<void> _openAddModal(ShoppingService shoppingService) async {
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null || householdId.isEmpty) return;
    final changed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddProvisionSheet(
        shoppingService: shoppingService,
        householdId: householdId,
      ),
    );
    if (changed == true && mounted) _showSuccessSnackBar('Item added');
  }

  Future<void> _openDetailModal(ShoppingItem item, ShoppingService shoppingService) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ProvisionDetailSheet(item: item, shoppingService: shoppingService),
    );
    if (changed == true && mounted) _showSuccessSnackBar('Item updated');
  }

  @override
  Widget build(BuildContext context) {
    final shoppingService = ref.watch(shoppingServiceProvider);
    final householdId = ref.watch(currentHouseholdIdProvider);

    if (widget.openAddOnLaunch && !_didOpenAddOnLaunch && householdId != null && householdId.isNotEmpty) {
      _didOpenAddOnLaunch = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openAddModal(shoppingService);
      });
    }

    if (householdId == null || householdId.isEmpty) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: Center(
          child: Text(
            'Household context not ready',
            style: GoogleFonts.manrope(
              color: _inkColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final itemsAsync = ref.watch(activeShoppingItemsProvider(householdId));

    final currentItems = itemsAsync.valueOrNull ?? [];
    final filteredItems = currentItems
        .where((item) => _searchQuery.isEmpty || item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

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
                  const SizedBox(height: 32),
                  
                  // SEARCH BAR PIU' STRETTA
                  _buildSearchBar(),
                  
                  // SPAZIO EQUIDISTANTE SUPERIORE
                  const SizedBox(height: 26), 
                  
                  // TASTO SELECT A DESTRA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end, 
                    children: [_buildDeleteModeToggle()],
                  ),
                  
                  // SPAZIO INFERIORE AZZERATO (compensato dal padding della lista)
                  const SizedBox(height: 0),
                  
                  Expanded(
                    child: itemsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator(color: _appTeal)),
                      error: (err, _) => Center(
                        child: Text(
                          err.toString(),
                          style: GoogleFonts.manrope(color: _appCoral),
                        )
                      ),
                      data: (_) {
                        if (filteredItems.isEmpty && _searchQuery.isNotEmpty) {
                          return Center(
                            child: Text(
                              'No items found',
                              style: GoogleFonts.manrope(
                                color: _inkColor.withOpacity(0.5),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return filteredItems.isEmpty
                            ? _buildEmptyState(shoppingService)
                            : _buildGlassList(filteredItems, shoppingService);
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_isDeleteMode)
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildBatchArchiveBar(filteredItems, shoppingService),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // HEADER MINIMAL (SENZA SFONDO BIANCO)
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
                width: 44,
                height: 44,
                color: Colors.transparent, 
                alignment: Alignment.centerLeft, 
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: _inkColor, size: 24),
              ),
            ),
          ),
        ),
        Text(
          'Provision List',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _inkColor,
            letterSpacing: -0.5,
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pushNamed(AppRouteNames.provisionHistory),
              child: Container(
                width: 44,
                height: 44,
                color: Colors.transparent, 
                alignment: Alignment.centerRight, 
                child: const Icon(Icons.history_rounded, color: _inkColor, size: 28),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- SEARCH BAR: STRETTA E COMPATTA ---
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0), 
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
            child: Container(
              height: 50, // Altezza ridotta
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _inkColor.withOpacity(0.03), 
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.7), 
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search items...',
                        hintStyle: GoogleFonts.manrope(
                          color: _inkColor.withOpacity(0.4),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: GoogleFonts.manrope(
                        color: _inkColor, 
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Icon(Icons.search_rounded, color: _inkColor.withOpacity(0.4), size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- TASTO SELECT MINIMAL ---
  Widget _buildDeleteModeToggle() {
    return GestureDetector(
      onTap: () => setState(() {
        _isDeleteMode = !_isDeleteMode;
        if (!_isDeleteMode) _selectedIdsForDeletion.clear();
      }),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isDeleteMode ? Icons.close_rounded : Icons.checklist_rounded,
              size: 20,
              color: _inkColor,
            ),
            const SizedBox(width: 6),
            Text(
              _isDeleteMode ? 'Cancel' : 'Select',
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
  Widget _buildBatchArchiveBar(List<ShoppingItem> currentFilteredItems, ShoppingService shoppingService) {
    final count = _selectedIdsForDeletion.length;
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
              duration: const Duration(milliseconds: 300),
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: hasSelection
                    ? _appOrange.withOpacity(0.85)
                    : _inkColor.withOpacity(0.03), // Scurisce leggermente
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: hasSelection
                      ? _appOrange.withOpacity(0.9)
                      : Colors.white.withOpacity(0.7),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() {
                      if (allSelected)
                        _selectedIdsForDeletion.clear();
                      else
                        _selectedIdsForDeletion.addAll(
                          currentFilteredItems.map((e) => e.id),
                        );
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: allSelected
                            ? Colors.white.withOpacity(0.4)
                            : (hasSelection
                                ? Colors.white.withOpacity(0.2)
                                : _inkColor.withOpacity(0.05)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        allSelected
                            ? Icons.remove_done_rounded
                            : Icons.done_all_rounded,
                        color: hasSelection ? Colors.white : _inkColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      count == 0
                          ? 'Select items...'
                          : (allSelected
                              ? 'All selected ($count)'
                              : '$count selected'),
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: hasSelection
                            ? Colors.white
                            : _inkColor.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasSelection)
                    GestureDetector(
                      onTap: () => _moveToHistorySelectedItems(shoppingService),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.archive_outlined,
                              color: _appOrange,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Archive',
                              style: GoogleFonts.manrope(
                                color: _appOrange,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
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
      ),
    );
  }

  // ==========================================
  // LISTA CON IL TASTO ADD IN FONDO
  // ==========================================
  Widget _buildGlassList(List<ShoppingItem> items, ShoppingService shoppingService) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: _isDeleteMode ? 100 : 40), 
      itemCount: _isDeleteMode ? items.length : items.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (!_isDeleteMode && index == items.length) {
          return _buildInlineAddButton(shoppingService);
        }

        final item = items[index];
        return Dismissible(
          key: ValueKey(item.id),
          direction: _isDeleteMode
              ? DismissDirection.none
              : DismissDirection.endToStart,
          background: Container(
            decoration: BoxDecoration(
              color: _appOrange,
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(
              Icons.archive_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          confirmDismiss: (direction) async {
            final shouldArchive = await _confirmMoveToHistory(item);
            if (shouldArchive == true)
              await _moveToHistoryItem(item.id, shoppingService);
            return false;
          },
          child: _buildListItem(item, shoppingService),
        );
      },
    );
  }

  // --- ITEM STYLE: VETRO CON PATINA BIANCA E LEGGERMENTE SCURO ---
  Widget _buildListItem(ShoppingItem item, ShoppingService shoppingService) {
    final isSelected = _selectedIdsForDeletion.contains(item.id);
    Color currentBorderColor = _isDeleteMode && isSelected
        ? _appOrange
        : Colors.white.withOpacity(0.7); // Patina bianca

    return GestureDetector(
      onTap: _isDeleteMode
          ? () => _toggleSelection(item.id)
          : () => _openDetailModal(item, shoppingService),
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
              duration: const Duration(milliseconds: 200),
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: _isDeleteMode && isSelected
                    ? _appOrange.withOpacity(0.15) 
                    : _inkColor.withOpacity(0.03), // Scurisce leggermente
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: currentBorderColor, width: 1.5),
              ),
              child: Row(
                children: [
                  // Icona di selezione SOLO se siamo in Delete Mode
                  if (_isDeleteMode) ...[
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: isSelected
                          ? _appOrange
                          : _inkColor.withOpacity(0.3),
                      size: 26,
                    ),
                    const SizedBox(width: 16),
                  ],
                  
                  Expanded(
                    child: Text(
                      item.name,
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _inkColor, // Testo scuro come prima
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  if (item.quantity > 1 && !_isDeleteMode)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7), 
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Qty: ${item.quantity}',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _appTeal,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- BOTTONCINO "+" TONDO SCURO SOTTO LA LISTA ---
  Widget _buildInlineAddButton(ShoppingService shoppingService) {
    return Center(
      child: GestureDetector(
        onTap: () => _openAddModal(shoppingService),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _inkColor, 
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _inkColor.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ShoppingService shoppingService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.8),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.shopping_bag_rounded,
              size: 64,
              color: _appTeal.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your list is empty.',
            style: GoogleFonts.manrope(
              color: _inkColor,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 32),
          _buildInlineAddButton(shoppingService),
        ],
      ),
    );
  }
}

// ==========================================
// MODAL: ADD PROVISION
// ==========================================
class _AddProvisionSheet extends StatefulWidget {
  const _AddProvisionSheet({
    required this.shoppingService,
    required this.householdId,
  });

  final ShoppingService shoppingService;
  final String householdId;

  @override
  State<_AddProvisionSheet> createState() => _AddProvisionSheetState();
}

class _AddProvisionSheetState extends State<_AddProvisionSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  bool _isSaving = false;
  List<RecommendedItem> recommendedItems = [];

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      final repo = RecommendedItemRepository();
      final items = await repo.getItems();

      if (mounted) {
        setState(() {
          recommendedItems = items;
        });
      }
    } catch (e) {
      debugPrint("Error loading recommendations: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final RecommendedItem? recommendedItem = recommendedItems
        .cast<RecommendedItem?>()
        .firstWhere(
          (item) => item?.name.toLowerCase() == name.toLowerCase(),
          orElse: () => null,
        );
    if (name.isEmpty) return;

    final parsedQuantity = int.tryParse(_quantityController.text.trim());
    final quantity = parsedQuantity == null || parsedQuantity <= 0
        ? 1
        : parsedQuantity;

    setState(() => _isSaving = true);

    await widget.shoppingService.addItem(
      widget.householdId,
      name,
      quantity: quantity,
      recommendedItemId: recommendedItem?.id,
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.80,
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 30,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95), 
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 30),
                      decoration: BoxDecoration(
                        color: _inkColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Text(
                    'Add a Provision',
                    style: GoogleFonts.manrope(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: _inkColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildPremiumAutocompleteField(
                            'Name',
                            true,
                            false,
                            _nameController,
                            _appTeal,
                            recommendedItems,
                          ),
                          const SizedBox(height: 16),
                          _buildPremiumTextField(
                            'Quantity',
                            false,
                            true,
                            _quantityController,
                            _appTeal,
                          ),
                          const SizedBox(height: 40),

                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: _appTeal.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _appTeal,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  'Add Item',
                                  style: GoogleFonts.manrope(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_isSaving)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(0.8),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_appTeal),
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

  // --- CAMPI MODAL CON VETRO ---
  Widget _buildPremiumTextField(
    String label,
    bool isRequired,
    bool isNumber,
    TextEditingController controller,
    Color accentColor,
  ) {
    final displayLabel = isRequired ? '$label *' : label;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _inkColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: _inkColor.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
            ),
            child: TextField(
              controller: controller,
              keyboardType: isNumber ? TextInputType.number : TextInputType.text,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _inkColor,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                labelText: displayLabel,
                labelStyle: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isRequired ? _appCoral : _inkColor.withOpacity(0.6),
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                hintText: 'Tap to enter...',
                hintStyle: GoogleFonts.manrope(
                  color: _inkColor.withOpacity(0.3),
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildPremiumAutocompleteField(
  String label,
  bool isRequired,
  bool isNumber,
  TextEditingController controller,
  Color accentColor,
  List<RecommendedItem> recommendations,
) {
  final displayLabel = isRequired ? '$label *' : label;

  return Autocomplete<RecommendedItem>(
    displayStringForOption: (RecommendedItem option) => option.name,

    optionsBuilder: (TextEditingValue textEditingValue) {
      if (textEditingValue.text.isEmpty) {
        return const Iterable<RecommendedItem>.empty();
      }
      return recommendations.where((RecommendedItem option) {
        return option.name.toLowerCase().contains(
          textEditingValue.text.toLowerCase(),
        );
      });
    },

    onSelected: (RecommendedItem selection) {
      controller.text = selection.name;
    },

    fieldViewBuilder: (context, autoController, focusNode, onFieldSubmitted) {
      if (autoController.text != controller.text) {
        autoController.text = controller.text;
      }

      autoController.addListener(() {
        controller.text = autoController.text;
      });

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _inkColor.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _inkColor.withOpacity(0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.7),
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: autoController,
                focusNode: focusNode,
                keyboardType: isNumber ? TextInputType.number : TextInputType.text,
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _inkColor,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  labelText: displayLabel,
                  labelStyle: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isRequired
                        ? _appCoral
                        : _inkColor.withOpacity(0.6),
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hintText: 'Tap to type...',
                  hintStyle: GoogleFonts.manrope(
                    color: _inkColor.withOpacity(0.3),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },

    optionsViewBuilder: (context, onSelected, options) {
      return Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(24),
          color: Colors.transparent, // Lo facciamo trasparente per il blur
          child: Container(
            width: MediaQuery.of(context).size.width - 48,
            constraints: const BoxConstraints(maxHeight: 250),
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
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9), // Un po' più solido qui per leggerezza
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final RecommendedItem option = options.elementAt(index);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _appTeal.withOpacity(0.1),
                          backgroundImage: NetworkImage(option.picture),
                        ),
                        title: Text(
                          option.name,
                          style: GoogleFonts.manrope(
                            color: _inkColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

// ==========================================
// MODAL: EDIT PROVISION
// ==========================================
class _ProvisionDetailSheet extends StatefulWidget {
  const _ProvisionDetailSheet({
    required this.item,
    required this.shoppingService,
  });

  final ShoppingItem item;
  final ShoppingService shoppingService;

  @override
  State<_ProvisionDetailSheet> createState() => _ProvisionDetailSheetState();
}

class _ProvisionDetailSheetState extends State<_ProvisionDetailSheet> {
  bool _isEditing = false;
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _quantityController = TextEditingController(
      text: widget.item.quantity.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _saveEdit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) return;

    final hasNameChanged = name != widget.item.name;
    final hasQuantityChanged = quantity != widget.item.quantity;
    if (!hasNameChanged && !hasQuantityChanged) {
      if (!mounted) return;
      Navigator.pop(context, false);
      return;
    }

    setState(() => _isSaving = true);

    final updated = ShoppingItem(
      id: widget.item.id,
      householdId: widget.item.householdId,
      name: name,
      quantity: quantity,
      status: widget.item.status,
      recommendedItem: widget.item.recommendedItem,
    );

    try {
      await widget.shoppingService.updateItem(updated);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 40,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 30),
                      decoration: BoxDecoration(
                        color: _inkColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: _isEditing
                            ? TextField(
                                controller: _nameController,
                                style: GoogleFonts.manrope(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: _inkColor,
                                  letterSpacing: -0.5,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  hintText: 'Name',
                                ),
                              )
                            : Text(
                                widget.item.name,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: _inkColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                      ),
                      if (!_isEditing)
                        GestureDetector(
                          onTap: () => setState(() => _isEditing = true),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: _appTeal,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  if (!_isEditing) ...[
                    // VIEW MODE: Dashboard Card
                    _buildDashCard(
                      'Quantity',
                      widget.item.quantity.toString(),
                      Icons.tag_rounded,
                      _appTeal,
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    // EDIT MODE
                    _buildPremiumTextField(
                      'Quantity',
                      _quantityController,
                      _appTeal,
                    ),
                    const SizedBox(height: 40),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                                _nameController.text = widget.item.name;
                                _quantityController.text = widget.item.quantity
                                    .toString();
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: _inkColor.withOpacity(0.2),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.manrope(
                                color: _inkColor.withOpacity(0.7),
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _appTeal.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _saveEdit,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: _appTeal,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                'Save',
                                style: GoogleFonts.manrope(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              if (_isSaving)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(0.8),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_appTeal),
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

  Widget _buildDashCard(
    String title,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    final textColor = const Color(0xFF3D342C);
    return Container(
      width: double.infinity,
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
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _inkColor.withOpacity(0.03), 
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: accentColor),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumTextField(
    String label,
    TextEditingController controller,
    Color accentColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _inkColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: _inkColor.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
            ),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _inkColor,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                labelText: label,
                labelStyle: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _inkColor.withOpacity(0.6),
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                hintText: 'Tap to enter...',
                hintStyle: GoogleFonts.manrope(
                  color: _inkColor.withOpacity(0.3),
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}