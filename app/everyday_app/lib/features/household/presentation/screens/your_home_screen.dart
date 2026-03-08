import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/features/household/data/models/household_floor.dart';
import 'package:everyday_app/features/household/data/services/home_configuration_service.dart';

// --- MODELLO DATI PER LA STANZA ---
class RoomItem {
  final String id;
  final String name;
  final String floor;
  final String floorId;
  final String? roomType;

  RoomItem({
    required this.id,
    required this.name,
    required this.floor,
    required this.floorId,
    this.roomType,
  });
}

class YourHomeScreen extends StatefulWidget {
  const YourHomeScreen({super.key});

  @override
  State<YourHomeScreen> createState() => _YourHomeScreenState();
}

class _YourHomeScreenState extends State<YourHomeScreen> {
  // Stato: Piano selezionato e Modalità Modifica
  String _selectedFloor = '';
  String? _selectedFloorId;
  bool _isEditMode = false;
  bool _isLoading = true;
  String? _error;

  final List<RoomItem> _allRooms = [];
  final HomeConfigurationService _homeConfigurationService =
      HomeConfigurationService();
  List<HouseholdFloor> _floors = const [];
  static const List<String> _roomTypes = [
    'kitchen',
    'bathroom',
    'bedroom',
    'living_room',
    'garage',
    'garden',
    'other',
  ];

