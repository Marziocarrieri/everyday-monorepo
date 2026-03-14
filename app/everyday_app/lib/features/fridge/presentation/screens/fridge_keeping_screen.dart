// TODO migrate to features/fridge
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import 'package:everyday_app/core/providers/app_state_providers.dart';
import 'package:everyday_app/features/fridge/data/models/area_type.dart';
import 'package:everyday_app/features/fridge/data/models/fridge_item.dart';
import 'package:everyday_app/features/fridge/domain/services/pantry_service.dart';
import 'package:everyday_app/features/fridge/presentation/providers/fridge_providers.dart';
import 'package:everyday_app/shared/utils/date_utils.dart';
import 'package:everyday_app/shared/utils/status_color_utils.dart';

class FridgeKeepingScreen extends ConsumerStatefulWidget {
  const FridgeKeepingScreen({super.key});

  @override
  ConsumerState<FridgeKeepingScreen> createState() =>
      _FridgeKeepingScreenState();
}

class _FridgeKeepingScreenState extends ConsumerState<FridgeKeepingScreen> {
  AreaType _selectedCategory = AreaType.pantry;
  DateTime? selectedDate;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController dateTextController = TextEditingController();
  bool _isListView = true;

  // Colori Brand per coerenza
  final Color primaryColor = const Color(0xFF5A8B9E); // Azzurro
  final Color warningColor = const Color(0xFFF4A261); // Giallo/Arancio
  final Color expiredColor = const Color(0xFFF28482); // Rosso
  final Color darkTextColor = const Color(0xFF3D342C);

