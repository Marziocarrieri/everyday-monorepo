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

class ProvisionListScreen extends ConsumerStatefulWidget {
  const ProvisionListScreen({super.key});

  @override
  ConsumerState<ProvisionListScreen> createState() =>
      _ProvisionListScreenState();
}

class _ProvisionListScreenState extends ConsumerState<ProvisionListScreen> {
  String _searchQuery = '';
  bool _isDeleteMode = false;
  final Set<String> _selectedIdsForDeletion = {};

  final Color primaryColor = const Color(0xFF5A8B9E); 
  final Color archiveColor = const Color(0xFFF4A261); // Giallo/Arancio per l'archivio
  final Color darkTextColor = const Color(0xFF3D342C);

  void _showSuccessSnackBar(String message) {
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

  // --- DIALOG DI CONFERMA ARCHIVIAZIONE SINGOLA ---
  Future<bool?> _confirmMoveToHistory(ShoppingItem item) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: archiveColor.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(color: archiveColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.archive_outlined, color: archiveColor, size: 30),
                ),
                const SizedBox(height: 20),
                Text('Move to History?', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: darkTextColor)),
                const SizedBox(height: 12),
                Text(
                  'This will move "${item.name}" to your history. You can restore it later.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: darkTextColor.withOpacity(0.6)),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(false),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(border: Border.all(color: darkTextColor.withOpacity(0.1), width: 1.5), borderRadius: BorderRadius.circular(16)),
                          child: Center(child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: darkTextColor.withOpacity(0.7)))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(true),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(color: archiveColor, borderRadius: BorderRadius.circular(16)),
                          child: Center(child: Text('Move', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
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
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: archiveColor.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(color: archiveColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.archive_outlined, color: archiveColor, size: 30),
                ),
                const SizedBox(height: 20),
                Text('Archive Items?', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: darkTextColor)),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to move $count items to your history?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: darkTextColor.withOpacity(0.6)),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(false),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(border: Border.all(color: darkTextColor.withOpacity(0.1), width: 1.5), borderRadius: BorderRadius.circular(16)),
                          child: Center(child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: darkTextColor.withOpacity(0.7)))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(true),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(color: archiveColor, borderRadius: BorderRadius.circular(16)),
                          child: Center(child: Text('Move', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
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
      if (_selectedIdsForDeletion.contains(itemId)) _selectedIdsForDeletion.remove(itemId);
      else _selectedIdsForDeletion.add(itemId);
    });
  }

  Future<void> _openAddModal(ShoppingService shoppingService) async {
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null || householdId.isEmpty) return;
    final changed = await showModalBottomSheet<bool>(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => _AddProvisionSheet(shoppingService: shoppingService, householdId: householdId),
    );
    if (changed == true && mounted) _showSuccessSnackBar('Item added');
  }

  Future<void> _openDetailModal(ShoppingItem item, ShoppingService shoppingService) async {
    final changed = await showModalBottomSheet<bool>(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => _ProvisionDetailSheet(item: item, shoppingService: shoppingService),
    );
    if (changed == true && mounted) _showSuccessSnackBar('Item updated');
  }

  @override
  Widget build(BuildContext context) {
    final shoppingService = ref.watch(shoppingServiceProvider);
    final householdId = ref.watch(currentHouseholdIdProvider);
    if (householdId == null || householdId.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text('Household context not ready', style: GoogleFonts.poppins(color: darkTextColor, fontWeight: FontWeight.w500)),
        ),
      );
    }

    // ATTENZIONE: USIAMO IL NUOVO PROVIDER ATTIVO
    final itemsAsync = ref.watch(activeShoppingItemsProvider(householdId));

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
                  _buildHeader(context, shoppingService),
                  const SizedBox(height: 30),
                  _buildSearchBar(),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [_buildDeleteModeToggle()],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: itemsAsync.when(
                      loading: () => Center(child: CircularProgressIndicator(color: primaryColor)),
                      error: (err, _) => Center(child: Text(err.toString())),
                      data: (_) {
                        if (filteredItems.isEmpty && _searchQuery.isNotEmpty) {
                          return Center(child: Text('No items found', style: GoogleFonts.poppins(color: darkTextColor.withOpacity(0.5), fontSize: 16, fontWeight: FontWeight.w500)));
                        }
                        return filteredItems.isEmpty ? _buildEmptyState() : _buildGlassList(filteredItems, shoppingService);
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_isDeleteMode) Align(alignment: Alignment.bottomCenter, child: _buildBatchArchiveBar(filteredItems, shoppingService)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ShoppingService shoppingService) {
    final themeColor = getStatusColor('safe');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: _buildHeaderIcon(Icons.arrow_back_ios_new_rounded, primaryColor),
        ),
        Text('Provision List', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: primaryColor)),
        Row(
          children: [
            GestureDetector(
              // NAVIGA ALLA NUOVA SCHERMATA HISTORY
              onTap: () => Navigator.of(context).pushNamed(AppRouteNames.provisionHistory),
              child: _buildHeaderIcon(Icons.history_rounded, archiveColor),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _openAddModal(shoppingService),
              child: _buildHeaderIcon(Icons.add_rounded, themeColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderIcon(IconData icon, Color color) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: Colors.white, shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          height: 55, padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(24),
            border: Border.all(color: primaryColor.withOpacity(0.2), width: 1.2),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(hintText: 'Search items...', hintStyle: GoogleFonts.poppins(color: primaryColor.withOpacity(0.5), fontSize: 15), border: InputBorder.none),
                  style: GoogleFonts.poppins(color: darkTextColor),
                ),
              ),
              Icon(Icons.search_rounded, color: primaryColor, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteModeToggle() {
    return GestureDetector(
      onTap: () => setState(() {
        _isDeleteMode = !_isDeleteMode;
        if (!_isDeleteMode) _selectedIdsForDeletion.clear(); 
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isDeleteMode ? archiveColor : Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _isDeleteMode ? archiveColor : primaryColor.withOpacity(0.1), width: 1.2),
        ),
        child: Icon(Icons.checklist_rounded, size: 22, color: _isDeleteMode ? Colors.white : primaryColor.withOpacity(0.4)),
      ),
    );
  }

  Widget _buildBatchArchiveBar(List<ShoppingItem> currentFilteredItems, ShoppingService shoppingService) {
    final count = _selectedIdsForDeletion.length;
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
              color: hasSelection ? archiveColor.withOpacity(0.95) : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: hasSelection ? archiveColor : darkTextColor.withOpacity(0.1), width: 1.5),
              boxShadow: [BoxShadow(color: hasSelection ? archiveColor.withOpacity(0.3) : Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() {
                    if (allSelected) _selectedIdsForDeletion.clear();
                    else _selectedIdsForDeletion.addAll(currentFilteredItems.map((e) => e.id));
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: allSelected ? Colors.white.withOpacity(0.2) : (hasSelection ? Colors.white.withOpacity(0.1) : primaryColor.withOpacity(0.1)), shape: BoxShape.circle),
                    child: Icon(allSelected ? Icons.remove_done_rounded : Icons.done_all_rounded, color: hasSelection ? Colors.white : primaryColor, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    count == 0 ? 'Select items...' : (allSelected ? 'All selected ($count)' : '$count selected'),
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: hasSelection ? Colors.white : darkTextColor.withOpacity(0.6)),
                  ),
                ),
                if (hasSelection)
                  GestureDetector(
                    onTap: () => _moveToHistorySelectedItems(shoppingService),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Icon(Icons.archive_outlined, color: archiveColor, size: 18),
                          const SizedBox(width: 4),
                          Text('Archive', style: GoogleFonts.poppins(color: archiveColor, fontWeight: FontWeight.w700, fontSize: 13))
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

  Widget _buildGlassList(List<ShoppingItem> items, ShoppingService shoppingService) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(), padding: EdgeInsets.only(bottom: _isDeleteMode ? 100 : 20),
      itemCount: items.length, separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Dismissible(
          key: ValueKey(item.id), direction: _isDeleteMode ? DismissDirection.none : DismissDirection.endToStart,
          background: Container(
            decoration: BoxDecoration(color: archiveColor, borderRadius: BorderRadius.circular(20)),
            alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 24),
            child: const Icon(Icons.archive_outlined, color: Colors.white, size: 28),
          ),
          confirmDismiss: (direction) async {
            final shouldArchive = await _confirmMoveToHistory(item);
            if (shouldArchive == true) await _moveToHistoryItem(item.id, shoppingService);
            return false;
          },
          child: _buildListItem(item, shoppingService),
        );
      },
    );
  }

  Widget _buildListItem(ShoppingItem item, ShoppingService shoppingService) {
    final themeColor = getStatusColor('safe');
    final isSelected = _selectedIdsForDeletion.contains(item.id);
    Color currentBorderColor = _isDeleteMode && isSelected ? archiveColor : Colors.white.withOpacity(0.8);
    
    return GestureDetector(
      onTap: _isDeleteMode ? () => _toggleSelection(item.id) : () => _openDetailModal(item, shoppingService),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200), height: 70, padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: _isDeleteMode && isSelected ? [archiveColor.withOpacity(0.15), Colors.white.withOpacity(0.8)] : [themeColor.withOpacity(0.15), Colors.white.withOpacity(0.6)]),
              borderRadius: BorderRadius.circular(20), border: Border.all(color: currentBorderColor, width: isSelected ? 2.0 : 1.5),
            ),
            child: Row(
              children: [
                if (_isDeleteMode) Icon(isSelected ? Icons.check_circle_rounded : Icons.circle_outlined, color: isSelected ? archiveColor : Colors.grey.withOpacity(0.5), size: 28)
                else Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: themeColor.withOpacity(0.5), width: 2))),
                const SizedBox(width: 16),
                Expanded(child: Text(item.name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: darkTextColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (item.quantity > 1 && !_isDeleteMode)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(12)),
                    child: Text('Qty: ${item.quantity}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: themeColor)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final themeColor = getStatusColor('safe');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 60, color: themeColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('Your list is empty.', style: GoogleFonts.poppins(color: darkTextColor.withOpacity(0.5), fontSize: 16, fontWeight: FontWeight.w500)),
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

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
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
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = getStatusColor('safe');
    final textColor = const Color(0xFF3D342C);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.70,
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 30,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95), // Luminoso
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 30),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Text(
                    'Add a Provision',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildPremiumTextField(
                            'Name',
                            true,
                            false,
                            _nameController,
                            themeColor,
                          ),
                          const SizedBox(height: 16),
                          _buildPremiumTextField(
                            'Quantity',
                            false,
                            true,
                            _quantityController,
                            themeColor,
                          ),
                          const SizedBox(height: 40),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _save,
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
              if (_isSaving)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(0.8),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(themeColor),
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

  Widget _buildPremiumTextField(
    String label,
    bool isRequired,
    bool isNumber,
    TextEditingController controller,
    Color accentColor,
  ) {
    final displayLabel = isRequired ? '$label *' : label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF3D342C),
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: displayLabel,
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isRequired
                ? const Color(0xFFF28482)
                : const Color(0xFF3D342C).withOpacity(0.6),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: 'Tap to enter...',
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFF3D342C).withOpacity(0.3),
            fontSize: 16,
          ),
        ),
      ),
    );
  }
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
    );

    try {
      await widget.shoppingService.updateItem(updated);
      if (!mounted) return;
      Navigator.pop(context, true);
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
    final themeColor = getStatusColor('safe');
    final textColor = const Color(0xFF3D342C);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
        child: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 40,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 30),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.3),
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
                          color: themeColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: themeColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.shopping_cart_outlined,
                          color: themeColor,
                          size: 28,
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
                                  color: textColor,
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
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
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
                            child: Icon(
                              Icons.edit_rounded,
                              color: themeColor,
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
                      themeColor,
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    // EDIT MODE
                    _buildPremiumTextField(
                      'Quantity',
                      _quantityController,
                      themeColor,
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
                                color: themeColor.withOpacity(0.5),
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
                            onPressed: _saveEdit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: themeColor,
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
                    color: Colors.white.withOpacity(0.8),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(themeColor),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.05),
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
              Icon(icon, size: 18, color: accentColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
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
    );
  }

  Widget _buildPremiumTextField(
    String label,
    TextEditingController controller,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF3D342C),
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF3D342C).withOpacity(0.6),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: 'Tap to enter...',
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFF3D342C).withOpacity(0.3),
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}