import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

// --- MODELLO DATI PER LA STANZA ---
class RoomItem {
  final String id;
  final String name;
  final String floor;

  RoomItem({required this.id, required this.name, required this.floor});
}

class YourHomeScreen extends StatefulWidget {
  const YourHomeScreen({super.key});

  @override
  State<YourHomeScreen> createState() => _YourHomeScreenState();
}

class _YourHomeScreenState extends State<YourHomeScreen> {
  // Stato: Piano selezionato e Modalità Modifica
  String _selectedFloor = 'First Floor';
  bool _isEditMode = false;

  // Lista finta delle stanze (come da Figma)
  final List<RoomItem> _allRooms = [
    RoomItem(id: '1', name: 'Bathroom', floor: 'First Floor'),
    RoomItem(id: '2', name: 'Bedroom 1', floor: 'First Floor'),
    RoomItem(id: '3', name: 'Bedroom 2', floor: 'First Floor'),
    RoomItem(id: '4', name: 'Office', floor: 'First Floor'),
    RoomItem(id: '5', name: 'Kitchen', floor: 'First Floor'),
    RoomItem(id: '6', name: 'Master Bed', floor: 'Second Floor'), // Esempio altro piano
  ];

  final TextEditingController _roomNameController = TextEditingController();

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  // Filtra le stanze in base al piano selezionato
  List<RoomItem> get _currentFloorRooms {
    return _allRooms.where((room) => room.floor == _selectedFloor).toList();
  }

