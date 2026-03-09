// TODO migrate to features/pets
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/core/app_router.dart';
import 'package:everyday_app/features/pets/data/models/pet.dart';
import 'package:everyday_app/features/pets/data/repositories/pets_repository.dart';


class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  // Sfondo Azzurro Premium (Tema Invertito)
  final Color invertedBgColor = const Color(0xFF5A8B9E); 
  final PetRepository _petRepository = PetRepository();
  List<Pet> _pets = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetches the current active household ID from your AppContext
      final householdId = AppContext.instance.requireHouseholdId();
      
      final pets = await _petRepository.getPets(householdId);

      if (!mounted) return;
      
      setState(() {
        _pets = pets;
      });
    } catch (error) {
      if (!mounted) return;
      
      setState(() {
        _error = error.toString();
      });
      debugPrint('UI Error loading members: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  // Funzione per aprire il popup di aggiunta Pet
  void _openAddPetSheet() async{
    final result = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AddPetSheet(),
    );
    if (result == true) {
      debugPrint("Refresh della lista in corso...");
      setState(() {
        _loadPets();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: invertedBgColor, 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              // --- HEADER INVERTITO (Con il tasto "+" ripristinato) ---
              SizedBox(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: _buildHeaderIcon(Icons.arrow_back_ios_new_rounded),
                    ),
                    Text(
                      'Pets',
                      style: GoogleFonts.poppins(
                        fontSize: 26, 
                        fontWeight: FontWeight.w800, 
                        color: Colors.white, 
                        letterSpacing: 0.5
                      ),
                    ),
                    GestureDetector(
                      onTap: _openAddPetSheet, // <--- APRE IL POPUP
                      child: _buildHeaderIcon(Icons.add_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 35),

              // --- LISTA ANIMALI (Card Vetro Bianco) ---


              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator()) // Show loader while fetching
                    : _error != null
                        ? Center(child: Text('Error: $_error')) // Show error if it fails
                        : _pets.isEmpty
                            ? const Center(child: Text('No pets found')) // Show empty state
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                itemCount: _pets.length,
                                itemBuilder: (context, index) {
                                  final pet = _pets[index];
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 20.0),
                                    child: _buildInvertedPetCard(
                                      pet,
                                      const Color(0xFFF4A261),
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  Widget _buildInvertedPetCard(Pet pet, Color pawColor) {
    return GestureDetector(
      onTap: () {
        final themeColor = pawColor == const Color(0xFF3D342C) ? const Color(0xFF5A8B9E) : pawColor;
        AppRouter.navigate<void>(
          context,
          AppRouteNames.petActivities,
          arguments: PetActivitiesRouteArgs(
            petId: pet.id,
            petColor: themeColor,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Colors.white.withValues(alpha: 0.25), Colors.white.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, 15))],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(color: pawColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: pawColor.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))]),
                          child: const Center(child: Icon(Icons.pets, color: Colors.white, size: 22)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pet.name, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                              const SizedBox(height: 2),
                              Text(pet.species ?? 'Unknown species', overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.3)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1, margin: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withValues(alpha: 0.0), Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0.0)])),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text('View\nActivity', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// NUOVO BOTTOM SHEET: AGGIUNGI PET
// ==========================================
class AddPetSheet extends StatefulWidget {
  const AddPetSheet({super.key});

  @override
  State<AddPetSheet> createState() => _AddPetSheetState();
}

class _AddPetSheetState extends State<AddPetSheet> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedType = 'Dog'; // Default
  final Color brandBlue = const Color(0xFF5A8B9E);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
        child: Container(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 20, 
            bottom: MediaQuery.of(context).viewInsets.bottom + 30, // Si alza con la tastiera
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle per lo swipe
              Container(width: 50, height: 5, decoration: BoxDecoration(color: brandBlue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 24),
              Text('Add a New Pet', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: brandBlue)),
              const SizedBox(height: 30),

              // CAMPO NOME (Liquid Glass Style)
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: brandBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: brandBlue.withValues(alpha: 0.1), width: 1.5),
                ),
                child: Center(
                  child: TextField(
                    controller: _nameController,
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C)),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Pet's Name",
                      hintStyle: GoogleFonts.poppins(color: const Color(0xFF3D342C).withValues(alpha: 0.3)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // SELETTORE SPECIE (Dog, Cat, Other)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTypePill('Dog', Icons.pets),
                  _buildTypePill('Cat', Icons.bakery_dining_outlined), // Un gatto stilizzato o simile
                  _buildTypePill('Other', Icons.help_outline_rounded),
                ],
              ),
              const SizedBox(height: 40),

              // BOTTONE CONFERMA
              GestureDetector(
                onTap: () async {
                  final name = _nameController.text.trim();
                  
                  // 1. Recuperiamo l'ID dal contesto (adatta questa riga alla tua implementazione)
                  final householdId = AppContext.instance.requireHouseholdId();

                  if (name.isEmpty) {
                    // Feedback rapido se il nome manca
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a name for your pet')),
                    );
                    return;
                  }

                  try {
                    // 2. Chiamata al Repository
                    final petRepo = PetRepository();
                    
                    await petRepo.createPet(
                      name: name,
                      species: _selectedType,
                      householdId: householdId,
                    );

                    // 3. Chiudiamo il foglio solo se il widget è ancora attivo
                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  } catch (e) {
                    // Qui catturi errori di rete o le famose RLS policies
                    debugPrint('Errore durante il salvataggio: $e');
                  }
                },

                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: brandBlue,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: brandBlue.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Center(
                    child: Text(
                      'Save Pet', 
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypePill(String type, IconData icon) {
    bool isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? brandBlue : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: brandBlue.withValues(alpha: 0.2), width: 1.5),
          boxShadow: isSelected ? [BoxShadow(color: brandBlue.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : brandBlue),
            const SizedBox(width: 8),
            Text(
              type, 
              style: GoogleFonts.poppins(
                fontSize: 14, 
                fontWeight: FontWeight.w600, 
                color: isSelected ? Colors.white : brandBlue
              ),
            ),
          ],
        ),
      ),
    );
  }
}