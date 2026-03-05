import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

// ==========================================
// MODELLI MOCKATI (Finti, solo per la UI)
// ==========================================
class MockHouseholdFloor {
  final String id;
  final String name;

  const MockHouseholdFloor({required this.id, required this.name});
}

class MockRoomItem {
  final String id;
  final String name;
  final String floor;
  final String floorId;
  final String? roomType;

  MockRoomItem({
    required this.id,
    required this.name,
    required this.floor,
    required this.floorId,
    this.roomType,
  });
}

class _NewRoomData {
  final String name;
  final String? roomType;

  const _NewRoomData({required this.name, this.roomType});
}

// ==========================================
// SCHERMATA PRINCIPALE
// ==========================================
class CohostYourHomeScreen extends StatefulWidget {
  const CohostYourHomeScreen({super.key});

  @override
  State<CohostYourHomeScreen> createState() => _CohostYourHomeScreenState();
}

class _CohostYourHomeScreenState extends State<CohostYourHomeScreen> {
  // Stato: Piano selezionato e Modalità Modifica
  String _selectedFloor = 'Ground Floor';
  String? _selectedFloorId = 'floor_1';
  bool _isEditMode = false;

  // Dati Finti
  final List<MockHouseholdFloor> _floors = [
    const MockHouseholdFloor(id: 'floor_1', name: 'Ground Floor'),
    const MockHouseholdFloor(id: 'floor_2', name: 'First Floor'),
  ];

  late List<MockRoomItem> _allRooms;

