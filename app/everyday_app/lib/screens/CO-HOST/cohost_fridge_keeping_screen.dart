import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

// ==========================================
// FUNZIONE COLORI SIMULATA (Mock di status_color_utils.dart)
// ==========================================
Color getStatusColor(String status) {
  if (status == 'safe') {
    return const Color(0xFF7CB9E8); // Azzurro brillante
  }
  return const Color(0xFF5A8B9E); // Azzurro scuro
}

// ==========================================
// MODELLI MOCKATI (Finti, solo per la UI)
// ==========================================
enum AreaType { pantry, fridge, freezer }

extension AreaTypeExtension on AreaType {
  String get label {
    switch (this) {
      case AreaType.pantry: return 'Pantry';
      case AreaType.fridge: return 'Fridge';
      case AreaType.freezer: return 'Freezer';
    }
  }
}

class MockFridgeItem {
  final String id;
  final String name;
  final AreaType area;
  final int? quantity;
  final int? weight;
  final DateTime? expirationDate;

  MockFridgeItem({
    required this.id, required this.name, required this.area, this.quantity, this.weight, this.expirationDate,
  });
}

// ==========================================
// SCHERMATA PRINCIPALE
// ==========================================
class CohostFridgeKeepingScreen extends StatefulWidget {
  const CohostFridgeKeepingScreen({super.key});

  @override
  State<CohostFridgeKeepingScreen> createState() => _CohostFridgeKeepingScreenState();
}

class _CohostFridgeKeepingScreenState extends State<CohostFridgeKeepingScreen> {
  AreaType _selectedCategory = AreaType.fridge;
  DateTime? selectedDate;
  
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController dateTextController = TextEditingController();
  
  bool _isListView = true;

  final List<MockFridgeItem> _mockItems = [
    MockFridgeItem(id: '1', name: 'Milk', area: AreaType.fridge, quantity: 2, expirationDate: DateTime.now().add(const Duration(days: 5))),
    MockFridgeItem(id: '2', name: 'Eggs', area: AreaType.fridge, quantity: 6, expirationDate: DateTime.now().add(const Duration(days: 10))),
    MockFridgeItem(id: '3', name: 'Apples', area: AreaType.fridge, weight: 500, expirationDate: DateTime.now().add(const Duration(days: 7))),
  ];