  // --- LOGICA COLORE SCADENZA ---
  Color _getItemColor(FridgeItem item) {
    if (item.expirationDate == null) {
      return getStatusColor('safe'); // Azzurro base se non c'è data
    }

    final now = DateTime.now();
    // Azzero l'orario per fare un confronto pulito tra i giorni
    final today = DateTime(now.year, now.month, now.day);
    final expDate = DateTime(
      item.expirationDate!.year,
      item.expirationDate!.month,
      item.expirationDate!.day,
    );

    final difference = expDate.difference(today).inDays;

    if (difference <= 0) {
      return expiredColor; // Scaduto oggi o in passato -> Rosso
    } else if (difference <= 2) {
      return warningColor; // Scade tra 1 o 2 giorni -> Giallo
    } else {
      return getStatusColor('safe'); // Tutto ok -> Azzurro
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    weightController.dispose();
    dateTextController.dispose();
    super.dispose();
  }

  Future<bool> _addItem() async {
    final trimmedName = nameController.text.trim();
    if (trimmedName.isEmpty) return false;

    final parsedQuantity = int.tryParse(quantityController.text.trim());
    final parsedWeight = int.tryParse(weightController.text.trim());

    try {
      final pantryService = ref.read(pantryServiceProvider);
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null || householdId.isEmpty) {
        return false;
      }

      await pantryService.addItem(
        householdId: householdId,
        name: trimmedName,
        area: _selectedCategory,
        quantity: parsedQuantity,
        weight: parsedWeight,
        unit: 'g',
        expirationDate: selectedDate,
      );
      return true;
    } catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
      return false;
    }
  }

  // --- DIALOG DI CONFERMA ELIMINAZIONE ---
  Future<bool?> _confirmDelete(FridgeItem item) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFF28482).withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 10))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF28482).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFF28482), size: 30),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Delete Item',
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: darkTextColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Are you sure you want to remove "${item.name}"?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: darkTextColor.withValues(alpha: 0.6)),
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: darkTextColor.withValues(alpha: 0.1), width: 1.5),
                            ),
                            child: Center(
                              child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: darkTextColor.withValues(alpha: 0.7))),
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
                              color: const Color(0xFFF28482),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: const Color(0xFFF28482).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Center(
                              child: Text('Delete', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
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
        );
      },
    );
  }

  Future<void> _deleteItem(FridgeItem item) async {
    try {
      final pantryService = ref.read(pantryServiceProvider);
      await pantryService.deleteItem(item.id);
      _showSuccessSnackBar('Item deleted');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pantryService = ref.watch(pantryServiceProvider);
    final householdId = ref.watch(currentHouseholdIdProvider);
    if (householdId == null || householdId.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            'Household context not ready',
            style: GoogleFonts.poppins(
              color: darkTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final itemsAsync = ref.watch(pantryItemsStreamProvider(householdId));
    final themeColor = getStatusColor('safe');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 30),

              _buildSearchBar(),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [_buildViewToggle(), _buildCategorySelector(context)],
              ),
              const SizedBox(height: 20),

              Expanded(
                child: itemsAsync.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF28482).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFF28482).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        error.toString(),
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFF28482),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  data: (items) {
                    final filteredItems = items
                        .where((item) => item.area == _selectedCategory)
                        .toList();

                    // Ordina la lista mettendo prima quelli scaduti/in scadenza
                    filteredItems.sort((a, b) {
                      if (a.expirationDate == null && b.expirationDate == null) return 0;
                      if (a.expirationDate == null) return 1;
                      if (b.expirationDate == null) return -1;
                      return a.expirationDate!.compareTo(b.expirationDate!);
                    });

                    return _isListView
                        ? _buildGlassList(filteredItems, pantryService)
                        : _buildSmallGlassGrid(filteredItems, pantryService);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      // NESSUN FLOATING ACTION BUTTON! Il bottone è integrato nelle liste.
    );
  }

  // ==========================================
  // UI PRINCIPALE
  // ==========================================

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: primaryColor,
              size: 20,
            ),
          ),
        ),
        Text(
          'Fridge Keeping',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.qr_code_scanner_rounded,
            color: primaryColor,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.2),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    hintStyle: GoogleFonts.poppins(
                      color: primaryColor.withValues(alpha: 0.5),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                  ),
                  style: GoogleFonts.poppins(color: darkTextColor),
                ),
              ),
              Icon(
                Icons.search_rounded,
                color: primaryColor,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.1),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isListView = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isListView ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                boxShadow: _isListView
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                Icons.view_list_rounded,
                size: 22,
                color: _isListView
                    ? primaryColor
                    : primaryColor.withValues(alpha: 0.4),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _isListView = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: !_isListView ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                boxShadow: !_isListView
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                Icons.grid_view_rounded,
                size: 22,
                color: !_isListView
                    ? primaryColor
                    : primaryColor.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCategoryModal(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: darkTextColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: darkTextColor.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedCategory.label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.9),
                    Colors.white.withValues(alpha: 0.7),
                  ],
                ),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildModalOption(AreaType.pantry),
                  const Divider(color: Colors.black12, height: 30),
                  _buildModalOption(AreaType.fridge),
                  const Divider(color: Colors.black12, height: 30),
                  _buildModalOption(AreaType.freezer),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalOption(AreaType areaType) {
    bool isSelected = _selectedCategory == areaType;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = areaType);
        Navigator.pop(context);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            areaType.label,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFFF4A261)
                  : darkTextColor,
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle_rounded, color: Color(0xFFF4A261)),
        ],
      ),
    );
  }

  // ==========================================
  // LISTE ED ELEMENTI
  // ==========================================

  Widget _buildGlassList(List<FridgeItem> items, PantryService pantryService) {
    if (items.isEmpty) return _buildEmptyState();
    
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 40), 
      itemCount: items.length + 1, // +1 per il bottone "+" alla fine
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        // Se siamo all'ultimo indice, mostriamo il bottoncino centrale
        if (index == items.length) {
          return _buildInlineAddButton();
        }

        final item = items[index];
        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF28482),
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          confirmDismiss: (direction) async {
            final shouldDelete = await _confirmDelete(item);
            if (shouldDelete != true) {
              return false;
            }

            await _deleteItem(item);
            return false;
          },
          child: _buildListItem(item, pantryService),
        );
      },
    );
  }

  Widget _buildListItem(FridgeItem item, PantryService pantryService) {
    Color iconColor = _getItemColor(item); // USO LA NUOVA LOGICA!
    
    return GestureDetector(
      onTap: () => _showItemDetailModal(item, pantryService, iconColor),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            height: 85,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.3), // Bordo col colore di stato
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.3), // Ombra col colore di stato
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.kitchen_outlined,
                    color: iconColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    item.name,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: darkTextColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: iconColor.withValues(alpha: 0.5),
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallGlassGrid(
    List<FridgeItem> items,
    PantryService pantryService,
  ) {
    if (items.isEmpty) return _buildEmptyState();

    // Usiamo una CustomScrollView per poter mettere il bottone alla fine della griglia
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1, // Card più compatte e basse!
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildSmallGridCard(items[index], pantryService),
            childCount: items.length,
          ),
        ),
        // Aggiungiamo il bottoncino sotto la griglia
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 40.0),
            child: _buildInlineAddButton(),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallGridCard(FridgeItem item, PantryService pantryService) {
    Color iconColor = _getItemColor(item); // USO LA NUOVA LOGICA!

    return GestureDetector(
      onTap: () => _showItemDetailModal(item, pantryService, iconColor),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.3), // Bordo col colore di stato
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.3), // Ombra col colore di stato
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.kitchen_outlined,
                    color: iconColor,
                    size: 22, // Ridotto un po' per la card compatta
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: darkTextColor,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- BOTTONE AGGIUNGI (In linea, scorre con gli elementi) ---
  Widget _buildInlineAddButton() {
    return Center(
      child: GestureDetector(
        onTap: () => _showAddElementModal(context),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          width: 56, 
          height: 56,
          decoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }

  // --- EMPTY STATE MAGICO ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 2),
            ),
            child: Icon(
              Icons.shopping_basket_outlined,
              size: 64,
              color: primaryColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nothing here yet',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: darkTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button below to add\ngroceries to this area.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: darkTextColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          _buildInlineAddButton(), // Bottone mostrato anche quando è vuoto
        ],
      ),
    );
  }

  Future<void> _showItemDetailModal(
    FridgeItem item,
    PantryService pantryService,
    Color itemColor, // Aggiunto per passare il colore calcolato
  ) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          FridgeItemDetailSheet(item: item, pantryService: pantryService, itemColor: itemColor,),
    );
    if (result == true && mounted) {
      _showSuccessSnackBar('Item updated');
    }
  }


  // ==========================================
  // MODAL ADD ELEMENT
  // ==========================================

  Future<void> _showAddElementModal(BuildContext context) async {
    nameController.clear();
    quantityController.clear();
    weightController.clear();
    dateTextController.clear();
    selectedDate = null;

    final themeColor = getStatusColor('safe');

    final changed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 30,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 30),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Text(
                    'Add an element',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: darkTextColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildModalTextField(
                            'Name',
                            true,
                            false,
                            controller: nameController,
                          ),
                          const SizedBox(height: 16),
                          _buildModalTextField(
                            'Weight (g) [optional]',
                            false,
                            true,
                            controller: weightController,
                          ),
                          const SizedBox(height: 16),
                          _buildModalTextField(
                            'Quantity [optional]',
                            false,
                            true,
                            controller: quantityController,
                          ),
                          const SizedBox(height: 16),
                          _buildModalTextField(
                            'Expire date [optional]',
                            false,
                            false,
                            isDate: true,
                            controller: dateTextController,
                          ),
                          const SizedBox(height: 40),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final added = await _addItem();
                                if (!context.mounted) return;
                                if (added) Navigator.pop(context, true);
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: themeColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                'Add Item',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
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
            ),
          ),
        );
      },
    );

    if (changed == true && mounted) {
      _showSuccessSnackBar('Item added');
    }
  }

  Widget _buildModalTextField(
    String label,
    bool isRequired,
    bool isNumber, {
    bool isDate = false,
    TextEditingController? controller,
  }) {
    final accentColor = getStatusColor('safe');
    final displayLabel = isRequired ? '$label *' : label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: isDate,
              onTap: isDate
                  ? () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: accentColor,
                              onPrimary: Colors.white,
                              onSurface: darkTextColor,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
                          dateTextController.text = formatDate(pickedDate);
                        });
                      }
                    }
                  : null,
              keyboardType: isNumber
                  ? TextInputType.number
                  : TextInputType.text,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: darkTextColor,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                labelText: displayLabel,
                labelStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isRequired
                      ? const Color(0xFFF28482)
                      : darkTextColor.withValues(alpha: 0.6),
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                hintText: isDate ? 'Select date...' : 'Tap to type...',
                hintStyle: GoogleFonts.poppins(
                  color: darkTextColor.withValues(alpha: 0.3),
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (isDate)
            Icon(Icons.calendar_month_rounded, color: accentColor, size: 24),
        ],
      ),
    );
  }
}

