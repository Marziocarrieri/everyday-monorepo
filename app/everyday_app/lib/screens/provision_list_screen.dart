import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

// --- MODELLO DATI PER LA LISTA DELLA SPESA ---
class ProvisionItem {
  final String id;
  final String name;
  final String? weight;
  final String? quantity;

  ProvisionItem({required this.id, required this.name, this.weight, this.quantity});
}

class ProvisionListScreen extends StatefulWidget {
  const ProvisionListScreen({super.key});

  @override
  State<ProvisionListScreen> createState() => _ProvisionListScreenState();
}

class _ProvisionListScreenState extends State<ProvisionListScreen> {
  // LISTA FINTA INIZIALE 
  final List<ProvisionItem> _provisionList = [
    ProvisionItem(id: '1', name: 'chicken breast', weight: '500 g', quantity: '1'),
    ProvisionItem(id: '2', name: 'salad', weight: null, quantity: '2'),
    ProvisionItem(id: '3', name: 'eggs', weight: null, quantity: '6'),
    ProvisionItem(id: '4', name: 'toilet paper', weight: null, quantity: '1'),
    ProvisionItem(id: '5', name: 'sausage', weight: '300 g', quantity: '1'),
  ];

  // Controller per l'aggiunta
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // Funzione per rimuovere un elemento
  void _removeItem(String id) {
    setState(() {
      _provisionList.removeWhere((item) => item.id == id);
    });
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
                child: _provisionList.isEmpty
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
  // WIDGET PRINCIPALI
  // ==========================================

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Tasto Indietro
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
        
        // Titolo
        Text('Provision List', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF5A8B9E))),
        
        // Tasto Aggiungi
        GestureDetector(
          onTap: () {
            _nameController.clear();
            _weightController.clear();
            _quantityController.clear();
            _showAddProvisionModal(context);
          },
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
      itemCount: _provisionList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _provisionList[index];
        return _buildListItem(item);
      },
    );
  }

  Widget _buildListItem(ProvisionItem item) {
    return GestureDetector(
      onTap: () => _showProvisionDetailModal(context, item), // Mostra i dettagli
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            height: 70, padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF5A8B9E).withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.4)]
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF5A8B9E).withValues(alpha: 0.1), width: 1),
            ),
            child: Row(
              children: [
                // Pallino stile Figma
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF3D342C), shape: BoxShape.circle)),
                const SizedBox(width: 16),
                
                // Nome
                Expanded(
                  child: Text(
                    item.name, 
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C))
                  )
                ),
                
                // Bottone Rimuovi (-) in Vetro Corallo
                GestureDetector(
                  onTap: () => _removeItem(item.id),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF28482).withValues(alpha: 0.15), // Rosso/Corallo pastello
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF28482).withValues(alpha: 0.3), width: 1),
                    ),
                    child: const Icon(Icons.remove_rounded, color: Color(0xFFF28482), size: 20),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 60, color: const Color(0xFF5A8B9E).withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Your list is empty.', style: GoogleFonts.poppins(color: const Color(0xFF5A8B9E).withValues(alpha: 0.6), fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      )
    );
  }

  // ==========================================
  // AGGIUNGI ELEMENTO ALLA LISTA
  // ==========================================
  void _showAddProvisionModal(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.only(left: 30, right: 30, top: 30, bottom: MediaQuery.of(context).viewInsets.bottom + 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFF7CB9E8).withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.8)]), 
                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 50, height: 5, margin: const EdgeInsets.only(bottom: 30), decoration: BoxDecoration(color: const Color(0xFF7CB9E8).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(10)))),
                  Text('Add a Provision', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF7CB9E8), letterSpacing: 0.5)),
                  const SizedBox(height: 30),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildModalTextField('Name', true, false, _nameController), const SizedBox(height: 20),
                          _buildModalTextField('Weight (g) [optional]', false, true, _weightController), const SizedBox(height: 20),
                          _buildModalTextField('Quantity [optional]', false, true, _quantityController),
                          const SizedBox(height: 40),
                          
                          // Bottone Conferma (Check)
                          GestureDetector(
                            onTap: () {
                              if (_nameController.text.isNotEmpty) {
                                setState(() {
                                  _provisionList.add(ProvisionItem(
                                    id: DateTime.now().toString(), // Generiamo un ID finto al volo
                                    name: _nameController.text,
                                    weight: _weightController.text.isNotEmpty ? '${_weightController.text} g' : null,
                                    quantity: _quantityController.text.isNotEmpty ? _quantityController.text : '1',
                                  ));
                                });
                                Navigator.pop(context); // Chiudi il modal
                              }
                            },
                            child: Container(
                              width: 70, height: 70,
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

  Widget _buildModalTextField(String label, bool isRequired, bool isNumber, TextEditingController controller) {
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
              decoration: const InputDecoration(border: InputBorder.none),
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C)),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // DETTAGLI ELEMENTO
  // ==========================================
  void _showProvisionDetailModal(BuildContext context, ProvisionItem item) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFFF4A261).withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.7)]), 
                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5)
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Occupa solo lo spazio necessario
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 50, height: 5, margin: const EdgeInsets.only(bottom: 30), decoration: BoxDecoration(color: const Color(0xFFF4A261).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(10)))),
                  
                  // Titolo
                  Text(item.name, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: const Color(0xFFF4A261), letterSpacing: -0.5)),
                  const SizedBox(height: 30),
                  
                  // Dettagli
                  _buildModalDetailRow('Weight (g)', item.weight ?? 'none'),
                  _buildModalDivider(),
                  _buildModalDetailRow('Quantity', item.quantity ?? '1'),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
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
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF4A261), shape: BoxShape.circle)), const SizedBox(width: 10),
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
}