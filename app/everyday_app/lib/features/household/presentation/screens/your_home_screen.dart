// TODO migrate to features/household
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import 'package:everyday_app/features/household/data/models/household_floor.dart';
import 'package:everyday_app/features/household/data/models/household_room.dart';
import 'package:everyday_app/features/household/data/services/home_configuration_service.dart';
import 'package:everyday_app/core/providers/app_state_providers.dart';
import 'package:everyday_app/features/household/presentation/providers/household_providers.dart';
import 'package:everyday_app/core/app_context.dart'; 

// --- COLORI DEL DESIGN SYSTEM ---
const _bgColor = Color(0xFFF4F1ED);
const _inkColor = Color(0xFF1F3A44);
const _appOrange = Color(0xFFF4A261);
const _appCoral = Color(0xFFF28482);
const _appTeal = Color(0xFF5A8B9E);

class YourHomeScreen extends ConsumerStatefulWidget {
  const YourHomeScreen({super.key});

  @override
  ConsumerState<YourHomeScreen> createState() => _YourHomeScreenState();
}

class _YourHomeScreenState extends ConsumerState<YourHomeScreen> {
  // Stato: Piano selezionato e Modalità Modifica
  String? _selectedFloorId;
  bool _isEditMode = false;
  String _searchQuery = '';

  final HomeConfigurationService _homeConfigurationService = HomeConfigurationService();
  
  static const List<String> _roomTypes = [
    'kitchen',
    'bathroom',
    'bedroom',
    'living_room',
    'garage',
    'garden',
    'other',
  ];

  // --- CONTROLLO RUOLO: Ritorna true solo se l'utente è HOST ---
  bool get _isHost {
    final role = AppContext.instance.activeMembership?.role;
    return role?.toUpperCase() == 'HOST';
  }