  void _removeRoom(String id) {
    setState(() {
      _allRooms.removeWhere((room) => room.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: _buildHeader(context),
            ),
            
            // PIANO SELEZIONATO E TASTO EDIT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tasto Edit (per mostrare/nascondere i meno rossi)
                  GestureDetector(
                    onTap: () => setState(() => _isEditMode = !_isEditMode),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isEditMode ? const Color(0xFFE76F51).withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _isEditMode ? const Color(0xFFE76F51).withValues(alpha: 0.5) : Colors.transparent),
                      ),
                      child: Text(
                        _isEditMode ? 'Done' : 'Edit Rooms',
                        style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600, 
                          color: _isEditMode ? const Color(0xFFE76F51) : const Color(0xFF5A8B9E)
                        ),
                      ),
                    ),
                  ),

                  // Pillola del Piano Selezionato
                  GestureDetector(
                    onTap: () => _showFloorSelectorModal(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D342C).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(_selectedFloor, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF3D342C))),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF3D342C), size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // GRIGLIA DELLE STANZE IN VETRO
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 colonne
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0, // Quadrati perfetti
                ),
                // Numero di stanze + 1 per il bottone "Aggiungi"
                itemCount: _currentFloorRooms.length + 1,
                itemBuilder: (context, index) {
                  if (index == _currentFloorRooms.length) {
                    return _buildAddRoomCard();
                  }
                  final room = _currentFloorRooms[index];
                  return _buildRoomCard(room);
                },
              ),
            ),
          ],
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
        Text('Your Home', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF5A8B9E))),
        const SizedBox(width: 48), // Bilancia lo spazio
      ],
    );
  }

  // --- CARD STANZA SINGOLA CON DRAG & DROP ---
  Widget _buildRoomCard(RoomItem room) {
    return DragTarget<RoomItem>(
      onAcceptWithDetails: (details) {
        final draggedRoom = details.data;
        if (draggedRoom.id != room.id) {
          setState(() {
            // Troviamo le posizioni delle due stanze nella lista
            final oldIndex = _allRooms.indexOf(draggedRoom);
            final newIndex = _allRooms.indexOf(room);
            
            // Magia: le scambiamo di posto!
            _allRooms[oldIndex] = room;
            _allRooms[newIndex] = draggedRoom;
          });
        }
      },
      builder: (context, candidateItems, rejectedItems) {
        // Se c'è un'altra card che sta "volando" sopra questa, candidateItems non è vuoto
        final isHovered = candidateItems.isNotEmpty;

        return LongPressDraggable<RoomItem>(
          data: room,
          // 1. Quello che vedi "volare" sotto al dito mentre trascini
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.4, // Grandezza simile alla griglia
              height: MediaQuery.of(context).size.width * 0.4,
              child: Opacity(
                opacity: 0.8,
                child: _buildInnerRoomCard(room, isHovered: false),
              ),
            ),
          ),
          // 2. Come appare la card originale mentre la stai spostando (semi-trasparente)
          childWhenDragging: Opacity(
            opacity: 0.3, 
            child: _buildInnerRoomCard(room, isHovered: false),
          ),
          // 3. La card normale a riposo (o illuminata se ci passi sopra con un'altra)
          child: _buildInnerRoomCard(room, isHovered: isHovered),
        );
      },
    );
  }

  // --- CONTENUTO GRAFICO DELLA CARD (Separato per riutilizzarlo nel trascinamento) ---
  Widget _buildInnerRoomCard(RoomItem room, {required bool isHovered}) {
    return Stack(
      children: [
        // Animazione fluida quando ci passi sopra con un'altra card!
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(isHovered ? 1.05 : 1.0), // Si ingrandisce
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [
                      // Se ci passi sopra si illumina di pesca, sennò è il solito vetro
                      isHovered ? const Color(0xFFF4A261).withValues(alpha: 0.2) : const Color(0xFF5A8B9E).withValues(alpha: 0.05), 
                      isHovered ? Colors.white.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.6)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isHovered ? const Color(0xFFF4A261).withValues(alpha: 0.5) : const Color(0xFF5A8B9E).withValues(alpha: 0.1), 
                    width: isHovered ? 2.0 : 1.5
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      room.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF3D342C)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Badge "Rimuovi" (visibile solo se hai premuto "Edit Rooms")
        if (_isEditMode)
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: () => _removeRoom(room.id),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE76F51).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE76F51).withValues(alpha: 0.3), width: 1),
                ),
                child: const Icon(Icons.remove_rounded, color: Color(0xFFE76F51), size: 16),
              ),
            ),
          ),
      ],
    );
  }

  // --- CARD AGGIUNGI STANZA (+) ---
  Widget _buildAddRoomCard() {
    return GestureDetector(
      onTap: () {
        _roomNameController.clear();
        _showAddRoomModal(context);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF5A8B9E).withValues(alpha: 0.03), // Leggerissimo azzurro
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF5A8B9E).withValues(alpha: 0.2), width: 1.5),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: const Color(0xFF5A8B9E).withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 5))]
                ),
                child: const Icon(Icons.add_rounded, color: Color(0xFF5A8B9E), size: 32),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MODAL: SELETTORE PIANO (Stile Solid Light Card)
  // ==========================================
  void _showFloorSelectorModal(BuildContext context) {
    final floors = ['First Floor', 'Second Floor', 'Third Floor'];

    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FA), // Sfondo grigio chiarissimo / bianco sporco
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.only(top: 15, left: 24, right: 24, bottom: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trattino per lo swipe (Drag handle)
              Center(
                child: Container(
                  width: 40, height: 4, 
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D342C).withValues(alpha: 0.15), 
                    borderRadius: BorderRadius.circular(10)
                  )
                ),
              ),
              const SizedBox(height: 25),
              
              // Generazione della lista dei piani
              ...floors.asMap().entries.map((entry) {
                final index = entry.key;
                final floor = entry.value;
                final isLast = index == floors.length - 1;
                
                return _buildFloorOption(context, floor, floor == _selectedFloor, isLast);
              }),
            ],
          ),
        );
      },
    );
  }

  // --- SINGOLA OPZIONE PIANO ---
  Widget _buildFloorOption(BuildContext context, String floorName, bool isActive, bool isLast) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFloor = floorName);
        Navigator.pop(context); // Chiude il modal dopo la selezione
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.transparent,
          // Aggiunge la linea sottile grigia in basso, tranne per l'ultimo elemento
          border: isLast 
              ? null 
              : Border(bottom: BorderSide(color: const Color(0xFF3D342C).withValues(alpha: 0.08), width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              floorName, 
              style: GoogleFonts.poppins(
                fontSize: 18, 
                // Grassetto e arancione se attivo, normale e scuro se inattivo
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, 
                color: isActive ? const Color(0xFFF4A261) : const Color(0xFF3D342C)
              )
            ),
            // Spunta arancione visibile solo se è l'elemento attivo
            if (isActive) 
              const Icon(Icons.check_circle, color: Color(0xFFF4A261), size: 24),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MODAL: AGGIUNGI NUOVA STANZA
  // ==========================================
  void _showAddRoomModal(BuildContext context) {
    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.transparent, 
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              padding: EdgeInsets.only(left: 30, right: 30, top: 30, bottom: MediaQuery.of(context).viewInsets.bottom + 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight, 
                  colors: [const Color(0xFF5A8B9E).withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.9)]
                ), 
                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5)
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4, 
                      decoration: BoxDecoration(color: const Color(0xFF5A8B9E).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10))
                    )
                  ),
                  const SizedBox(height: 30),
                  
                  // TITOLO PRINCIPALE: Azzurro "Spray Cleaner"
                  Text(
                    'Add a new Room', 
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF7CB9E8))
                  ),
                  const SizedBox(height: 8),
                  
                  // SOTTOTITOLO: Marrone Scuro
                  Text(
                    'It will be added to $_selectedFloor', 
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C).withValues(alpha: 0.8))
                  ),
                  const SizedBox(height: 30),
                  
                  // Text Field in Vetro
                  Container(
                    height: 55, padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6), 
                      borderRadius: BorderRadius.circular(20), 
                      border: Border.all(color: const Color(0xFF5A8B9E).withValues(alpha: 0.2), width: 1.5)
                    ),
                    child: Center(
                      child: TextField(
                        controller: _roomNameController,
                        autofocus: true,
                        decoration: InputDecoration(
                          border: InputBorder.none, 
                          hintText: 'e.g. Living Room', 
                          hintStyle: GoogleFonts.poppins(color: const Color(0xFF3D342C).withValues(alpha: 0.3))
                        ),
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Bottone Aggiungi
                  GestureDetector(
                    onTap: () {
                      if (_roomNameController.text.isNotEmpty) {
                        setState(() {
                          _allRooms.add(RoomItem(id: DateTime.now().toString(), name: _roomNameController.text, floor: _selectedFloor));
                        });
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF5A8B9E), Color(0xFF3A5F6E)]), 
                        borderRadius: BorderRadius.circular(20), 
                        boxShadow: [BoxShadow(color: const Color(0xFF5A8B9E).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))]
                      ),
                      child: Center(
                        child: Text('Add Room', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))
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