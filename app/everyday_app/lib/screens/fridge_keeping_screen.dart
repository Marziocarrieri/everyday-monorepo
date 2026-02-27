import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import '../core/app_context.dart';
import '../models/fridge_item.dart';
import '../repositories/fridge_repository.dart';

class InventoryItem {
  final String name;
  final IconData icon;
  final String expiryStatus; // 'safe', 'warning', 'expired'

  InventoryItem(this.name, this.icon, this.expiryStatus);
}

class FridgeKeepingScreen extends StatefulWidget {
  const FridgeKeepingScreen({super.key});

  @override
  State<FridgeKeepingScreen> createState() => _FridgeKeepingScreenState();
}

class _FridgeKeepingScreenState extends State<FridgeKeepingScreen> {
  String _selectedCategory = 'Pantry'; 
  bool _isListView = true;
  final FridgeRepository _fridgeRepository = FridgeRepository();
  List<FridgeItem> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final householdId = AppContext.instance.requireHouseholdId();
      final items = await _fridgeRepository.getItems(householdId);

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

  Future<void> _addItem(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    try {
      final householdId = AppContext.instance.requireHouseholdId();
      await _fridgeRepository.addItem(
        householdId: householdId,
        name: trimmedName,
      );
      await _loadItems();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentItems = _items
        .map(
          (item) => InventoryItem(
            item.name,
            Icons.kitchen_outlined,
            'safe',
          ),
        )
        .toList();

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
                children: [
                  _buildViewToggle(),
                  _buildCategorySelector(context),
                ],
              ),
              const SizedBox(height: 20),

              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 8),
              ],
              
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _isListView
                        ? _buildGlassList(currentItems)
                        : _buildSmallGlassGrid(currentItems),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildAddButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ==========================================
  // 1. UI PRINCIPALE (COLORI PREMIUM ORIGINALI)
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
        Text('Fridge Keeping', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF5A8B9E))),
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF5A8B9E).withValues(alpha: 0.1), width: 1), boxShadow: [BoxShadow(color: const Color(0xFF5A8B9E).withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))]),
          child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF5A8B9E), size: 22),
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
          height: 55, padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF5A8B9E).withValues(alpha: 0.2), width: 1.2)),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(hintText: 'Search items...', hintStyle: GoogleFonts.poppins(color: const Color(0xFF5A8B9E).withValues(alpha: 0.5), fontSize: 15), border: InputBorder.none),
                  style: GoogleFonts.poppins(color: const Color(0xFF3D342C)),
                ),
              ),
              const Icon(Icons.search_rounded, color: Color(0xFF5A8B9E), size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF5A8B9E).withValues(alpha: 0.1), width: 1.2)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isListView = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: _isListView ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(18), boxShadow: _isListView ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2))] : []),
              child: Icon(Icons.view_list_rounded, size: 22, color: _isListView ? const Color(0xFF5A8B9E) : const Color(0xFF5A8B9E).withValues(alpha: 0.4)),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _isListView = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: !_isListView ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(18), boxShadow: !_isListView ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2))] : []),
              child: Icon(Icons.grid_view_rounded, size: 22, color: !_isListView ? const Color(0xFF5A8B9E) : const Color(0xFF5A8B9E).withValues(alpha: 0.4)),
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
        decoration: BoxDecoration(color: const Color(0xFF3D342C), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: const Color(0xFF3D342C).withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_selectedCategory, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  void _showCategoryModal(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.9), Colors.white.withValues(alpha: 0.7)]), border: Border.all(color: Colors.white, width: 1.5)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 50, height: 5, decoration: BoxDecoration(color: const Color(0xFF5A8B9E).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 30),
                  _buildModalOption('Pantry'), const Divider(color: Colors.black12, height: 30),
                  _buildModalOption('Fridge'), const Divider(color: Colors.black12, height: 30),
                  _buildModalOption('Refrigerator'), const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalOption(String title) {
    bool isSelected = _selectedCategory == title;
    return GestureDetector(
      onTap: () { setState(() => _selectedCategory = title); Navigator.pop(context); },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? const Color(0xFFF4A261) : const Color(0xFF3D342C))),
          if (isSelected) const Icon(Icons.check_circle_rounded, color: Color(0xFFF4A261)),
        ],
      ),
    );
  }

  // ==========================================
  // 2. SEZIONE ITEMS (Colori Carini e Coerenti)
  // ==========================================

  // Funzione che dona i "Colori Carini" coerenti con la palette
  Color _getColorFromStatus(String expiryStatus) {
    if (expiryStatus == 'warning') return const Color(0xFFFFB347); // Arancione Pesca Luminoso
    if (expiryStatus == 'expired') return const Color(0xFFF28482); // Rosso Corallo Morbido
    return const Color(0xFF7CB9E8); // Azzurro Nuvola
  }

  Widget _buildGlassList(List<InventoryItem> items) {
    if (items.isEmpty) return _buildEmptyState();
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildListItem(items[index]),
    );
  }

  Widget _buildListItem(InventoryItem item) {
    Color iconColor = _getColorFromStatus(item.expiryStatus);
    return GestureDetector(
      onTap: () => _showItemDetailModal(context, item),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            height: 85, padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [iconColor.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.4)]), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: iconColor.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))]),
                  child: Icon(item.icon, color: iconColor, size: 28), 
                ),
                const SizedBox(width: 20),
                Expanded(child: Text(item.name, style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C)))),
                Icon(Icons.chevron_right_rounded, color: iconColor.withValues(alpha: 0.5), size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallGlassGrid(List<InventoryItem> items) {
    if (items.isEmpty) return _buildEmptyState();
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.80),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildSmallGridCard(items[index]),
    );
  }

  Widget _buildSmallGridCard(InventoryItem item) {
    Color iconColor = _getColorFromStatus(item.expiryStatus);
    return GestureDetector(
      onTap: () => _showItemDetailModal(context, item),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [iconColor.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.4)]), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: iconColor.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))]),
                  child: Icon(item.icon, color: iconColor, size: 24),
                ),
                const SizedBox(height: 10),
                Text(item.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C), height: 1.1)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Text('No items found.', style: GoogleFonts.poppins(color: const Color(0xFF5A8B9E).withValues(alpha: 0.5), fontSize: 16, fontWeight: FontWeight.w500)));
  }

  void _showItemDetailModal(BuildContext context, InventoryItem item) {
    Color itemColor = _getColorFromStatus(item.expiryStatus);

    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.65, padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [itemColor.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.7)]), border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 50, height: 5, margin: const EdgeInsets.only(bottom: 30), decoration: BoxDecoration(color: itemColor.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(10)))),
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: itemColor.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))]), child: Icon(item.icon, color: itemColor, size: 30)),
                      const SizedBox(width: 16),
                      Expanded(child: Text(item.name, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: itemColor, letterSpacing: -0.5))),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildModalDetailRow('Weight (g)', 'none', itemColor), _buildModalDivider(),
                  _buildModalDetailRow('Quantity', '1', itemColor), _buildModalDivider(),
                  _buildModalDetailRow('Expire date', 'none', itemColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 10),
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
    return Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.0), Colors.white.withValues(alpha: 0.8), Colors.white.withValues(alpha: 0.0)])));
  }

  // ==========================================
  // 3. SEZIONE ADD ELEMENT
  // ==========================================

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => _showAddElementModal(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            width: 70, height: 70,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: const Color(0xFF5A8B9E).withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))]),
            child: const Icon(Icons.add_rounded, color: Color(0xFF5A8B9E), size: 40),
          ),
        ),
      ),
    );
  }

  void _showAddElementModal(BuildContext context) {
    final nameController = TextEditingController();

    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: EdgeInsets.only(left: 30, right: 30, top: 30, bottom: MediaQuery.of(context).viewInsets.bottom + 30),
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFF7CB9E8).withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.8)]), border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 50, height: 5, margin: const EdgeInsets.only(bottom: 30), decoration: BoxDecoration(color: const Color(0xFF7CB9E8).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(10)))),
                  Text('Add an element', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF7CB9E8), letterSpacing: 0.5)),
                  const SizedBox(height: 30),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildModalTextField('Name', true, false, controller: nameController), const SizedBox(height: 20),
                          _buildModalTextField('Weight (g) [optional]', false, true), const SizedBox(height: 20),
                          _buildModalTextField('Quantity [optional]', false, true), const SizedBox(height: 20),
                          _buildModalTextField('Expire date [optional]', false, false, isDate: true),
                          const SizedBox(height: 40),
                          GestureDetector(
                            onTap: () async {
                              await _addItem(nameController.text);
                              if (!context.mounted) return;
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: 70, height: 70,
                              // Gradiente carino e luminoso per il tasto di spunta
                              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7CB9E8), Color(0xFF5A8B9E)]), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: const Color(0xFF7CB9E8).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10))]),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF3D342C), shape: BoxShape.circle)), const SizedBox(width: 10),
            Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C))),
            if (isRequired) Text(' *', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFF28482))), 
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 55, padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF7CB9E8).withValues(alpha: 0.3), width: 1.5)),
          child: Center(
            child: TextField(
              controller: controller,
              keyboardType: isNumber ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(border: InputBorder.none, hintText: isDate ? 'DD/MM/YYYY' : '', suffixIcon: isDate ? const Icon(Icons.calendar_today_rounded, color: Color(0xFF7CB9E8), size: 20) : null),
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C)),
            ),
          ),
        ),
      ],
    );
  }
}