  String _formatRoomTypeLabel(String rawType) {
    final normalized = rawType.trim().replaceAll('_', ' ');
    if (normalized.isEmpty) return rawType;

    return normalized
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _roomDisplayLabel(HouseholdRoom room) {
    final roomType = room.roomType;
    if (roomType == null || roomType.trim().isEmpty) {
      return room.name;
    }
    return '${room.name}\n(${_formatRoomTypeLabel(roomType)})'; 
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _appTeal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<HouseholdFloor> _sortedFloors(List<HouseholdFloor> floors) {
    final sorted = [...floors]
      ..sort((a, b) => a.floorOrder.compareTo(b.floorOrder));
    return sorted;
  }

  String? _resolveSelectedFloorId(List<HouseholdFloor> floors) {
    if (floors.isEmpty) return null;

    final selectedFloorId = _selectedFloorId;
    if (selectedFloorId == null) return floors.first.id;

    final exists = floors.any((floor) => floor.id == selectedFloorId);
    return exists ? selectedFloorId : floors.first.id;
  }

  String _selectedFloorName(List<HouseholdFloor> floors, String? selectedFloorId) {
    if (selectedFloorId == null) return '';
    for (final floor in floors) {
      if (floor.id == selectedFloorId) {
        return floor.name;
      }
    }
    return '';
  }

  Future<void> _addRoom({required String roomName, required String floorId, String? roomType}) async {
    if (!_isHost) return; 

    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null || householdId.isEmpty) return;

    try {
      await _homeConfigurationService.addRoom(
        householdId: householdId,
        floorId: floorId,
        name: roomName,
        roomType: roomType,
      );
      _showSuccessSnackBar('Room added');
    } catch (error) {
      debugPrint('Error adding room: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString(), style: GoogleFonts.manrope()),
          backgroundColor: _appCoral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _addFloor(String floorName) async {
    if (!_isHost) return;

    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null || householdId.isEmpty) return;

    final floors = ref.read(floorsStreamProvider(householdId)).maybeWhen(
          data: (value) => value,
          orElse: () => const <HouseholdFloor>[],
        );

    try {
      await _homeConfigurationService.addFloor(
        householdId: householdId,
        name: floorName,
        floorOrder: floors.length,
      );
      _showSuccessSnackBar('Floor added');
    } catch (error) {
      debugPrint('Error adding floor: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString(), style: GoogleFonts.manrope()),
          backgroundColor: _appCoral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openAddFloorFlow() async {
    final floorName = await _showAddFloorModal(context);
    if (floorName == null || floorName.trim().isEmpty) return;
    await _addFloor(floorName.trim());
  }

  Future<void> _removeRoom(String id) async {
    if (!_isHost) return; 

    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null || householdId.isEmpty) return;

    try {
      await _homeConfigurationService.removeRoom(id);
      _showSuccessSnackBar('Room deleted');
    } catch (error) {
      debugPrint('Error deleting room: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString(), style: GoogleFonts.manrope()),
          backgroundColor: _appCoral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isHost && _isEditMode) {
      _isEditMode = false;
    }

    final householdId = ref.watch(currentHouseholdIdProvider);
    if (householdId == null || householdId.isEmpty) {
      return _buildScaffoldBody(isLoading: false);
    }

    final floorsAsync = ref.watch(floorsStreamProvider(householdId));
    final roomsAsync = ref.watch(roomsStreamProvider(householdId));

    return floorsAsync.when(
      loading: () => _buildScaffoldBody(isLoading: true),
      error: (error, _) => _buildScaffoldBody(isLoading: false, streamError: error),
      data: (floors) {
        final sortedFloors = _sortedFloors(floors);
        final selectedFloorId = _resolveSelectedFloorId(sortedFloors);
        final selectedFloorName = _selectedFloorName(sortedFloors, selectedFloorId);

        return roomsAsync.when(
          loading: () => _buildScaffoldBody(isLoading: true),
          error: (error, _) => _buildScaffoldBody(isLoading: false, streamError: error),
          data: (rooms) {
            final visibleRooms = selectedFloorId == null
                ? const <HouseholdRoom>[]
                : rooms.where((room) => room.floorId == selectedFloorId).toList();

            return _buildScaffoldBody(
              isLoading: false,
              floors: sortedFloors,
              selectedFloorId: selectedFloorId,
              selectedFloorName: selectedFloorName,
              visibleRooms: visibleRooms,
            );
          },
        );
      },
    );
  }

  Widget _buildScaffoldBody({
    required bool isLoading,
    Object? streamError,
    List<HouseholdFloor> floors = const [],
    String? selectedFloorId,
    String selectedFloorName = '',
    List<HouseholdRoom> visibleRooms = const [],
  }) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 32),

                  if (!isLoading && floors.isNotEmpty) ...[
                    // RIGA: SELETTORE PIANO A DESTRA
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildFloorSelectorButton(
                          context, 
                          floors: floors, 
                          selectedFloorId: selectedFloorId, 
                          selectedFloorName: selectedFloorName
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // RIGA: SELECT A SINISTRA
                    if (_isHost) 
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _buildEditModeToggle(),
                        ],
                      ),
                  ],
                ],
              ),
            ),

            if (streamError != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _appCoral.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _appCoral.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: _appCoral, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          streamError.toString(),
                          style: GoogleFonts.manrope(
                            color: _appCoral,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // GRIGLIA DELLE STANZE IN VETRO SATINATO
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: _appTeal))
                  : (selectedFloorId == null
                      ? _buildNoFloorsState()
                      : visibleRooms.isEmpty && !_isHost 
                          ? _buildNoRoomsState(
                              selectedFloorName: selectedFloorName,
                              selectedFloorId: selectedFloorId,
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                              physics: const BouncingScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, 
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.0, 
                              ),
                              itemCount: visibleRooms.length + (_isHost ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (_isHost && index == visibleRooms.length) {
                                  return _buildAddRoomCard(
                                    selectedFloorId: selectedFloorId,
                                    selectedFloorName: selectedFloorName,
                                  );
                                }
                                final room = visibleRooms[index];
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
  // UI PRINCIPALE 
  // ==========================================

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Pulsante Indietro (Nudo)
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            color: Colors.transparent,
            alignment: Alignment.centerLeft,
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _inkColor,
              size: 24,
            ),
          ),
        ),
        // Titolo Centrato
        Text(
          'Your Home',
          style: GoogleFonts.manrope(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _inkColor,
            letterSpacing: -0.5,
          ),
        ),
        // Bilancia Spazio (QR rimosso come richiesto)
        const SizedBox(width: 44), 
      ],
    );
  }

  // BOTTONE ARANCIONE SELEZIONA PIANO CON GRADIENTE (STILE FRIDGE)
  Widget _buildFloorSelectorButton(
    BuildContext context, {
    required List<HouseholdFloor> floors, 
    required String? selectedFloorId, 
    required String selectedFloorName
  }) {
    return GestureDetector(
      onTap: () => _showFloorSelectorModal(
        context,
        floors: floors,
        selectedFloorId: selectedFloorId,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_appOrange, Color(0xFFE76F51)], 
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _appOrange.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedFloorName,
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // TASTO SELECT MINIMAL
  Widget _buildEditModeToggle() {
    return GestureDetector(
      onTap: () => setState(() => _isEditMode = !_isEditMode),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isEditMode ? Icons.close_rounded : Icons.checklist_rounded,
              size: 20,
              color: _inkColor,
            ),
            const SizedBox(width: 6),
            Text(
              _isEditMode ? 'Cancel' : 'Select',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _inkColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CARD STANZA (VETRO SATINATO) ---
  Widget _buildRoomCard(HouseholdRoom room) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: _inkColor.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24), 
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: _inkColor.withOpacity(0.03), 
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8), // Bordo satinato
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getIconForRoomType(room.roomType),
                          color: _inkColor.withOpacity(0.8),
                          size: 36,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _roomDisplayLabel(room),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _inkColor,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Badge "Rimuovi" 
        if (_isEditMode && _isHost)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () async => _removeRoom(room.id),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _appCoral,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: _appCoral.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  IconData _getIconForRoomType(String? type) {
    switch (type) {
      case 'kitchen':
        return Icons.kitchen_rounded;
      case 'bathroom':
        return Icons.bathtub_outlined;
      case 'bedroom':
        return Icons.bed_outlined;
      case 'living_room':
        return Icons.weekend_outlined;
      case 'garage':
        return Icons.garage_outlined;
      case 'garden':
        return Icons.park_outlined;
      default:
        return Icons.door_front_door_outlined;
    }
  }

  // --- CARD AGGIUNGI STANZA (+) ---
  Widget _buildAddRoomCard({
    required String selectedFloorId,
    required String selectedFloorName,
  }) {
    return GestureDetector(
      onTap: () async {
        final newRoom = await _showAddRoomModal(
          context,
          selectedFloorName: selectedFloorName,
        );
        if (newRoom == null || newRoom.name.trim().isEmpty) return;
        await _addRoom(
          roomName: newRoom.name.trim(),
          floorId: selectedFloorId,
          roomType: newRoom.roomType,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _inkColor.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(
              decoration: BoxDecoration(
                color: _inkColor.withOpacity(0.03), 
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.7),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _inkColor, 
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _inkColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MODAL: SELETTORE PIANO (Molto chiaro e pulito)
  // ==========================================
  void _showFloorSelectorModal(
    BuildContext context, {
    required List<HouseholdFloor> floors,
    required String? selectedFloorId,
  }) {
    if (floors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No floors available yet',
            style: GoogleFonts.manrope(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _appCoral,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95), // Sfondo molto chiaro e pulito come da screen
                border: Border.all(color: Colors.white, width: 2),
              ),
              padding: EdgeInsets.only(
                top: 15,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 40,
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
                        color: _inkColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  ...floors.asMap().entries.map((entry) {
                    final index = entry.key;
                    final floor = entry.value;
                    final isLast = !_isHost && index == floors.length - 1;

                    return _buildFloorOption(
                      context,
                      floor,
                      floor.id == selectedFloorId,
                      isLast,
                    );
                  }),

                  if (_isHost) ...[
                    const SizedBox(height: 6),
                    Container(
                      height: 1,
                      color: _inkColor.withOpacity(0.08),
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
                            const Icon(Icons.add_rounded, color: _appTeal),
                            const SizedBox(width: 8),
                            Text(
                              'Add floor',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _appTeal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloorOption(
    BuildContext context,
    HouseholdFloor floor,
    bool isActive,
    bool isLast,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFloorId = floor.id;
        });
        Navigator.pop(context); 
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: _inkColor.withOpacity(0.08),
                    width: 1,
                  ),
                ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              floor.name,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? _appOrange : _inkColor,
              ),
            ),
            if (isActive)
              const Icon(Icons.check_circle, color: _appOrange, size: 24),
          ],
        ),
      ),
    );
  }

  // --- MODAL: SCELTA TIPO STANZA ---
  void _showRoomTypePickerModal(
    BuildContext context,
    Function(String?) onSelected,
    String? currentSelection,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.white.withOpacity(0.95), // Chiaro e pulito
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
              side: const BorderSide(color: Colors.white, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select Room Type',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _inkColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: _inkColor.withOpacity(0.1)),

                  ListTile(
                    title: Text(
                      'None',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        color: currentSelection == null
                            ? _appOrange
                            : _inkColor.withOpacity(0.5),
                        fontWeight: currentSelection == null
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    onTap: () {
                      onSelected(null);
                      Navigator.pop(context);
                    },
                  ),
                  Divider(color: _inkColor.withOpacity(0.1)),

                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _roomTypes.map((type) {
                          final isSelected = type == currentSelection;
                          return Column(
                            children: [
                              ListTile(
                                title: Text(
                                  _formatRoomTypeLabel(type),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.manrope(
                                    color: isSelected
                                        ? _appOrange
                                        : _inkColor,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    fontSize: 18,
                                  ),
                                ),
                                onTap: () {
                                  onSelected(type);
                                  Navigator.pop(context);
                                },
                              ),
                              Divider(
                                color: _inkColor.withOpacity(0.1),
                              ),
                            ],
                          );
                        }).toList(),
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

  // --- MODAL: AGGIUNGI NUOVO PIANO (Floor) ---
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
                bottom: MediaQuery.of(context).viewInsets.bottom + 30,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95), // Chiaro e pulito
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: _inkColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Add a new floor',
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _inkColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Vetro TextField
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: _inkColor.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.8),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _inkColor.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ]
                      ),
                      child: Center(
                        child: TextField(
                          controller: floorNameController,
                          autofocus: true,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _inkColor,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'e.g. Ground Floor',
                            hintStyle: GoogleFonts.manrope(
                              color: _inkColor.withOpacity(0.4),
                              fontWeight: FontWeight.w600
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    GestureDetector(
                      onTap: () {
                        final floorName = floorNameController.text.trim();
                        if (floorName.isEmpty) return;
                        Navigator.pop(context, floorName);
                      },
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _appTeal,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _appTeal.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Save Floor',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
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
          ),
        );
      },
    );
  }

  // --- MODAL: AGGIUNGI NUOVA STANZA (Room) ---
  Future<_NewRoomData?> _showAddRoomModal(
    BuildContext context, {
    required String selectedFloorName,
  }) {
    final roomNameController = TextEditingController();
    String? selectedRoomType;

    return showModalBottomSheet<_NewRoomData>(
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
                bottom: MediaQuery.of(context).viewInsets.bottom + 30,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95), // Chiaro e pulito
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: SafeArea(
                top: false,
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    String typeDisplayText = 'Select a type';
                    if (selectedRoomType != null) {
                      typeDisplayText = _formatRoomTypeLabel(selectedRoomType!);
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 48,
                            height: 5,
                            decoration: BoxDecoration(
                              color: _inkColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Add a new Room',
                          style: GoogleFonts.manrope(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: _inkColor,
                          ),
                        ),
                        Text(
                          'It will be added to $selectedFloorName',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _inkColor.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Text Field Vetro
                        Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: _inkColor.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.8),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _inkColor.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              )
                            ]
                          ),
                          child: Center(
                            child: TextField(
                              controller: roomNameController,
                              autofocus: true,
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _inkColor,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'e.g. Living Room',
                                hintStyle: GoogleFonts.manrope(
                                  color: _inkColor.withOpacity(0.4),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Text(
                          'Room type (optional)',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _inkColor.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // --- SELETTORE TIPO STANZA VETRO ---
                        GestureDetector(
                          onTap: () {
                            _showRoomTypePickerModal(context, (
                              String? newValue,
                            ) {
                              setModalState(() {
                                selectedRoomType = newValue;
                              });
                            }, selectedRoomType);
                          },
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: _inkColor.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.8),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _inkColor.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                )
                              ]
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  typeDisplayText,
                                  style: GoogleFonts.manrope(
                                    color: selectedRoomType == null
                                        ? _inkColor.withOpacity(0.4)
                                        : _inkColor,
                                    fontWeight: selectedRoomType == null
                                        ? FontWeight.w600
                                        : FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: _inkColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

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
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Name is required',
                                    style: GoogleFonts.manrope(),
                                  ),
                                  backgroundColor: _appCoral,
                                ),
                              );
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              color: _appTeal,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _appTeal.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'Save Room',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
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
          ),
        );
      },
    );
  }

  // --- EMPTY STATES ---
  Widget _buildNoFloorsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.8),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.layers_clear_outlined,
                size: 48,
                color: _appTeal.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No floors yet',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _inkColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isHost
                  ? 'Start by adding the first floor\nof your beautiful home.'
                  : 'Your host hasn\'t added\nany floors yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _inkColor.withOpacity(0.6),
              ),
            ),
            
            if (_isHost) ...[
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _openAddFloorFlow,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: _inkColor, 
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _inkColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add Floor',
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoRoomsState({
    required String selectedFloorName,
    required String selectedFloorId,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.8),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.meeting_room_outlined,
                size: 48,
                color: _appTeal.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'This floor is empty',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _inkColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isHost
                  ? 'Add your first room to $selectedFloorName.'
                  : 'There are no rooms on this floor yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _inkColor.withOpacity(0.6),
              ),
            ),
            
            if (_isHost) ...[
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () async {
                  final newRoom = await _showAddRoomModal(
                    context,
                    selectedFloorName: selectedFloorName,
                  );
                  if (newRoom == null || newRoom.name.trim().isEmpty) return;
                  await _addRoom(
                    roomName: newRoom.name.trim(),
                    floorId: selectedFloorId,
                    roomType: newRoom.roomType,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: _inkColor, 
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _inkColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add Room',
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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