// TODO migrate to features/fridge
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import 'package:everyday_app/core/providers/app_state_providers.dart';
import 'package:everyday_app/features/fridge/data/models/area_type.dart';
import 'package:everyday_app/features/fridge/data/models/fridge_item.dart';
import 'package:everyday_app/features/fridge/domain/services/pantry_service.dart';
import 'package:everyday_app/features/fridge/domain/services/shopping_service.dart';
import 'package:everyday_app/features/fridge/presentation/providers/fridge_providers.dart';
import 'package:everyday_app/shared/utils/date_utils.dart';
import 'package:everyday_app/features/fridge/data/models/recommended_item.dart';
import 'package:everyday_app/features/fridge/data/repositories/recommended_item_repository.dart';

// --- COLORI DEL DESIGN SYSTEM ---
const _bgColor = Color(0xFFF4F1ED);
const _inkColor = Color(0xFF1F3A44);
const _appTeal = Color(0xFF5A8B9E);
const _appCoral = Color(0xFFF28482);
const _appOrange = Color(0xFFF4A261);

class FridgeKeepingScreen extends ConsumerStatefulWidget {
  final Object? initialArea; // Argomento in ingresso dal router
  final bool openAddOnLaunch;

  const FridgeKeepingScreen({
    super.key,
    this.initialArea,
    this.openAddOnLaunch = false,
  });

  @override
  ConsumerState<FridgeKeepingScreen> createState() =>
      _FridgeKeepingScreenState();
}

class _FridgeKeepingScreenState extends ConsumerState<FridgeKeepingScreen> {
  late AreaType _selectedCategory;
  bool _didOpenAddOnLaunch = false;
  DateTime? selectedDate;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController dateTextController = TextEditingController();

  bool _isListView = true;
  bool _isDeleteMode = false;
  String _searchQuery = '';
  final Set<String> _selectedIdsForDeletion = {};

  List<RecommendedItem> recommendedItems = [];

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
    // Imposta la categoria iniziale se è stata passata, altrimenti usa pantry come default
    _selectedCategory = (widget.initialArea as AreaType?) ?? AreaType.pantry;