  static const List<String> _roomTypes = [
    'kitchen',
    'bathroom',
    'bedroom',
    'living_room',
    'garage',
    'garden',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    // Inizializziamo le stanze finte
    _allRooms = [
      MockRoomItem(id: 'r1', name: 'Main Kitchen', floor: 'Ground Floor', floorId: 'floor_1', roomType: 'kitchen'),
      MockRoomItem(id: 'r2', name: 'Living Area', floor: 'Ground Floor', floorId: 'floor_1', roomType: 'living_room'),
      MockRoomItem(id: 'r3', name: 'Master Bedroom', floor: 'First Floor', floorId: 'floor_2', roomType: 'bedroom'),
      MockRoomItem(id: 'r4', name: 'Guest Bath', floor: 'First Floor', floorId: 'floor_2', roomType: 'bathroom'),
    ];
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

  // Helper per la UI delle tipologie
  String _formatRoomTypeLabel(String rawType) {
    final normalized = rawType.trim().replaceAll('_', ' ');
    if (normalized.isEmpty) return rawType;

    return normalized.split(' ').where((word) => word.isNotEmpty).map(
      (word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
    ).join(' ');
  }

  String _roomDisplayLabel(MockRoomItem room) {
    final roomType = room.roomType;
    if (roomType == null || roomType.trim().isEmpty) return room.name;
    return '${room.name}\n(${_formatRoomTypeLabel(roomType)})';
  }

  // Filtra le stanze in base al piano selezionato
  List<MockRoomItem> get _currentFloorRooms {
    if (_selectedFloorId == null) return const [];
    return _allRooms.where((room) => room.floorId == _selectedFloorId).toList();
  }

  // --- AZIONI SIMULATE ---
  void _simulateAddRoom(String roomName, {String? roomType}) {
    setState(() {
      _allRooms.add(
        MockRoomItem(
          id: DateTime.now().toString(),
          name: roomName,
          floor: _selectedFloor,
          floorId: _selectedFloorId!,
          roomType: roomType,
        ),
      );
    });
    _showSuccessSnackBar('Simulazione: Room added');
  }

  void _simulateAddFloor(String floorName) {
    final newId = 'floor_${_floors.length + 1}';
    setState(() {
      _floors.add(MockHouseholdFloor(id: newId, name: floorName));
      _selectedFloor = floorName;
      _selectedFloorId = newId;
    });
    _showSuccessSnackBar('Simulazione: Floor added');
  }

  Future<void> _openAddFloorFlow() async {
    final floorName = await _showAddFloorModal(context);
    if (floorName == null || floorName.trim().isEmpty) return;
    _simulateAddFloor(floorName.trim());
  }

  void _simulateRemoveRoom(String id) {
    setState(() {
      _allRooms.removeWhere((r) => r.id == id);
    });
    _showSuccessSnackBar('Simulazione: Room deleted');
  }


  // ==========================================
  // BUILD PRINCIPALE DELLO SCHERMO
  // ==========================================
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

            if (_floors.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tasto Edit
                        GestureDetector(
                          onTap: () => setState(() => _isEditMode = !_isEditMode),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _isEditMode ? const Color(0xFFE76F51).withValues(alpha: 0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isEditMode ? const Color(0xFFE76F51).withValues(alpha: 0.5) : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              _isEditMode ? 'Done' : 'Edit Rooms',
                              style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w600,
                                color: _isEditMode ? const Color(0xFFE76F51) : const Color(0xFF5A8B9E),
                              ),
                            ),
                          ),
                        ),
                        
                        // Selettore Piano
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
                                Text(
                                  _selectedFloor,
                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF3D342C)),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF3D342C), size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            // GRIGLIA DELLE STANZE IN VETRO
            Expanded(
              child: _selectedFloorId == null
                  ? _buildNoFloorsState()
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.0,
                      ),
                      itemCount: _currentFloorRooms.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _currentFloorRooms.length) {
                          return _buildAddRoomCard();
                        }
                        return _buildRoomCard(_currentFloorRooms[index]);
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
        Text(
          'Your Home',
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF5A8B9E)),
        ),
        const SizedBox(width: 48), // Bilancia lo spazio
      ],
    );
  }

  // --- CARD STANZA SINGOLA CON DRAG & DROP ---
  Widget _buildRoomCard(MockRoomItem room) {
    return DragTarget<MockRoomItem>(
      onAcceptWithDetails: (details) {
        final draggedRoom = details.data;
        if (draggedRoom.id != room.id) {
          setState(() {
            final oldIndex = _allRooms.indexOf(draggedRoom);
            final newIndex = _allRooms.indexOf(room);
            _allRooms[oldIndex] = room;
            _allRooms[newIndex] = draggedRoom;
          });
        }
      },
      builder: (context, candidateItems, rejectedItems) {
        final isHovered = candidateItems.isNotEmpty;

        return LongPressDraggable<MockRoomItem>(
          data: room,
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.4,
              height: MediaQuery.of(context).size.width * 0.4,
              child: Opacity(opacity: 0.8, child: _buildInnerRoomCard(room, isHovered: false)),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: _buildInnerRoomCard(room, isHovered: false)),
          child: _buildInnerRoomCard(room, isHovered: isHovered),
        );
      },
    );
  }

  Widget _buildInnerRoomCard(MockRoomItem room, {required bool isHovered}) {
    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scaleByDouble(isHovered ? 1.05 : 1.0, isHovered ? 1.05 : 1.0, 1.0, 1.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [
                      isHovered ? const Color(0xFFF4A261).withValues(alpha: 0.2) : const Color(0xFF5A8B9E).withValues(alpha: 0.05),
                      isHovered ? Colors.white.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isHovered ? const Color(0xFFF4A261).withValues(alpha: 0.5) : const Color(0xFF5A8B9E).withValues(alpha: 0.1),
                    width: isHovered ? 2.0 : 1.5,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      _roomDisplayLabel(room), textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF3D342C)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_isEditMode)
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: () => _simulateRemoveRoom(room.id),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE76F51).withValues(alpha: 0.15), shape: BoxShape.circle,
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
      onTap: () async {
        final newRoom = await _showAddRoomModal(context);
        if (newRoom == null || newRoom.name.trim().isEmpty) return;
        _simulateAddRoom(newRoom.name.trim(), roomType: newRoom.roomType);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF5A8B9E).withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF5A8B9E).withValues(alpha: 0.2), width: 1.5),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: const Color(0xFF5A8B9E).withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 5))],
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
  // MODAL: SELETTORE PIANO E AGGIUNTA
  // ==========================================
  void _showFloorSelectorModal(BuildContext context) {
    if (_floors.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.only(top: 15, left: 24, right: 24, bottom: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFF3D342C).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 25),
              ..._floors.asMap().entries.map((entry) {
                final isLast = entry.key == _floors.length - 1;
                return _buildFloorOption(context, entry.value, entry.value.name == _selectedFloor, isLast);
              }),
              const SizedBox(height: 6),
              Container(height: 1, color: const Color(0xFF3D342C).withValues(alpha: 0.08)),
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
                      const Icon(Icons.add_rounded, color: Color(0xFF5A8B9E)),
                      const SizedBox(width: 8),
                      Text('+ Add floor', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF5A8B9E))),
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

  Widget _buildFloorOption(BuildContext context, MockHouseholdFloor floor, bool isActive, bool isLast) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFloor = floor.name;
          _selectedFloorId = floor.id;
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: isLast ? null : Border(bottom: BorderSide(color: const Color(0xFF3D342C).withValues(alpha: 0.08), width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              floor.name,
              style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? const Color(0xFFF4A261) : const Color(0xFF3D342C),
              ),
            ),
            if (isActive) const Icon(Icons.check_circle, color: Color(0xFFF4A261), size: 24),
          ],
        ),
      ),
    );
  }

  Future<_NewRoomData?> _showAddRoomModal(BuildContext context) {
    final roomNameController = TextEditingController();
    String? selectedRoomType;

    return showModalBottomSheet<_NewRoomData>(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              padding: EdgeInsets.only(left: 30, right: 30, top: 30, bottom: MediaQuery.of(context).viewInsets.bottom + 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFF5A8B9E).withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.9)]),
                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
              ),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF5A8B9E).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10))),
                      ),
                      const SizedBox(height: 30),
                      Text('Add a new Room', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF7CB9E8))),
                      const SizedBox(height: 8),
                      Text('It will be added to $_selectedFloor', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C).withValues(alpha: 0.8))),
                      const SizedBox(height: 30),
                      Container(
                        height: 55, padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF5A8B9E).withValues(alpha: 0.2), width: 1.5),
                        ),
                        child: Center(
                          child: TextField(
                            controller: roomNameController, autofocus: true,
                            decoration: InputDecoration(border: InputBorder.none, hintText: 'e.g. Living Room', hintStyle: GoogleFonts.poppins(color: const Color(0xFF3D342C).withValues(alpha: 0.3))),
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text('Room type (optional)', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C).withValues(alpha: 0.8))),
                      const SizedBox(height: 10),
                      Container(
                        height: 55, padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF5A8B9E).withValues(alpha: 0.2), width: 1.5),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedRoomType, isExpanded: true,
                            hint: Text('Select a type', style: GoogleFonts.poppins(color: const Color(0xFF3D342C).withValues(alpha: 0.4))),
                            items: _roomTypes.map((type) => DropdownMenuItem<String>(value: type, child: Text(type, style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF3D342C))))).toList(),
                            onChanged: (value) => setModalState(() => selectedRoomType = value),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      GestureDetector(
                        onTap: () {
                          final roomName = roomNameController.text.trim();
                          if (roomName.isNotEmpty) {
                            Navigator.pop(context, _NewRoomData(name: roomName, roomType: selectedRoomType));
                          }
                        },
                        child: Container(
                          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF5A8B9E), Color(0xFF3A5F6E)]),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: const Color(0xFF5A8B9E).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
                          ),
                          child: Center(
                            child: Text('Add Room', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
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

  Future<String?> _showAddFloorModal(BuildContext context) {
    final floorNameController = TextEditingController();
    return showModalBottomSheet<String>(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5)),
              child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add a new floor', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF5A8B9E))),
                  const SizedBox(height: 16),
                  TextField(controller: floorNameController, autofocus: true, decoration: const InputDecoration(hintText: 'e.g. Ground Floor', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final floorName = floorNameController.text.trim();
                        if (floorName.isNotEmpty) Navigator.pop(context, floorName);
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

  Widget _buildNoFloorsState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('No floors available', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C).withValues(alpha: 0.7))),
          const SizedBox(height: 12),
          TextButton.icon(onPressed: _openAddFloorFlow, icon: const Icon(Icons.add_rounded), label: const Text('+ Add your first floor')),
        ],
      ),
    );
  }
}