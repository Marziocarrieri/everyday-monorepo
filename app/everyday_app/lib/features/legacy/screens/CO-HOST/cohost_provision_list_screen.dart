import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

// ==========================================
// MODELLI MOCKATI (Finti, solo per la UI)
// ==========================================
class MockShoppingItem {
  final String id;
  final String name;
  final int quantity;
  final String status;

  MockShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    this.status = 'pending',
  });
}

// ==========================================
// SCHERMATA PRINCIPALE
// ==========================================
class CohostProvisionListScreen extends StatefulWidget {
  const CohostProvisionListScreen({super.key});

  @override
  State<CohostProvisionListScreen> createState() => _CohostProvisionListScreenState();
}

class _CohostProvisionListScreenState extends State<CohostProvisionListScreen> {
  // Dati finti per vedere il design
  final List<MockShoppingItem> _mockItems = [
    MockShoppingItem(id: '1', name: 'Paper Towels', quantity: 2),
    MockShoppingItem(id: '2', name: 'Dish Soap', quantity: 1),
    MockShoppingItem(id: '3', name: 'Trash Bags', quantity: 3),
  ];

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openAddModal() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _CohostAddProvisionSheet(),
    );

    if (changed == true && mounted) {
      _showSuccessSnackBar('Simulazione: Item added');
    }
  }

  Future<void> _openDetailModal(MockShoppingItem item) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CohostProvisionDetailSheet(item: item),
    );

    if (changed == true && mounted) {
      _showSuccessSnackBar('Simulazione: Item updated');
    }
  }

  @override
  Widget build(BuildContext context) {
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

              // LA LISTA IN VETRO
              Expanded(
                child: _mockItems.isEmpty
                    ? _buildEmptyState()
                    : _buildGlassList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SEZIONE 1: HEADER E LISTA
  // ==========================================
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF5A8B9E).withValues(alpha: 0.1), width: 1),
              boxShadow: [BoxShadow(color: const Color(0xFF5A8B9E).withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF5A8B9E), size: 20),
          ),
        ),
        Text(
          'Provision List',
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF5A8B9E)),
        ),
        GestureDetector(
          onTap: _openAddModal,
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF5A8B9E).withValues(alpha: 0.3), width: 1.5),
              boxShadow: [BoxShadow(color: const Color(0xFF5A8B9E).withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: const Icon(Icons.add_rounded, color: Color(0xFF5A8B9E), size: 28),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassList() {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: _mockItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _mockItems[index];
        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
          ),
          confirmDismiss: (direction) async {
             // Mockiamo la conferma di eliminazione
            return await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Delete this item?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Delete')),
                ],
              ),
            ) ?? false;
          },
          onDismissed: (direction) {
            setState(() {
              _mockItems.removeAt(index);
            });
            _showSuccessSnackBar('Simulazione: Item deleted');
          },
          child: _buildListItem(item),
        );
      },
    );
  }

  Widget _buildListItem(MockShoppingItem item) {
    return GestureDetector(
      onTap: () => _openDetailModal(item),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            height: 70, padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFF5A8B9E).withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.4)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF5A8B9E).withValues(alpha: 0.1), width: 1),
            ),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF3D342C), shape: BoxShape.circle)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(item.name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C))),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF5A8B9E).withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
                  child: Text('x${item.quantity}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF5A8B9E))),
                ),
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
          Icon(Icons.shopping_bag_outlined, size: 60, color: const Color(0xFF5A8B9E).withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'Your list is empty.',
            style: GoogleFonts.poppins(color: const Color(0xFF5A8B9E).withValues(alpha: 0.6), fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SEZIONE 2: POPUP AGGIUNGI ITEM
// ==========================================
class _CohostAddProvisionSheet extends StatefulWidget {
  const _CohostAddProvisionSheet();

  @override
  State<_CohostAddProvisionSheet> createState() => _CohostAddProvisionSheetState();
}

class _CohostAddProvisionSheetState extends State<_CohostAddProvisionSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: EdgeInsets.only(left: 30, right: 30, top: 30, bottom: MediaQuery.of(context).viewInsets.bottom + 30),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFF7CB9E8).withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.8)]),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50, height: 5, margin: const EdgeInsets.only(bottom: 30),
                  decoration: BoxDecoration(color: const Color(0xFF7CB9E8).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(10)),
                ),
              ),
              Text('Add a Provision', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF7CB9E8), letterSpacing: 0.5)),
              const SizedBox(height: 30),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildModalTextField('Name', true, false, _nameController),
                      const SizedBox(height: 20),
                      _buildModalTextField('Quantity [optional]', false, true, _quantityController),
                      const SizedBox(height: 40),
                      GestureDetector(
                        onTap: _save,
                        child: Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF7CB9E8), Color(0xFF5A8B9E)]),
                            shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [BoxShadow(color: const Color(0xFF7CB9E8).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10))],
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
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
  }

  Widget _buildModalTextField(String label, bool isRequired, bool isNumber, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF3D342C), shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C))),
            if (isRequired) Text(' *', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFF28482))),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 55, padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF7CB9E8).withValues(alpha: 0.3), width: 1.5),
          ),
          child: Center(
            child: TextField(
              controller: controller, keyboardType: isNumber ? TextInputType.number : TextInputType.text,
              decoration: const InputDecoration(border: InputBorder.none),
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C)),
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// SEZIONE 3: POPUP DETTAGLIO ITEM
// ==========================================
class _CohostProvisionDetailSheet extends StatefulWidget {
  final MockShoppingItem item;
  const _CohostProvisionDetailSheet({required this.item});

  @override
  State<_CohostProvisionDetailSheet> createState() => _CohostProvisionDetailSheetState();
}

class _CohostProvisionDetailSheetState extends State<_CohostProvisionDetailSheet> {
  bool _isEditing = false;
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _quantityController = TextEditingController(text: widget.item.quantity.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _saveEdit() {
    if (_nameController.text.trim().isEmpty) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFFF4A261).withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.7)]),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50, height: 5, margin: const EdgeInsets.only(bottom: 30),
                  decoration: BoxDecoration(color: const Color(0xFFF4A261).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(10)),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _isEditing
                        ? TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(border: InputBorder.none, hintText: 'Name'),
                            style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: const Color(0xFFF4A261), letterSpacing: -0.5),
                          )
                        : Text(
                            widget.item.name, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: const Color(0xFFF4A261), letterSpacing: -0.5),
                          ),
                  ),
                  if (!_isEditing)
                    IconButton(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit, color: Color(0xFFF4A261)),
                    ),
                ],
              ),
              const SizedBox(height: 30),
              if (!_isEditing) ...[
                _buildModalDetailRow('Quantity', widget.item.quantity.toString()),
                _buildModalDivider(),
                _buildModalDetailRow('Status', widget.item.status),
              ] else ...[
                _buildEditField('Quantity', _quantityController),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          _nameController.text = widget.item.name;
                          _quantityController.text = widget.item.quantity.toString();
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: _saveEdit,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF4A261), shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C).withValues(alpha: 0.7))),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white, width: 1)),
            child: Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF3D342C))),
          ),
        ],
      ),
    );
  }

  Widget _buildModalDivider() {
    return Container(
      height: 1, margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.0), Colors.white.withValues(alpha: 0.8), Colors.white.withValues(alpha: 0.0)])),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF4A261), shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C).withValues(alpha: 0.7))),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 55, padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white, width: 1)),
          child: Center(
            child: TextField(
              controller: controller, keyboardType: TextInputType.number,
              decoration: const InputDecoration(border: InputBorder.none),
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF3D342C)),
            ),
          ),
        ),
      ],
    );
  }
}