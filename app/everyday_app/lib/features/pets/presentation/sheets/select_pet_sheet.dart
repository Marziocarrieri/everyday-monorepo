import 'dart:ui';

import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/features/pets/data/models/pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

enum PetSelectionFlowMode { addActivity, viewActivity }

void openPetSelectionSheet(
  BuildContext context,
  AsyncValue<List<Pet>> pets, {
  PetSelectionFlowMode flowMode = PetSelectionFlowMode.viewActivity,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => SelectPetSheet(pets: pets, flowMode: flowMode),
  );
}

class SelectPetSheet extends StatefulWidget {
  final AsyncValue<List<Pet>> pets;
  final PetSelectionFlowMode flowMode;

  const SelectPetSheet({
    super.key,
    required this.pets,
    this.flowMode = PetSelectionFlowMode.viewActivity,
  });

  @override
  State<SelectPetSheet> createState() => _SelectPetSheetState();
}

class _SelectPetSheetState extends State<SelectPetSheet> {
  static const Color _titleInk = Color(0xFF1F3A44);
  static const Color _brandBlue = Color(0xFF5A8B9E);
  static const Color _petAccent = Color(0xFFF4A261);

  String? _selectedPetId;

  bool get _isAddActivityMode {
    return widget.flowMode == PetSelectionFlowMode.addActivity;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
        child: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 30,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFF7F3EF).withValues(alpha: 0.95),
                Colors.white.withValues(alpha: 0.82),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: widget.pets.when(
            loading: () => const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => SizedBox(
              height: 220,
              child: Center(
                child: Text(
                  'Error loading pets: $err',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ),
            data: (petsList) {
              final canContinue = _selectedPetId != null;
              final title = _isAddActivityMode
                  ? 'Add Activity For...'
                  : 'View Activity For...';

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _brandBlue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.manrope(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _titleInk,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _brandBlue.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Single select',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _brandBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (petsList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'No pets available in this household',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.withValues(alpha: 0.82),
                        ),
                      ),
                    )
                  else
                    ...petsList.map(_buildPetTile),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: !canContinue
                        ? null
                        : () {
                            final selectedId = _selectedPetId;
                            if (selectedId == null) {
                              return;
                            }

                            final navigator = Navigator.of(context);
                            navigator.pop();
                            navigator.pushNamed(
                              AppRouteNames.petActivities,
                              arguments: PetActivitiesRouteArgs(
                                petId: selectedId,
                                petColor: _petAccent,
                                openAddOnLaunch: _isAddActivityMode,
                              ),
                            );
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: !canContinue
                            ? null
                            : const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF5A8B9E), Color(0xFF3E6D81)],
                              ),
                        color: !canContinue
                            ? Colors.grey.withValues(alpha: 0.5)
                            : null,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: !canContinue
                              ? Colors.grey.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.8),
                          width: 1.5,
                        ),
                        boxShadow: !canContinue
                            ? []
                            : [
                                BoxShadow(
                                  color: const Color(
                                    0xFF5A8B9E,
                                  ).withValues(alpha: 0.28),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                      ),
                      child: Center(
                        child: Text(
                          _isAddActivityMode
                              ? 'Continue To Add Activity'
                              : 'Continue To Activity',
                          style: GoogleFonts.manrope(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
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
  }

  Widget _buildPetTile(Pet pet) {
    final isSelected = _selectedPetId == pet.id;
    final title = pet.name.trim().isEmpty ? 'Unnamed pet' : pet.name.trim();
    final subtitle = (pet.species ?? '').trim().isEmpty
        ? 'Unknown species'
        : pet.species!.trim();
    final initial = title.isEmpty ? '?' : title[0].toUpperCase();

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPetId = isSelected ? null : pet.id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [const Color(0xFFFFF0E2), const Color(0xFFF7FAFC)]
                : [
                    Colors.white.withValues(alpha: 0.88),
                    Colors.white.withValues(alpha: 0.56),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? _petAccent.withValues(alpha: 0.42)
                : Colors.white.withValues(alpha: 0.9),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _petAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _petAccent.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _titleInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _titleInk.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected
                  ? _petAccent
                  : _titleInk.withValues(alpha: 0.35),
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}
