import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

// ==========================================
// FUNZIONE COLORI SIMULATA 
// ==========================================
Color getStatusColor(String status) {
  if (status == 'safe') {
    return const Color(0xFF7CB9E8); // Azzurro brillante
  }
  return const Color(0xFF5A8B9E); // Azzurro scuro
}

// ==========================================
// MODELLO MOCKATO (Finto, solo per la UI)
// ==========================================
class MockProvisionItem {
  final String id;
  String name;
  int quantity;
  bool isBought;

  MockProvisionItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.isBought = false,
  });
}

// ==========================================
// SCHERMATA PRINCIPALE (PROVISION LIST)
// ==========================================
class PersonnelProvisionListScreen extends StatefulWidget {
  const PersonnelProvisionListScreen({super.key});

  @override
  State<PersonnelProvisionListScreen> createState() => _PersonnelProvisionListScreenState();
}

class _PersonnelProvisionListScreenState extends State<PersonnelProvisionListScreen> {
  // Dati finti per la lista della spesa
  final List<MockProvisionItem> _items = [
    MockProvisionItem(id: '1', name: 'Latte intero', quantity: 2),
    MockProvisionItem(id: '2', name: 'Uova (confezione da 6)', quantity: 1),
    MockProvisionItem(id: '3', name: 'Pane in cassetta', quantity: 1, isBought: true),
    MockProvisionItem(id: '4', name: 'Detersivo piatti', quantity: 2),
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _toggleBoughtStatus(String id) {
    setState(() {
      final item = _items.firstWhere((element) => element.id == id);
      item.isBought = !item.isBought;
    });
  }

  void _deleteItem(String id) {
    setState(() {
      _items.removeWhere((element) => element.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Articolo rimosso'), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Separiamo gli elementi da comprare da quelli già presi
    final toBuyItems = _items.where((item) => !item.isBought).toList();
    final boughtItems = _items.where((item) => item.isBought).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: _buildHeader(context),
            ),
            Expanded(
              child: _items.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                      children: [
                        if (toBuyItems.isNotEmpty) ...[
                          Text(
                            'To Buy',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF3D342C)),
                          ),
                          const SizedBox(height: 16),
                          ...toBuyItems.map((item) => _buildListItem(item)).toList(),
                        ],
                        if (boughtItems.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Bought',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF3D342C).withValues(alpha: 0.5)),
                          ),
                          const SizedBox(height: 16),
                          ...boughtItems.map((item) => _buildListItem(item)).toList(),
                        ],
                        const SizedBox(height: 80), // Spazio per il FAB
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildAddButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ==========================================
  // WIDGETS DELLA UI
  // ==========================================
  Widget _buildHeader(BuildContext context) {
    final themeColor = getStatusColor('safe');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
              border: Border.all(color: themeColor.withValues(alpha: 0.1), width: 1),
              boxShadow: [BoxShadow(color: themeColor.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: themeColor, size: 20),
          ),
        ),
        Text('Provision List', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: themeColor)),
        const SizedBox(width: 48), // Spazio vuoto per bilanciare il tasto back
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined, size: 80, color: getStatusColor('safe').withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Your list is empty', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C).withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _buildListItem(MockProvisionItem item) {
    final themeColor = getStatusColor('safe');
    final isBought = item.isBought;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Dismissible(
        key: Key(item.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _deleteItem(item.id),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24.0),
          decoration: BoxDecoration(color: const Color(0xFFF28482), borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 30),
        ),
        child: GestureDetector(
          onTap: () => _toggleBoughtStatus(item.id),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 80, padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isBought 
                        ? [Colors.white.withValues(alpha: 0.4), Colors.white.withValues(alpha: 0.2)]
                        : [themeColor.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.6)]
                  ),
                  borderRadius: BorderRadius.circular(24), 
                  border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2),
                ),
                child: Row(
                  children: [
                    // Checkbox rotonda
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: isBought ? themeColor : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: isBought ? themeColor : themeColor.withValues(alpha: 0.5), width: 2),
                      ),
                      child: isBought ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                    ),
                    const SizedBox(width: 16),
                    
                    // Testo e Quantità
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name, 
                            style: GoogleFonts.poppins(
                              fontSize: 16, 
                              fontWeight: FontWeight.w600, 
                              color: isBought ? const Color(0xFF3D342C).withValues(alpha: 0.4) : const Color(0xFF3D342C),
                              decoration: isBought ? TextDecoration.lineThrough : TextDecoration.none,
                            ),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          if (item.quantity > 1)
                            Text(
                              'Qty: ${item.quantity}', 
                              style: GoogleFonts.poppins(
                                fontSize: 13, 
                                fontWeight: FontWeight.w500, 
                                color: isBought ? const Color(0xFF3D342C).withValues(alpha: 0.3) : const Color(0xFF3D342C).withValues(alpha: 0.6)
                              )
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    final themeColor = getStatusColor('safe');
    return GestureDetector(
      onTap: () => _showAddElementModal(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: themeColor.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Icon(Icons.add_rounded, color: themeColor, size: 40),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MODAL: AGGIUNGI ELEMENTO
  // ==========================================
  Future<void> _showAddElementModal(BuildContext context) async {
    final themeColor = getStatusColor('safe');
    _nameController.clear();
    _quantityController.text = '1';

    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              padding: EdgeInsets.only(left: 30, right: 30, top: 30, bottom: MediaQuery.of(context).viewInsets.bottom + 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [themeColor.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.8)]),
                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 50, height: 5, margin: const EdgeInsets.only(bottom: 30), decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(10)))),
                  Text('Add to list', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: themeColor, letterSpacing: 0.5)),
                  const SizedBox(height: 30),
                  
                  // Campo Nome
                  Container(
                    height: 55, padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20), border: Border.all(color: themeColor.withValues(alpha: 0.3), width: 1.5)),
                    child: Center(
                      child: TextField(
                        controller: _nameController, autofocus: true,
                        decoration: InputDecoration(border: InputBorder.none, hintText: 'Item name...', hintStyle: GoogleFonts.poppins(color: const Color(0xFF3D342C).withValues(alpha: 0.4))),
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Campo Quantità
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Quantity', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C))),
                      Container(
                        width: 100, height: 50, padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(15), border: Border.all(color: themeColor.withValues(alpha: 0.3), width: 1.5)),
                        child: TextField(
                          controller: _quantityController, textAlign: TextAlign.center, keyboardType: TextInputType.number,
                          decoration: const InputDecoration(border: InputBorder.none),
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF3D342C)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  
                  // Tasto Salva
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        if (_nameController.text.isNotEmpty) {
                          setState(() {
                            _items.add(MockProvisionItem(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              name: _nameController.text.trim(),
                              quantity: int.tryParse(_quantityController.text) ?? 1,
                            ));
                          });
                        }
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [themeColor, const Color(0xFF5A8B9E)]),
                          shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [BoxShadow(color: themeColor.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
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
  }
}