  @override
  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    weightController.dispose();
    dateTextController.dispose();
    super.dispose();
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'none';
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
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
              _buildSearchBar(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [_buildViewToggle(), _buildCategorySelector(context)],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isListView ? _buildGlassList(_mockItems) : _buildSmallGlassGrid(_mockItems),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildAddButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader(BuildContext context) {
    final themeColor = getStatusColor('safe'); // Applichiamo il colore
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
        Text('Fridge Keeping', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: themeColor)),
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: Colors.white, shape: BoxShape.circle,
            border: Border.all(color: themeColor.withValues(alpha: 0.1), width: 1),
            boxShadow: [BoxShadow(color: themeColor.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Icon(Icons.qr_code_scanner_rounded, color: themeColor, size: 22),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final themeColor = getStatusColor('safe');
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          height: 55, padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: themeColor.withValues(alpha: 0.2), width: 1.2),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    hintStyle: GoogleFonts.poppins(color: themeColor.withValues(alpha: 0.5), fontSize: 15),
                    border: InputBorder.none,
                  ),
                  style: GoogleFonts.poppins(color: const Color(0xFF3D342C)),
                ),
              ),
              Icon(Icons.search_rounded, color: themeColor, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    final themeColor = getStatusColor('safe');
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColor.withValues(alpha: 0.1), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isListView = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isListView ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(18),
                boxShadow: _isListView ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2))] : [],
              ),
              child: Icon(Icons.view_list_rounded, size: 22, color: _isListView ? themeColor : themeColor.withValues(alpha: 0.4)),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _isListView = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: !_isListView ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(18),
                boxShadow: !_isListView ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2))] : [],
              ),
              child: Icon(Icons.grid_view_rounded, size: 22, color: !_isListView ? themeColor : themeColor.withValues(alpha: 0.4)),
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
          color: const Color(0xFF3D342C), borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: const Color(0xFF3D342C).withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_selectedCategory.label, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
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
                  Container(width: 50, height: 5, margin: const EdgeInsets.only(bottom: 30), decoration: BoxDecoration(color: getStatusColor('safe').withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10))),
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
      onTap: () { setState(() => _selectedCategory = areaType); Navigator.pop(context); },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(areaType.label, style: GoogleFonts.poppins(fontSize: 18, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? const Color(0xFFF4A261) : const Color(0xFF3D342C))),
          if (isSelected) const Icon(Icons.check_circle_rounded, color: Color(0xFFF4A261)),
        ],
      ),
    );
  }

  Widget _buildGlassList(List<MockFridgeItem> items) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(), itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildListItem(items[index]),
    );
  }

  Widget _buildListItem(MockFridgeItem item) {
    Color iconColor = getStatusColor('safe'); // Applichiamo il colore brillante alla card
    return GestureDetector(
      onTap: () => _showItemDetailModal(item),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            height: 85, padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [iconColor.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.4)]),
              borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: iconColor.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))]),
                  child: Icon(Icons.kitchen_outlined, color: iconColor, size: 28),
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

  Widget _buildSmallGlassGrid(List<MockFridgeItem> items) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.80),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildSmallGridCard(items[index]),
    );
  }

  Widget _buildSmallGridCard(MockFridgeItem item) {
    Color iconColor = getStatusColor('safe');
    return GestureDetector(
      onTap: () => _showItemDetailModal(item),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [iconColor.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.4)]),
              borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: iconColor.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))]),
                  child: Icon(Icons.kitchen_outlined, color: iconColor, size: 24),
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

  Future<void> _showItemDetailModal(MockFridgeItem item) async {
    await showModalBottomSheet<bool>(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => CohostFridgeItemDetailSheet(item: item),
    );
  }

  Future<void> _showAddElementModal(BuildContext context) async {
    final themeColor = getStatusColor('safe');
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
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [themeColor.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.8)]),
                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 50, height: 5, margin: const EdgeInsets.only(bottom: 30), decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(10)))),
                  Text('Add an element', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: themeColor, letterSpacing: 0.5)),
                  const SizedBox(height: 30),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildModalTextField('Name', true, false, controller: nameController),
                          const SizedBox(height: 20),
                          _buildModalTextField('Weight (g) [optional]', false, true, controller: weightController),
                          const SizedBox(height: 20),
                          _buildModalTextField('Quantity [optional]', false, true, controller: quantityController),
                          const SizedBox(height: 20),
                          _buildModalTextField('Expire date [optional]', false, false, isDate: true, controller: dateTextController),
                          const SizedBox(height: 40),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
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

  Widget _buildModalTextField(String label, bool isRequired, bool isNumber, {bool isDate = false, TextEditingController? controller}) {
    final themeColor = getStatusColor('safe');
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
            border: Border.all(color: themeColor.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Center(
            child: TextField(
              controller: controller, readOnly: isDate, keyboardType: isNumber ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(border: InputBorder.none, hintText: isDate ? 'DD/MM/YYYY' : '', suffixIcon: isDate ? Icon(Icons.calendar_today_rounded, color: themeColor, size: 20) : null),
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C)),
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// COMPONENTE: POPUP DETTAGLIO OGGETTO
// ==========================================
class CohostFridgeItemDetailSheet extends StatefulWidget {
  final MockFridgeItem item;
  const CohostFridgeItemDetailSheet({super.key, required this.item});

  @override
  State<CohostFridgeItemDetailSheet> createState() => _CohostFridgeItemDetailSheetState();
}

class _CohostFridgeItemDetailSheetState extends State<CohostFridgeItemDetailSheet> {
  bool _isEditing = false;
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _weightController;
  late final TextEditingController _expirationDateController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.item.expirationDate;
    _nameController = TextEditingController(text: widget.item.name);
    _quantityController = TextEditingController(text: widget.item.quantity?.toString() ?? '');
    _weightController = TextEditingController(text: widget.item.weight?.toString() ?? '');
    _expirationDateController = TextEditingController(text: _formatDate(widget.item.expirationDate));
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'none';
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  void _handleSaveEdit() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Simulazione: Modifiche salvate!"), behavior: SnackBarBehavior.floating));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final itemColor = getStatusColor('safe'); // Applichiamo il colore brillante al popup

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.65,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [itemColor.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.7)]),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 50, height: 5, margin: const EdgeInsets.only(bottom: 30), decoration: BoxDecoration(color: itemColor.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(10)))),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: itemColor.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))]),
                      child: Icon(Icons.kitchen_outlined, color: itemColor, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _isEditing
                          ? TextField(controller: _nameController, decoration: const InputDecoration(border: InputBorder.none, hintText: 'Name'), style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: itemColor, letterSpacing: -0.5))
                          : Text(widget.item.name, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: itemColor, letterSpacing: -0.5)),
                    ),
                    if (!_isEditing) IconButton(onPressed: () => setState(() => _isEditing = true), icon: Icon(Icons.edit, color: itemColor, size: 22)),
                  ],
                ),
                const SizedBox(height: 30),
                if (!_isEditing) ...[
                  _buildModalDetailRow('Weight (g)', widget.item.weight?.toString() ?? 'none', itemColor), _buildModalDivider(),
                  _buildModalDetailRow('Quantity', widget.item.quantity?.toString() ?? 'none', itemColor), _buildModalDivider(),
                  _buildModalDetailRow('Expire date', _formatDate(widget.item.expirationDate), itemColor),
                ] else ...[
                  _buildModalEditRow(label: 'Weight (g)', controller: _weightController, color: itemColor, keyboardType: TextInputType.number), _buildModalDivider(),
                  _buildModalEditRow(label: 'Quantity', controller: _quantityController, color: itemColor, keyboardType: TextInputType.number), _buildModalDivider(),
                  _buildModalEditRow(label: 'Expire date', controller: _expirationDateController, color: itemColor, readOnly: true, onTap: () async {
                    final pickedDate = await showDatePicker(context: context, initialDate: _selectedDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (pickedDate != null && mounted) setState(() { _selectedDate = pickedDate; _expirationDateController.text = _formatDate(pickedDate); });
                  }),
                ],
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(onPressed: () { setState(() { _isEditing = false; _nameController.text = widget.item.name; _weightController.text = widget.item.weight?.toString() ?? ''; _quantityController.text = widget.item.quantity?.toString() ?? ''; _selectedDate = widget.item.expirationDate; _expirationDateController.text = _formatDate(widget.item.expirationDate); }); }, style: OutlinedButton.styleFrom(side: BorderSide(color: itemColor.withValues(alpha: 0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)), child: Text('Cancel', style: GoogleFonts.poppins(color: itemColor, fontWeight: FontWeight.w600))),
                        ElevatedButton(onPressed: _handleSaveEdit, style: ElevatedButton.styleFrom(backgroundColor: itemColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), elevation: 5, shadowColor: itemColor.withValues(alpha: 0.3)), child: Text('Save', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 10), Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C).withValues(alpha: 0.7)))]),
          const SizedBox(height: 8),
          Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white, width: 1)), child: Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF3D342C)))),
        ],
      ),
    );
  }

  Widget _buildModalDivider() { return Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.0), Colors.white.withValues(alpha: 0.8), Colors.white.withValues(alpha: 0.0)]))); }

  Widget _buildModalEditRow({required String label, required TextEditingController controller, required Color color, TextInputType keyboardType = TextInputType.text, bool readOnly = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 10), Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C).withValues(alpha: 0.7)))]),
          const SizedBox(height: 8),
          Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white, width: 1)),
            child: TextField(controller: controller, readOnly: readOnly, onTap: onTap, keyboardType: keyboardType, decoration: InputDecoration(border: InputBorder.none, suffixIcon: label == 'Expire date' ? const Icon(Icons.calendar_today_rounded, size: 18) : null), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF3D342C))),
          ),
        ],
      ),
    );
  }
}