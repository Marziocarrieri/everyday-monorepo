import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import 'package:everyday_app/features/household/data/models/household_floor.dart';
import 'package:everyday_app/features/household/data/models/household_room.dart';
import 'package:everyday_app/features/household/data/services/home_configuration_service.dart';
import 'package:everyday_app/core/providers/app_state_providers.dart';
import 'package:everyday_app/features/household/presentation/providers/household_providers.dart';

class YourHomeScreen extends ConsumerStatefulWidget {
  const YourHomeScreen({super.key});

  @override
  ConsumerState<YourHomeScreen> createState() => _YourHomeScreenState();
}

class _YourHomeScreenState extends ConsumerState<YourHomeScreen> {
  // Stato: Piano selezionato e Modalità Modifica
  String? _selectedFloorId;
  bool _isEditMode = false;

  final HomeConfigurationService _homeConfigurationService =
      HomeConfigurationService();
  static const List<String> _roomTypes = [
    'kitchen',
    'bathroom',
    'bedroom',
    'living_room',
    'garage',
    'garden',
    'other',
  ];

  final Color primaryColor = const Color(0xFF5A8B9E);
  final Color accentColor = const Color(0xFFF4A261);
  final Color errorColor = const Color(0xFFF28482);

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

  String _roomDisplayLabel(HouseholdRoom room) {
    final roomType = room.roomType;
    if (roomType == null || roomType.trim().isEmpty) {
      return room.name;
    }
    return '${room.name}\n(${_formatRoomTypeLabel(roomType)})'; // A capo per design
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryColor,
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

  String _selectedFloorName(
    List<HouseholdFloor> floors,
    String? selectedFloorId,
  ) {
    if (selectedFloorId == null) return '';
    for (final floor in floors) {
      if (floor.id == selectedFloorId) {
        return floor.name;
      }
    }
    return '';
  }

  Future<void> _addRoom({
    required String roomName,
    required String floorId,
    String? roomType,
  }) async {
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null || householdId.isEmpty) {
      return;
    }

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
          content: Text(error.toString(), style: GoogleFonts.poppins()),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _addFloor(String floorName) async {
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null || householdId.isEmpty) {
      return;
    }

    final floors = ref
        .read(floorsStreamProvider(householdId))
        .maybeWhen(
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
          content: Text(error.toString(), style: GoogleFonts.poppins()),
          backgroundColor: errorColor,
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
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null || householdId.isEmpty) {
      return;
    }

    try {
      await _homeConfigurationService.removeRoom(id);
      ref.invalidate(roomsStreamProvider(householdId));
      ref.invalidate(floorsStreamProvider(householdId));
      _showSuccessSnackBar('Room deleted');
    } catch (error) {
      debugPrint('Error deleting room: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString(), style: GoogleFonts.poppins()),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final householdId = ref.watch(currentHouseholdIdProvider);
    if (householdId == null || householdId.isEmpty) {
      return _buildScaffoldBody(isLoading: false);
    }

    final floorsAsync = ref.watch(floorsStreamProvider(householdId));
    final roomsAsync = ref.watch(roomsStreamProvider(householdId));

    return floorsAsync.when(
      loading: () => _buildScaffoldBody(isLoading: true),
      error: (error, _) =>
          _buildScaffoldBody(isLoading: false, streamError: error),
      data: (floors) {
        final sortedFloors = _sortedFloors(floors);
        final selectedFloorId = _resolveSelectedFloorId(sortedFloors);
        final selectedFloorName = _selectedFloorName(
          sortedFloors,
          selectedFloorId,
        );

        return roomsAsync.when(
          loading: () => _buildScaffoldBody(isLoading: true),
          error: (error, _) =>
              _buildScaffoldBody(isLoading: false, streamError: error),
          data: (rooms) {
            final visibleRooms = selectedFloorId == null
                ? const <HouseholdRoom>[]
                : rooms
                      .where((room) => room.floorId == selectedFloorId)
                      .toList();

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF6F9FA),
              Color(0xFFE3EDF2),
            ], // Sfondo Premium App
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: _buildHeader(context),
              ),

              if (!isLoading) ...[
                if (floors.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // PULSANTE EDIT ROOMS
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _isEditMode = !_isEditMode),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _isEditMode
                                      ? errorColor.withValues(alpha: 0.1)
                                      : Colors.white.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _isEditMode
                                        ? errorColor.withValues(alpha: 0.4)
                                        : primaryColor.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                  boxShadow: _isEditMode
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: primaryColor.withValues(
                                              alpha: 0.05,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                ),
                                child: Text(
                                  _isEditMode ? 'Done' : 'Edit Rooms',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _isEditMode
                                        ? errorColor
                                        : primaryColor,
                                  ),
                                ),
                              ),
                            ),

                            // SELETTORE PIANO
                            GestureDetector(
                              onTap: () => _showFloorSelectorModal(
                                context,
                                floors: floors,
                                selectedFloorId: selectedFloorId,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF3D342C,
                                    ).withValues(alpha: 0.1),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF3D342C,
                                      ).withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      selectedFloorName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF3D342C),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
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

              if (streamError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: errorColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: errorColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            streamError.toString(),
                            style: GoogleFonts.poppins(
                              color: errorColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // GRIGLIA DELLE STANZE IN VETRO
              Expanded(
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      )
                    : (selectedFloorId == null
                          ? _buildNoFloorsState()
                          : visibleRooms.isEmpty
                          ? _buildNoRoomsState(
                              selectedFloorName: selectedFloorName,
                              selectedFloorId: selectedFloorId,
                            )
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
                              itemCount: visibleRooms.length + 1,
                              itemBuilder: (context, index) {
                                if (index == visibleRooms.length) {
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
                color: primaryColor.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: primaryColor,
              size: 20,
            ),
          ),
        ),
        Text(
          'Your Home',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: primaryColor,
          ),
        ),
        const SizedBox(width: 48), // Bilancia lo spazio
      ],
    );
  }

  // --- CARD STANZA SINGOLA ---
  Widget _buildRoomCard(HouseholdRoom room) {
    return _buildInnerRoomCard(room, isHovered: false);
  }

  // --- CONTENUTO GRAFICO DELLA CARD ---
  Widget _buildInnerRoomCard(HouseholdRoom room, {required bool isHovered}) {
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
            borderRadius: BorderRadius.circular(28), // Più tondo
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
                          ? accentColor.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.9),
                      isHovered
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isHovered
                        ? accentColor.withValues(alpha: 0.5)
                        : Colors.white,
                    width: isHovered ? 2.0 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getIconForRoomType(room.roomType),
                          color: primaryColor.withValues(alpha: 0.6),
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _roomDisplayLabel(room),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3D342C),
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

        // Badge "Rimuovi" (visibile solo se hai premuto "Edit Rooms")
        if (_isEditMode)
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () async => _removeRoom(room.id),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: errorColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: errorColor.withValues(alpha: 0.3),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: primaryColor.withValues(
                alpha: 0.05,
              ), // Leggerissimo azzurro
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(Icons.add_rounded, color: primaryColor, size: 32),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MODAL: SELETTORE PIANO (Stile pulito richiesto)
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
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
                  floor.id == selectedFloorId,
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
                      Icon(Icons.add_rounded, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Add floor',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
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
    HouseholdFloor floor,
    bool isActive,
    bool isLast,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFloorId = floor.id;
        });
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
              floor.name,
              style: GoogleFonts.poppins(
                fontSize: 18,
                // Grassetto e arancione se attivo, normale e scuro se inattivo
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? accentColor : const Color(0xFF3D342C),
              ),
            ),
            // Spunta arancione visibile solo se è l'elemento attivo
            if (isActive)
              Icon(Icons.check_circle, color: accentColor, size: 24),
          ],
        ),
      ),
    );
  }

  // --- MODAL: SCELTA TIPO STANZA (STILE VETRO/PREMIUM DA IMMAGINE) ---
  void _showRoomTypePickerModal(
    BuildContext context,
    Function(String?) onSelected,
    String? currentSelection,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: Colors.white.withValues(alpha: 0.95),
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
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF3D342C),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: primaryColor.withValues(alpha: 0.2)),

                  ListTile(
                    title: Text(
                      'None',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: currentSelection == null
                            ? primaryColor
                            : const Color(0xFF3D342C).withValues(alpha: 0.5),
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
                  Divider(color: primaryColor.withValues(alpha: 0.1)),

                  // Limitiamo l'altezza se ci sono troppi tipi per evitare che il dialog sia troppo lungo
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
                                  style: GoogleFonts.poppins(
                                    color: isSelected
                                        ? primaryColor
                                        : const Color(0xFF3D342C),
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
                                color: primaryColor.withValues(alpha: 0.1),
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

  // ==========================================
  // MODAL: AGGIUNGI NUOVO PIANO (Floor)
  // ==========================================
  Future<String?> _showAddFloorModal(BuildContext context) {
    final floorNameController = TextEditingController();

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
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 30,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                border: Border.all(color: Colors.white, width: 1.5),
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
                          color: const Color(
                            0xFF3D342C,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Add a new floor',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: TextField(
                          controller: floorNameController,
                          autofocus: true,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3D342C),
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'e.g. Ground Floor',
                            hintStyle: GoogleFonts.poppins(
                              color: const Color(
                                0xFF3D342C,
                              ).withValues(alpha: 0.3),
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
                        height: 60,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Save Floor',
                            style: GoogleFonts.poppins(
                              fontSize: 17,
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
          ),
        );
      },
    );
  }

  // ==========================================
  // MODAL: AGGIUNGI NUOVA STANZA (Room)
  // ==========================================
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
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
                color: Colors.white.withValues(alpha: 0.95),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: SafeArea(
                top: false,
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    // Helper locale per ricavare la label o il placeholder
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
                              color: const Color(
                                0xFF3D342C,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Add a new Room',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          'It will be added to $selectedFloorName',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(
                              0xFF3D342C,
                            ).withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Text Field in Vetro
                        Container(
                          height: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: TextField(
                              controller: roomNameController,
                              autofocus: true,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3D342C),
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'e.g. Living Room',
                                hintStyle: GoogleFonts.poppins(
                                  color: const Color(
                                    0xFF3D342C,
                                  ).withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Text(
                          'Room type (optional)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(
                              0xFF3D342C,
                            ).withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // --- NUOVO SELETTORE TIPO STANZA (SIMILE A ADD_TASK) ---
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
                            height: 60,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(
                                  0xFF3D342C,
                                ).withValues(alpha: 0.1),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  typeDisplayText,
                                  style: GoogleFonts.poppins(
                                    color: selectedRoomType == null
                                        ? const Color(
                                            0xFF3D342C,
                                          ).withValues(alpha: 0.4)
                                        : const Color(0xFF3D342C),
                                    fontWeight: selectedRoomType == null
                                        ? FontWeight.w500
                                        : FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Color(0xFF3D342C),
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
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: errorColor,
                                ),
                              );
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'Save Room',
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.layers_clear_outlined,
                size: 48,
                color: primaryColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No floors yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF3D342C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by adding the first floor\nof your beautiful home.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3D342C).withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _openAddFloorFlow,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
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
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.meeting_room_outlined,
                size: 48,
                color: primaryColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'This floor is empty',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF3D342C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first room to $selectedFloorName.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3D342C).withValues(alpha: 0.6),
              ),
            ),
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
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
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
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
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