  String _formatRoomTypeLabel(String rawType) {
    final normalized = rawType.trim().replaceAll('_', ' ');
    if (normalized.isEmpty) return rawType;

    return normalized
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _roomDisplayLabel(RoomItem room) {
    final roomType = room.roomType;
    if (roomType == null || roomType.trim().isEmpty) {
      return room.name;
    }
    return '${room.name} (${_formatRoomTypeLabel(roomType)})';
  }

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
    _loadHomeConfiguration();
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<String> get _availableFloors {
    return _floors.map((floor) => floor.name).toList();
  }

  // Filtra le stanze in base al piano selezionato
  List<RoomItem> get _currentFloorRooms {
    final selectedFloorId = _selectedFloorId;
    if (selectedFloorId == null) return const [];
    return _allRooms
        .where((room) => room.floorId == selectedFloorId)
        .toList();
  }

  Future<void> _loadHomeConfiguration() async {
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
      final floors = await _homeConfigurationService.loadFloors(householdId);

      if (!mounted) return;
      if (floors.isEmpty) {
        setState(() {
          _floors = const [];
          _allRooms.clear();
          _selectedFloor = '';
          _selectedFloorId = null;
        });
        return;
      }

      HouseholdFloor selectedFloor = floors.first;
      final currentSelectedFloorId = _selectedFloorId;
      if (currentSelectedFloorId != null) {
        for (final floor in floors) {
          if (floor.id == currentSelectedFloorId) {
            selectedFloor = floor;
            break;
          }
        }
      }

      final rooms = await _homeConfigurationService.loadRooms(
        householdId: householdId,
        floorId: selectedFloor.id,
      );

      if (!mounted) return;
      setState(() {
        _floors = floors;
        _selectedFloor = selectedFloor.name;
        _selectedFloorId = selectedFloor.id;
        _allRooms
          ..clear()
          ..addAll(
            rooms
                .map(
                  (room) => RoomItem(
                    id: room.id,
                    name: room.name,
                    floor: selectedFloor.name,
                    floorId: selectedFloor.id,
                    roomType: room.roomType,
                  ),
                )
                .toList(),
          );
      });
    } catch (error) {
      debugPrint('Error loading home configuration: $error');
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load home configuration';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addRoom(String roomName, {String? roomType}) async {
    final householdId = AppContext.instance.householdId;
    if (householdId == null) return;
    final floorId = _selectedFloorId;
    if (floorId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No floor available for this household yet'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await _homeConfigurationService.addRoom(
        householdId: householdId,
        floorId: floorId,
        name: roomName,
        roomType: roomType,
      );
      await _loadHomeConfiguration();
      _showSuccessSnackBar('Room added');
    } catch (error) {
      debugPrint('Error adding room: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _addFloor(String floorName) async {
    final householdId = AppContext.instance.householdId;
    if (householdId == null) return;

    try {
      await _homeConfigurationService.addFloor(
        householdId: householdId,
        name: floorName,
        floorOrder: _floors.length,
      );
      await _loadHomeConfiguration();
      _showSuccessSnackBar('Floor added');
    } catch (error) {
      debugPrint('Error adding floor: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _openAddFloorFlow() async {
    final floorName = await _showAddFloorModal(context);
    if (floorName == null || floorName.trim().isEmpty) return;
    await _addFloor(floorName.trim());
  }

  Future<void> _removeRoom(String id) async {
    try {
      await _homeConfigurationService.removeRoom(id);
      await _loadHomeConfiguration();
      _showSuccessSnackBar('Room deleted');
    } catch (error) {
      debugPrint('Error deleting room: $error');
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

            if (!_isLoading) ...[
              if (_floors.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
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
                    ],
                  ),
                ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),

            // GRIGLIA DELLE STANZE IN VETRO
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                    : (_selectedFloorId == null
                        ? _buildNoFloorsState()
                        : _currentFloorRooms.isEmpty
                        ? _buildNoRoomsState()
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
                    )),
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
            ..scaleByDouble(
              isHovered ? 1.05 : 1.0,
              isHovered ? 1.05 : 1.0,
              1.0,
              1.0,
            ), // Si ingrandisce
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
                      _roomDisplayLabel(room),
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
        final newRoom = await _showAddRoomModal(context);
        if (newRoom == null || newRoom.name.trim().isEmpty) return;
        await _addRoom(newRoom.name.trim(), roomType: newRoom.roomType);
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

    if (floors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No floors available yet'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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
              const SizedBox(height: 6),
              Container(
                height: 1,
                color: const Color(0xFF3D342C).withValues(alpha: 0.08),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  await _openAddFloorFlow();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        color: Color(0xFF5A8B9E),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+ Add floor',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5A8B9E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
        for (final floor in _floors) {
          if (floor.name == floorName) {
            setState(() {
              _selectedFloor = floor.name;
              _selectedFloorId = floor.id;
            });
            break;
          }
        }
        _loadHomeConfiguration();
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
  Future<_NewRoomData?> _showAddRoomModal(BuildContext context) {
    final roomNameController = TextEditingController();
    String? selectedRoomType;

    return showModalBottomSheet<_NewRoomData>(
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
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    return Column(
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

                  Text(
                    'Room type (optional)',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3D342C).withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 55,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF5A8B9E).withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRoomType,
                        isExpanded: true,
                        hint: Text(
                          'Select a type',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF3D342C).withValues(alpha: 0.4),
                          ),
                        ),
                        items: _roomTypes
                            .map(
                              (type) => DropdownMenuItem<String>(
                                value: type,
                                child: Text(
                                  type,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: const Color(0xFF3D342C),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setModalState(() {
                            selectedRoomType = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Bottone Aggiungi
                  GestureDetector(
                    onTap: () {
                      final roomName = roomNameController.text.trim();
                      if (roomName.isNotEmpty) {
                        Navigator.pop(
                          context,
                          _NewRoomData(
                            name: roomName,
                            roomType: selectedRoomType,
                          ),
                        );
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
                    );
                  },
                ),
              ),
            ),
            );
      },
    );
  }

  Widget _buildNoFloorsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No floors available',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3D342C).withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _openAddFloorFlow,
              icon: const Icon(Icons.add_rounded),
              label: const Text('+ Add your first floor'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showAddFloorModal(BuildContext context) {
    final floorNameController = TextEditingController();

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add a new floor',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5A8B9E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: floorNameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Ground Floor',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final floorName = floorNameController.text.trim();
                        if (floorName.isEmpty) return;
                        Navigator.pop(context, floorName);
                      },
                      child: const Text('Add floor'),
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

  Widget _buildNoRoomsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No rooms yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3D342C),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                final newRoom = await _showAddRoomModal(context);
                if (newRoom == null || newRoom.name.trim().isEmpty) return;
                await _addRoom(
                  newRoom.name.trim(),
                  roomType: newRoom.roomType,
                );
              },
              child: const Text('Add your first room'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewRoomData {
  final String name;
  final String? roomType;

  const _NewRoomData({required this.name, this.roomType});
}