    if (widget.openAddOnLaunch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _didOpenAddOnLaunch) return;
        _didOpenAddOnLaunch = true;
        _showAddElementModal(context);
      });
    }
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

  Color _getItemColor(FridgeItem item) {
    if (item.expirationDate == null) return _appTeal;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expDate = DateTime(
      item.expirationDate!.year,
      item.expirationDate!.month,
      item.expirationDate!.day,
    );
    final difference = expDate.difference(today).inDays;

    if (difference <= 0)
      return _appCoral;
    else if (difference <= 2)
      return _appOrange;
    else
      return _appTeal;
  }

  // --- HELPER PER LE ICONE DINAMICHE ---
  IconData _getIconForArea(AreaType area) {
    switch (area) {
      case AreaType.fridge:
        return Icons.kitchen_rounded;
      case AreaType.freezer:
        return Icons.ac_unit_rounded;
      case AreaType.pantry:
        return Icons.inventory_2_rounded;
      case AreaType.spirits:
        return Icons.wine_bar_rounded;
      case AreaType.household:
        return Icons.cleaning_services_rounded;
      case AreaType.personalCare:
        return Icons.spa_rounded;
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _appTeal,
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
    final RecommendedItem? recommendedItem = recommendedItems
        .cast<RecommendedItem?>()
        .firstWhere(
          (item) => item?.name.toLowerCase() == trimmedName.toLowerCase(),
          orElse: () => null,
        );
    if (trimmedName.isEmpty) return false;
    final parsedQuantity = int.tryParse(quantityController.text.trim());
    final parsedWeight = int.tryParse(weightController.text.trim());

    try {
      final pantryService = ref.read(pantryServiceProvider);
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null || householdId.isEmpty) return false;

      await pantryService.addItem(
        householdId: householdId,
        name: trimmedName,
        area: _selectedCategory,
        quantity: parsedQuantity,
        weight: parsedWeight,
        unit: 'g',
        expirationDate: selectedDate,
        recommendedItemId: recommendedItem?.id,
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

  // --- DIALOG INTELLIGENTE ELIMINAZIONE SINGOLA ---
  Future<String?> _confirmDeleteOrCart(FridgeItem item) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return BackdropFilter(
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
                    color: _appTeal.withOpacity(0.15),
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
                      color: _appTeal.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      color: _appTeal,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Out of stock?',
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _inkColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Do you want to add "${item.name}" to your shopping list before removing it?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _inkColor.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop('cart'),
                        child: Container(
                          height: 50,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _appTeal,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _appTeal.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Yes, add to list',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.of(dialogContext).pop('cancel'),
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _inkColor.withOpacity(0.1),
                                    width: 1.5,
                                  ),
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
                              onTap: () => Navigator.of(dialogContext).pop('delete'),
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _appCoral.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    'Just Delete',
                                    style: GoogleFonts.manrope(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: _appCoral,
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- LOGICA DI ELIMINAZIONE SINGOLA ---
  Future<void> _handleItemRemoval(FridgeItem item) async {
    final action = await _confirmDeleteOrCart(item);
    if (action == null || action == 'cancel') return;

    final pantryService = ref.read(pantryServiceProvider);

    try {
      if (action == 'cart') {
        final householdId = ref.read(currentHouseholdIdProvider);
        if (householdId != null) {
          final shoppingService = ref.read(shoppingServiceProvider);
          await shoppingService.addItem(
            householdId,
            item.name,
            quantity: 1,
          );
        }
      }
      await pantryService.deleteItem(item.id);
      _showSuccessSnackBar(
        action == 'cart' ? 'Added to shopping list & removed' : 'Item deleted',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  // --- DIALOG INTELLIGENTE ELIMINAZIONE MULTIPLA ---
  Future<String?> _confirmBatchDeleteOrCart(int count) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return BackdropFilter(
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
                    color: _appTeal.withOpacity(0.15),
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
                      color: _appTeal.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_cart_checkout_rounded,
                      color: _appTeal,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Out of stock?',
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _inkColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Do you want to add these $count items to your shopping list before removing them?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _inkColor.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop('cart'),
                        child: Container(
                          height: 50,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _appTeal,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _appTeal.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Yes, add all to list',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.of(dialogContext).pop('cancel'),
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _inkColor.withOpacity(0.1),
                                    width: 1.5,
                                  ),
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
                              onTap: () => Navigator.of(dialogContext).pop('delete'),
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _appCoral.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    'Just Delete',
                                    style: GoogleFonts.manrope(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: _appCoral,
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleBatchRemoval(List<FridgeItem> allCurrentItems) async {
    if (_selectedIdsForDeletion.isEmpty) return;

    final action = await _confirmBatchDeleteOrCart(
      _selectedIdsForDeletion.length,
    );
    if (action == null || action == 'cancel') return;

    try {
      final pantryService = ref.read(pantryServiceProvider);

      if (action == 'cart') {
        final shoppingService = ref.read(shoppingServiceProvider);
        final householdId = ref.read(currentHouseholdIdProvider);
        if (householdId != null) {
          final selectedItems = allCurrentItems
              .where((i) => _selectedIdsForDeletion.contains(i.id))
              .toList();
          for (final item in selectedItems) {
            await shoppingService.addItem(householdId, item.name, quantity: 1);
          }
        }
      }

      for (final id in _selectedIdsForDeletion) {
        await pantryService.deleteItem(id);
      }

      if (!mounted) return;
      setState(() {
        _isDeleteMode = false;
        _selectedIdsForDeletion.clear();
      });
      _showSuccessSnackBar(
        action == 'cart' ? 'Added to list & removed' : 'Items deleted',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _toggleSelection(String itemId) {
    setState(() {
      if (_selectedIdsForDeletion.contains(itemId))
        _selectedIdsForDeletion.remove(itemId);
      else
        _selectedIdsForDeletion.add(itemId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pantryService = ref.watch(pantryServiceProvider);
    final householdId = ref.watch(currentHouseholdIdProvider);
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

    final itemsAsync = ref.watch(pantryItemsStreamProvider(householdId));

    final currentItems = itemsAsync.valueOrNull ?? [];
    final filteredItems = currentItems.where((item) {
      final matchesCategory = item.area == _selectedCategory;
      final matchesSearch =
          _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  
                  // 1. INVERTITO: PRIMA I BOTTONCINI GRIGLIA E CATEGORIA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildViewToggle(),
                      _buildCategorySelector(context),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // 2. INVERTITO: DOPO LA SEARCH BAR (Stretta e Compatta)
                  _buildSearchBar(),
                  
                  // SPAZIO EQUIDISTANTE SUPERIORE
                  const SizedBox(height: 26), 
                  
                  // 3. TASTO SELECT: EQUIDISTANTE ED ALLINEATO A DESTRA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [_buildDeleteModeToggle()],
                  ),
                  
                  // SPAZIO INFERIORE AZZERATO (compensato dal padding della lista)
                  const SizedBox(height: 0), 
                  
                  // 4. LISTA
                  Expanded(
                    child: itemsAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(_appTeal),
                        ),
                      ),
                      error: (error, _) => Center(
                        child: Text(
                          error.toString(),
                          style: GoogleFonts.manrope(color: _appCoral),
                        ),
                      ),
                      data: (_) {
                        return _isListView
                            ? _buildGlassList(filteredItems, pantryService)
                            : _buildSmallGlassGrid(
                                filteredItems,
                                pantryService,
                              );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_isDeleteMode)
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildBatchDeleteBar(filteredItems),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // UI PRINCIPALE - VETRO SMOKED/SATINATO
  // ==========================================

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Indietro (PULITO)
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            color: Colors.transparent,
            alignment: Alignment.centerLeft,
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _inkColor,
              size: 24,
            ),
          ),
        ),
        // Titolo
        Text(
          'Fridge Keeping',
          style: GoogleFonts.manrope(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _inkColor,
            letterSpacing: -0.5,
          ),
        ),
        // QR Code (PULITO)
        GestureDetector(
          onTap: () {
            // Aggiungi logica scanner se serve
          },
          child: Container(
            width: 44,
            height: 44,
            color: Colors.transparent,
            alignment: Alignment.centerRight,
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: _inkColor,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }

  // --- SEARCH BAR: STRETTA E COMPATTA ---
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0), // Più stretta
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _inkColor.withOpacity(0.08), // Ombra morbida
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
                color: _inkColor.withOpacity(0.03), // Leggera patina scura
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.7), // Bordo bianco satinato
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
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

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() {
              _isListView = true;
              _isDeleteMode = false;
              _selectedIdsForDeletion.clear();
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isListView ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                boxShadow: _isListView
                    ? [
                        BoxShadow(
                          color: _inkColor.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                Icons.view_list_rounded,
                size: 20,
                color: _isListView
                    ? _inkColor
                    : _inkColor.withOpacity(0.3),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _isListView = false;
              _isDeleteMode = false;
              _selectedIdsForDeletion.clear();
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: !_isListView ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                boxShadow: !_isListView
                    ? [
                        BoxShadow(
                          color: _inkColor.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                Icons.grid_view_rounded,
                size: 20,
                color: !_isListView
                    ? _inkColor
                    : _inkColor.withOpacity(0.3),
              ),
            ),
          ),
        ],
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

  Widget _buildBatchDeleteBar(List<FridgeItem> currentFilteredItems) {
    final count = _selectedIdsForDeletion.length;
    final total = currentFilteredItems.length;
    final bool hasSelection = count > 0;
    final bool allSelected = count == total && total > 0;

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
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 1.5),
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
                            ? _inkColor.withOpacity(0.15)
                            : (hasSelection
                                  ? _inkColor.withOpacity(0.05)
                                  : _inkColor.withOpacity(0.05)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        allSelected
                            ? Icons.remove_done_rounded
                            : Icons.done_all_rounded,
                        color: hasSelection ? _inkColor : _inkColor.withOpacity(0.4),
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
                            ? _inkColor
                            : _inkColor.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasSelection)
                    GestureDetector(
                      onTap: () => _handleBatchRemoval(currentFilteredItems),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _appCoral.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_outline_rounded,
                              color: _appCoral,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Remove',
                              style: GoogleFonts.manrope(
                                color: _appCoral,
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

  Widget _buildCategorySelector(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCategoryModal(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_appOrange, Color(0xFFE76F51)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _appOrange.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedCategory.label,
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.w800,
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
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _inkColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildModalOption(AreaType.pantry),
                  Divider(color: _inkColor.withOpacity(0.05), height: 24),
                  _buildModalOption(AreaType.fridge),
                  Divider(color: _inkColor.withOpacity(0.05), height: 24),
                  _buildModalOption(AreaType.freezer),
                  Divider(color: _inkColor.withOpacity(0.05), height: 24),
                  _buildModalOption(AreaType.spirits),
                  Divider(color: _inkColor.withOpacity(0.05), height: 24),
                  _buildModalOption(AreaType.household),
                  Divider(color: _inkColor.withOpacity(0.05), height: 24),
                  _buildModalOption(AreaType.personalCare),
                  const SizedBox(height: 10),
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
      child: Container(
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              areaType.label,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? _appOrange : _inkColor,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: _appOrange),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // LISTE ED ELEMENTI (VETRO SATINATO CHIARO)
  // ==========================================

  Widget _buildGlassList(List<FridgeItem> items, PantryService pantryService) {
    if (items.isEmpty) return _buildEmptyState();

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: _isDeleteMode ? 100 : 40),
      itemCount: items.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == items.length)
          return _isDeleteMode ? const SizedBox() : _buildInlineAddButton();
        final item = items[index];
        return Dismissible(
          key: ValueKey(item.id),
          direction: _isDeleteMode
              ? DismissDirection.none
              : DismissDirection.endToStart,
          background: Container(
            decoration: BoxDecoration(
              color: _appCoral,
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
            await _handleItemRemoval(item);
            return false;
          },
          child: _buildListItem(item, pantryService),
        );
      },
    );
  }

  Widget _buildListItem(FridgeItem item, PantryService pantryService) {
    final isSelected = _selectedIdsForDeletion.contains(item.id);
    Color baseIconColor = _getItemColor(item);
    Color currentBorderColor = _isDeleteMode && isSelected
        ? _appCoral
        : Colors.white.withOpacity(0.7); 

    final iconData = _getIconForArea(item.area);

    return GestureDetector(
      onTap: _isDeleteMode
          ? () => _toggleSelection(item.id)
          : () => _showItemDetailModal(item, pantryService, baseIconColor, iconData),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _inkColor.withOpacity(0.08), // Ombra profonda
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
              height: 76, 
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: _isDeleteMode && isSelected
                    ? _appCoral.withOpacity(0.1)
                    : _inkColor.withOpacity(0.03), // Leggermente scuro
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: currentBorderColor,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  if (_isDeleteMode) ...[
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                      color: isSelected ? _appCoral : _inkColor.withOpacity(0.3),
                      size: 26,
                    ),
                    const SizedBox(width: 16),
                  ] else ...[
                    item.recommendedItem?.picture != null && item.recommendedItem!.picture.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          item.recommendedItem!.picture,
                          width: 32, 
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(iconData, color: baseIconColor, size: 28),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return SizedBox(
                              width: 32, height: 32,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(baseIconColor.withOpacity(0.3)),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Icon(iconData, color: baseIconColor, size: 28),
                    const SizedBox(width: 16),
                  ],

                  Expanded(
                    child: Text(
                      item.name,
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _inkColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // CONTROLLO DI NULLITÀ
                  if (item.quantity != null && item.quantity! > 1 && !_isDeleteMode)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
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

  // --- GRID VIEW: VETRO SATINATO CHIARO ---
  Widget _buildSmallGlassGrid(List<FridgeItem> items, PantryService pantryService) {
    if (items.isEmpty) return _buildEmptyState();
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(bottom: _isDeleteMode ? 100 : 0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9, 
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildSmallGridCard(items[index], pantryService),
              childCount: items.length,
            ),
          ),
        ),
        if (!_isDeleteMode)
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
    final isSelected = _selectedIdsForDeletion.contains(item.id);
    Color baseIconColor = _getItemColor(item);
    Color currentBorderColor = _isDeleteMode && isSelected
        ? _appCoral
        : Colors.white.withOpacity(0.7);

    final iconData = _getIconForArea(item.area);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: _isDeleteMode
              ? () => _toggleSelection(item.id)
              : () => _showItemDetailModal(item, pantryService, baseIconColor, iconData),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _inkColor.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isDeleteMode && isSelected
                        ? _appCoral.withOpacity(0.1)
                        : _inkColor.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: currentBorderColor,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(iconData, color: baseIconColor, size: 28),
                      const SizedBox(height: 10),
                      Text(
                        item.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _inkColor,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_isDeleteMode)
          Positioned(
            top: 8,
            right: 8,
            child: Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected ? _appCoral : _inkColor.withOpacity(0.2),
              size: 24,
            ),
          ),
      ],
    );
  }

  // --- BOTTONCINO "+" TONDO SCURO ---
  Widget _buildInlineAddButton() {
    return Center(
      child: GestureDetector(
        onTap: () => _showAddElementModal(context),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
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
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
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
            child: Icon(
              Icons.shopping_basket_rounded,
              size: 64,
              color: _appTeal.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nothing here yet',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _inkColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button below to add\ngroceries to this area.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _inkColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showItemDetailModal(
    FridgeItem item,
    PantryService pantryService,
    Color itemColor,
    IconData itemIcon,
  ) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FridgeItemDetailSheet(
        item: item,
        pantryService: pantryService,
        itemColor: itemColor,
        itemIcon: itemIcon, 
      ),
    );
    if (result == true && mounted) _showSuccessSnackBar('Item updated');
  }

  // ==========================================
  // MODAL ADD ELEMENT (CHIARO)
  // ==========================================

  Future<void> _showAddElementModal(BuildContext context) async {
    nameController.clear();
    quantityController.clear();
    weightController.clear();
    dateTextController.clear();
    selectedDate = null;

    final changed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
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
              child: Column(
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
                    'Add an element',
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
                              'Name', true, false, nameController, recommendedItems),
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
                                onPressed: () async {
                                  final added = await _addItem();
                                  if (!context.mounted) return;
                                  if (added) Navigator.pop(context, true);
                                },
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
            ),
          ),
        );
      },
    );

    if (changed == true && mounted) _showSuccessSnackBar('Item added');
  }

  // --- CAMPI MODAL EFFETTO VETRO ---
  Widget _buildPremiumAutocompleteField(
    String label,
    bool isRequired,
    bool isNumber,
    TextEditingController? controller,
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
          return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (RecommendedItem selection) {
        controller?.text = selection.name;
      },
      fieldViewBuilder: (context, autoController, focusNode, onFieldSubmitted) {
        if (autoController.text != controller?.text) {
          autoController.text = controller?.text ?? '';
        }
        autoController.addListener(() {
          controller?.text = autoController.text;
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
                  border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
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
                      color: isRequired ? _appCoral : _inkColor.withOpacity(0.6),
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
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width - 48,
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: _inkColor.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9), 
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

  Widget _buildModalTextField(
    String label,
    bool isRequired,
    bool isNumber, {
    bool isDate = false,
    TextEditingController? controller,
  }) {
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
                                    primary: _appTeal,
                                    onPrimary: Colors.white,
                                    onSurface: _inkColor,
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (pickedDate != null)
                              setState(() {
                                selectedDate = pickedDate;
                                dateTextController.text = formatDate(pickedDate);
                              });
                          }
                        : null,
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
                      hintText: isDate ? 'Select date...' : 'Tap to type...',
                      hintStyle: GoogleFonts.manrope(
                        color: _inkColor.withOpacity(0.3),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                if (isDate)
                  const Icon(Icons.calendar_month_rounded, color: _appTeal, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// COMPONENTE: POPUP DETTAGLIO/MODIFICA (CHIARO)
// ==========================================
class FridgeItemDetailSheet extends StatefulWidget {
  const FridgeItemDetailSheet({
    super.key,
    required this.item,
    required this.pantryService,
    required this.itemColor,
    required this.itemIcon, 
  });
  final FridgeItem item;
  final PantryService pantryService;
  final Color itemColor;
  final IconData itemIcon; 

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
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'none') return null;
    final parts = trimmed.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null)
        return DateTime(year, month, day);
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

    final isDateUnset = dateText.isEmpty || dateText.toLowerCase() == 'none';
    final selectedDate = isDateUnset ? null : _parseDateFromInput(dateText);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemColor = widget.itemColor;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            border: Border.all(color: Colors.white, width: 2),
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
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: itemColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: itemColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            widget.itemIcon, 
                            color: itemColor,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
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
                                  style: GoogleFonts.manrope(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: _inkColor,
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
                                    color: _inkColor.withOpacity(0.05),
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
                      _buildPremiumTextField(
                        'Weight (g)',
                        _weightController,
                        itemColor,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildPremiumTextField(
                        'Quantity',
                        _quantityController,
                        itemColor,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildPremiumTextField(
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
                                    color: itemColor.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              ),
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
    final textColor = const Color(0xFF3D342C);
    return Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                    Icon(icon, size: 16, color: accentColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textColor.withOpacity(0.5),
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
                        ? darkTextColor.withOpacity(0.3)
                        : darkTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    Color accentColor, {
    bool readOnly = false,
    VoidCallback? onTap,
    bool isDate = false,
    TextInputType? keyboardType,
  }) {
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    readOnly: readOnly,
                    onTap: onTap,
                    keyboardType: keyboardType,
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
                        color: darkTextColor.withOpacity(0.6),
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                  ),
                ),
                if (isDate)
                  Icon(Icons.calendar_month_rounded, color: accentColor, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}