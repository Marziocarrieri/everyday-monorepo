import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/features/fridge/data/models/shopping_item.dart';
import 'package:everyday_app/features/fridge/domain/services/shopping_service.dart';
import 'package:everyday_app/features/fridge/presentation/providers/fridge_providers.dart';
import 'package:everyday_app/shared/utils/status_color_utils.dart'; // Importato per la coerenza dei colori

class ProvisionListScreen extends ConsumerStatefulWidget {
  const ProvisionListScreen({super.key});

  @override
  ConsumerState<ProvisionListScreen> createState() => _ProvisionListScreenState();
}

class _ProvisionListScreenState extends ConsumerState<ProvisionListScreen> {
  List<ShoppingItem> _items = [];
  bool _isLoading = true;
  String? _error;

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF5A8B9E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final shoppingService = ref.read(shoppingServiceProvider);
      final householdId = AppContext.instance.requireHouseholdId();
      final items = await shoppingService.getList(householdId);

      if (!mounted) return;
      setState(() {
        _items = items;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<bool?> _confirmDelete(ShoppingItem item) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            backgroundColor: Colors.white.withValues(alpha: 0.9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.white, width: 1.5)),
            title: Text(
              'Delete Item?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: const Color(0xFF3D342C)),
            ),
            content: Text(
              'Are you sure you want to remove "${item.name}" from your list?',
              style: GoogleFonts.poppins(color: const Color(0xFF3D342C).withValues(alpha: 0.7)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF5A8B9E), fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF28482),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteItem(String id, ShoppingService shoppingService) async {
    try {
      await shoppingService.deleteItem(id);
      await _loadItems();
      _showSuccessSnackBar('Item deleted');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      await _loadItems();
    }
  }

  Future<void> _openAddModal(ShoppingService shoppingService) async {
    final householdId = AppContext.instance.requireHouseholdId();
    final changed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddProvisionSheet(
        shoppingService: shoppingService,
        householdId: householdId,
      ),
    );

    if (changed == true && mounted) {
      await _loadItems();
      _showSuccessSnackBar('Item added');
    }
  }

  Future<void> _openDetailModal(ShoppingItem item, ShoppingService shoppingService) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ProvisionDetailSheet(
        item: item,
        shoppingService: shoppingService,
      ),
    );

    if (changed == true && mounted) {
      await _loadItems();
      _showSuccessSnackBar('Item updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    final shoppingService = ref.watch(shoppingServiceProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, shoppingService),
              const SizedBox(height: 30),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF28482).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF28482).withValues(alpha: 0.3))),
                  child: Text(_error!, style: GoogleFonts.poppins(color: const Color(0xFFF28482), fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 16),
              ],

              // LA LISTA IN VETRO
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(getStatusColor('safe')),
                        ),
                      )
                    : _items.isEmpty
                    ? _buildEmptyState()
                    : _buildGlassList(shoppingService),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET PRINCIPALI
  // ==========================================

  Widget _buildHeader(BuildContext context, ShoppingService shoppingService) {
    final themeColor = getStatusColor('safe');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Tasto Indietro
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF5A8B9E).withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5A8B9E).withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF5A8B9E),
              size: 20,
            ),
          ),
        ),

        // Titolo
        Text(
          'Provision List',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5A8B9E),
          ),
        ),

        // Tasto Aggiungi (Aggiornato al colore di tema)
        GestureDetector(
          onTap: () => _openAddModal(shoppingService),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: themeColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.add_rounded,
              color: themeColor,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassList(ShoppingService shoppingService) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: _items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _items[index];
        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF28482),
              borderRadius: BorderRadius.circular(20),
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
            return shouldDelete ?? false;
          },
          onDismissed: (direction) async {
            await _deleteItem(item.id, shoppingService);
          },
          child: _buildListItem(item, shoppingService),
        );
      },
    );
  }

  Widget _buildListItem(ShoppingItem item, ShoppingService shoppingService) {
    final themeColor = getStatusColor('safe');
    
    return GestureDetector(
      onTap: () => _openDetailModal(item, shoppingService),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  themeColor.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Pallino Vuoto stile Checkbox
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: themeColor.withValues(alpha: 0.5), width: 2),
                  ),
                ),
                const SizedBox(width: 16),

                // Nome
                Expanded(
                  child: Text(
                    item.name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3D342C),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Badge Quantità
                if (item.quantity > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Qty: ${item.quantity}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: themeColor,
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

  Widget _buildEmptyState() {
    final themeColor = getStatusColor('safe');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 60,
            color: themeColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Your list is empty.',
            style: GoogleFonts.poppins(
              color: const Color(0xFF3D342C).withValues(alpha: 0.5),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
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
  final TextEditingController _quantityController = TextEditingController(text: '1');
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
    final quantity = parsedQuantity == null || parsedQuantity <= 0 ? 1 : parsedQuantity;

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
            color: Colors.white.withValues(alpha: 0.95), // Luminoso
            border: Border.all(
              color: Colors.white,
              width: 1.5,
            ),
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
                        color: themeColor.withValues(alpha: 0.3),
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
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: themeColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: Text(
                                'Add Item', 
                                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
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
                    color: Colors.white.withValues(alpha: 0.8),
                    child: Center(
                      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(themeColor)),
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
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 1.5),
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
                : const Color(0xFF3D342C).withValues(alpha: 0.6),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: 'Tap to type...',
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFF3D342C).withValues(alpha: 0.3),
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

    setState(() => _isSaving = true);

    final updated = ShoppingItem(
      id: widget.item.id,
      householdId: widget.item.householdId,
      name: name,
      quantity: quantity,
      status: widget.item.status,
    );

    await widget.shoppingService.updateItem(updated);
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
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 20, 
            bottom: MediaQuery.of(context).viewInsets.bottom + 40
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
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
                      width: 40, height: 5, margin: const EdgeInsets.only(bottom: 30),
                      decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  Row(
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: themeColor.withValues(alpha: 0.3), width: 2),
                        ),
                        child: Icon(Icons.shopping_cart_outlined, color: themeColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _isEditing
                            ? TextField(
                                controller: _nameController,
                                style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.5),
                                decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: 'Name'),
                              )
                            : Text(
                                widget.item.name,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.5),
                              ),
                      ),
                      if (!_isEditing)
                        GestureDetector(
                          onTap: () => setState(() => _isEditing = true),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Icon(Icons.edit_rounded, color: themeColor, size: 20),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  if (!_isEditing) ...[
                    // VIEW MODE: Dashboard Card
                    _buildDashCard('Quantity', widget.item.quantity.toString(), Icons.tag_rounded, themeColor),
                    const SizedBox(height: 20),
                  ] else ...[
                    // EDIT MODE
                    _buildPremiumTextField('Quantity', _quantityController, themeColor),
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
                                _quantityController.text = widget.item.quantity.toString();
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: themeColor.withValues(alpha: 0.5), width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF5A8B9E), fontWeight: FontWeight.w700, fontSize: 16)),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: Text('Save', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
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
                    child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(themeColor))),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashCard(String title, String value, IconData icon, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(color: accentColor.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))
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
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C).withValues(alpha: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22, 
              fontWeight: FontWeight.w700, 
              color: const Color(0xFF3D342C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTextField(String label, TextEditingController controller, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF3D342C)),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF3D342C).withValues(alpha: 0.6)),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: 'Tap to enter...',
          hintStyle: GoogleFonts.poppins(color: const Color(0xFF3D342C).withValues(alpha: 0.3), fontSize: 16),
        ),
      ),
    );
  }
}