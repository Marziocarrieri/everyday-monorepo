import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_context.dart';

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
  bool _isLoading = true;
  String? _error;

  final List<RoomItem> _allRooms = [];

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

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<String> get _availableFloors {
    final floors = <String>{};
    for (final room in _allRooms) {
      final floorName = room.floor.trim();
      if (floorName.isNotEmpty) {
        floors.add(floorName);
      }
    }
    final sortedFloors = floors.toList()..sort();
    return sortedFloors;
  }

  // Filtra le stanze in base al piano selezionato
  List<RoomItem> get _currentFloorRooms {
    return _allRooms.where((room) => room.floor == _selectedFloor).toList();
  }

  Future<void> _loadRooms() async {
    final householdId = AppContext.instance.householdId;
    if (householdId == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Missing household context';
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await Supabase.instance.client
          .from('home_configuration')
          .select('id, floor, room')
          .eq('household_id', householdId)
          .order('created_at', ascending: true);

      final rooms = (response as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .map(
            (json) => RoomItem(
              id: (json['id'] as String?) ?? '',
              name: (json['room'] as String?) ?? '',
              floor: (json['floor'] as String?) ?? 'First Floor',
            ),
          )
          .where((room) => room.id.isNotEmpty && room.name.isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        _allRooms
          ..clear()
          ..addAll(rooms);
        final floors = _availableFloors;
        if (floors.isNotEmpty && !floors.contains(_selectedFloor)) {
          _selectedFloor = floors.first;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error =
            'Home configuration table not available. Ask backend to add `home_configuration(household_id, floor, room)`.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addRoom(String roomName) async {
    final householdId = AppContext.instance.householdId;
    if (householdId == null) return;

    final floorName = _selectedFloor.trim().isEmpty
        ? 'First Floor'
        : _selectedFloor.trim();

    try {
      await Supabase.instance.client.from('home_configuration').insert({
        'household_id': householdId,
        'floor': floorName,
        'room': roomName,
      });
      if (mounted) {
        setState(() {
          _selectedFloor = floorName;
        });
      }
      await _loadRooms();
      _showSuccessSnackBar('Room added');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _removeRoom(String id) async {
    try {
      await Supabase.instance.client
          .from('home_configuration')
          .delete()
          .eq('id', id);
      await _loadRooms();
      _showSuccessSnackBar('Room deleted');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _isEditMode
                            ? const Color(0xFFE76F51).withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isEditMode
                              ? const Color(0xFFE76F51).withValues(alpha: 0.5)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        _isEditMode ? 'Done' : 'Edit Rooms',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _isEditMode
                              ? const Color(0xFFE76F51)
                              : const Color(0xFF5A8B9E),
                        ),
                      ),
                    ),
                  ),

                  // Pillola del Piano Selezionato
                  GestureDetector(
                    onTap: () => _showFloorSelectorModal(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D342C).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _selectedFloor,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3D342C),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF3D342C),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),

            // GRIGLIA DELLE STANZE IN VETRO
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 10.0,
                      ),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
        Text(
          'Your Home',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF5A8B9E),
          ),
        ),
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
              width:
                  MediaQuery.of(context).size.width *
                  0.4, // Grandezza simile alla griglia
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
          transform: Matrix4.identity()
            ..scale(isHovered ? 1.05 : 1.0), // Si ingrandisce
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      // Se ci passi sopra si illumina di pesca, sennò è il solito vetro
                      isHovered
                          ? const Color(0xFFF4A261).withValues(alpha: 0.2)
                          : const Color(0xFF5A8B9E).withValues(alpha: 0.05),
                      isHovered
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isHovered
                        ? const Color(0xFFF4A261).withValues(alpha: 0.5)
                        : const Color(0xFF5A8B9E).withValues(alpha: 0.1),
                    width: isHovered ? 2.0 : 1.5,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      room.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3D342C),
                      ),
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
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () async => _removeRoom(room.id),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE76F51).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE76F51).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.remove_rounded,
                  color: Color(0xFFE76F51),
                  size: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // --- CARD AGGIUNGI STANZA (+) ---
  Widget _buildAddRoomCard() {
    return GestureDetector(
      onTap: () async {
        final roomName = await _showAddRoomModal(context);
        if (roomName == null || roomName.trim().isEmpty) return;
        await _addRoom(roomName.trim());
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(
                0xFF5A8B9E,
              ).withValues(alpha: 0.03), // Leggerissimo azzurro
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF5A8B9E).withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5A8B9E).withValues(alpha: 0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFF5A8B9E),
                  size: 32,
                ),
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
    final floors = _availableFloors;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(
              0xFFF8F9FA,
            ), // Sfondo grigio chiarissimo / bianco sporco
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.only(
            top: 15,
            left: 24,
            right: 24,
            bottom: 40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trattino per lo swipe (Drag handle)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D342C).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Generazione della lista dei piani
              ...floors.asMap().entries.map((entry) {
                final index = entry.key;
                final floor = entry.value;
                final isLast = index == floors.length - 1;

                return _buildFloorOption(
                  context,
                  floor,
                  floor == _selectedFloor,
                  isLast,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // --- SINGOLA OPZIONE PIANO ---
  Widget _buildFloorOption(
    BuildContext context,
    String floorName,
    bool isActive,
    bool isLast,
  ) {
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
              : Border(
                  bottom: BorderSide(
                    color: const Color(0xFF3D342C).withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
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
                color: isActive
                    ? const Color(0xFFF4A261)
                    : const Color(0xFF3D342C),
              ),
            ),
            // Spunta arancione visibile solo se è l'elemento attivo
            if (isActive)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFF4A261),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MODAL: AGGIUNGI NUOVA STANZA
  // ==========================================
  Future<String?> _showAddRoomModal(BuildContext context) {
    final roomNameController = TextEditingController();

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              padding: EdgeInsets.only(
                left: 30,
                right: 30,
                top: 30,
                bottom: MediaQuery.of(context).viewInsets.bottom + 30,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF5A8B9E).withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.9),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5A8B9E).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // TITOLO PRINCIPALE: Azzurro "Spray Cleaner"
                  Text(
                    'Add a new Room',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF7CB9E8),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // SOTTOTITOLO: Marrone Scuro
                  Text(
                    'It will be added to $_selectedFloor',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3D342C).withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Text Field in Vetro
                  Container(
                    height: 55,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF5A8B9E).withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: TextField(
                        controller: roomNameController,
                        autofocus: true,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'e.g. Living Room',
                          hintStyle: GoogleFonts.poppins(
                            color: const Color(
                              0xFF3D342C,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3D342C),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Bottone Aggiungi
                  GestureDetector(
                    onTap: () {
                      final roomName = roomNameController.text.trim();
                      if (roomName.isNotEmpty) {
                        Navigator.pop(context, roomName);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5A8B9E), Color(0xFF3A5F6E)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF5A8B9E,
                            ).withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Add Room',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
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