// ==========================================
// COMPONENTE: POPUP DETTAGLIO/MODIFICA 
// ==========================================
class FridgeItemDetailSheet extends StatefulWidget {
  const FridgeItemDetailSheet({
    super.key,
    required this.item,
    required this.pantryService,
    required this.itemColor, // Il colore dinamico
  });
  final FridgeItem item;
  final PantryService pantryService;
  final Color itemColor;

  @override
  State<FridgeItemDetailSheet> createState() => _FridgeItemDetailSheetState();
}

class _FridgeItemDetailSheetState extends State<FridgeItemDetailSheet> {
  bool _isEditing = false;
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _weightController;
  late final TextEditingController _expirationDateController;
  DateTime? _selectedDate;
  bool _isSaving = false;

  final Color darkTextColor = const Color(0xFF3D342C);

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.item.expirationDate;
    _nameController = TextEditingController(text: widget.item.name);
    _quantityController = TextEditingController(
      text: widget.item.quantity?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: widget.item.weight?.toString() ?? '',
    );
    _expirationDateController = TextEditingController(
      text: formatDate(widget.item.expirationDate),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _weightController.dispose();
    _expirationDateController.dispose();
    super.dispose();
  }

  DateTime? _parseDateFromInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'none') {
      return null;
    }
    final parts = trimmed.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime.tryParse(trimmed);
  }

  Future<void> _handleSaveEdit() async {
    final name = _nameController.text.trim();
    final quantityText = _quantityController.text.trim();
    final weightText = _weightController.text.trim();
    final dateText = _expirationDateController.text.trim();

    if (name.isEmpty) return;

    final quantity = quantityText.isEmpty ? null : int.tryParse(quantityText);
    final weight = weightText.isEmpty ? null : int.tryParse(weightText);

    if (weightText.isNotEmpty && weight == null) return;
    if (quantityText.isNotEmpty && quantity == null) return;

    final isDateUnset =
      dateText.isEmpty || dateText.toLowerCase() == 'none';
    final selectedDate = isDateUnset
      ? null
      : _parseDateFromInput(dateText);
    if (!isDateUnset && selectedDate == null) return;

    final updatedItem = FridgeItem(
      id: widget.item.id,
      householdId: widget.item.householdId,
      name: name,
      area: widget.item.area,
      quantity: quantity,
      weight: weight,
      unit: widget.item.unit,
      expirationDate: selectedDate,
      createdAt: widget.item.createdAt,
    );

    setState(() => _isSaving = true);
    try {
      await widget.pantryService.updateItem(updatedItem);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Uso il colore che mi è stato passato dal padre (rosso, giallo o azzurro)
    final itemColor = widget.itemColor;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 40,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 30),
                        decoration: BoxDecoration(
                          color: itemColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: itemColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: itemColor.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.kitchen_rounded,
                            color: itemColor,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _isEditing
                              ? TextField(
                                  controller: _nameController,
                                  style: GoogleFonts.poppins(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: darkTextColor,
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
                                  style: GoogleFonts.poppins(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: darkTextColor,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
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
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.edit_rounded,
                                color: itemColor,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    if (!_isEditing) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildDashCard(
                              'Weight',
                              widget.item.weight?.toString() != null
                                  ? '${widget.item.weight}g'
                                  : '-',
                              Icons.scale_rounded,
                              itemColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDashCard(
                              'Quantity',
                              widget.item.quantity?.toString() ?? '-',
                              Icons.tag_rounded,
                              itemColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final exactCardWidth =
                              (constraints.maxWidth - 16) / 2;
                          return Center(
                            child: SizedBox(
                              width: exactCardWidth,
                              child: _buildDashCard(
                                'Expire Date',
                                widget.item.expirationDate != null
                                    ? formatDate(widget.item.expirationDate)
                                    : '-',
                                Icons.calendar_today_rounded,
                                itemColor,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 30),
                    ] else ...[
                      _buildCleanEditField(
                        'Weight (g)',
                        _weightController,
                        itemColor,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildCleanEditField(
                        'Quantity',
                        _quantityController,
                        itemColor,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildCleanEditField(
                        'Expire Date',
                        _expirationDateController,
                        itemColor,
                        readOnly: true,
                        isDate: true,
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF5A8B9E),
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (pickedDate != null && mounted) {
                            setState(() {
                              _selectedDate = pickedDate;
                              _expirationDateController.text = formatDate(
                                pickedDate,
                              );
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 40),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                  _nameController.text = widget.item.name;
                                  _weightController.text =
                                      widget.item.weight?.toString() ?? '';
                                  _quantityController.text =
                                      widget.item.quantity?.toString() ?? '';
                                  _selectedDate = widget.item.expirationDate;
                                  _expirationDateController.text = formatDate(
                                    widget.item.expirationDate,
                                  );
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(
                                  color: itemColor.withValues(alpha: 0.5),
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF5A8B9E),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _handleSaveEdit,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: itemColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                'Save',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
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
                      color: Colors.white.withValues(alpha: 0.8),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(itemColor),
                        ),
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

  Widget _buildDashCard(
    String title,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: darkTextColor.withValues(alpha: 0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: value == '-' ? 16 : 18,
              fontWeight: value == '-' ? FontWeight.w500 : FontWeight.w700,
              color: value == '-'
                  ? darkTextColor.withValues(alpha: 0.3)
                  : darkTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCleanEditField(
    String label,
    TextEditingController controller,
    Color accentColor, {
    bool readOnly = false,
    VoidCallback? onTap,
    bool isDate = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              onTap: onTap,
              keyboardType: keyboardType,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: darkTextColor,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                labelText: label,
                labelStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: darkTextColor.withValues(alpha: 0.6),
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
          ),
          if (isDate)
            Icon(Icons.calendar_month_rounded, color: accentColor, size: 24),
        ],
      ),
    );
  }
}