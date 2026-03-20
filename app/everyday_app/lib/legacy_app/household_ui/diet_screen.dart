// TODO migrate to features/household
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/core/providers/app_state_providers.dart';
import 'package:everyday_app/legacy_app/services/diet_document_service.dart';
import 'package:everyday_app/shared/models/diet_document.dart';

// --- COLORI DEL DESIGN SYSTEM ---
const _bgColor = Color(0xFFF4F1ED);
const _inkColor = Color(0xFF1F3A44);
const _appTeal = Color(0xFF5A8B9E);
const _appCoral = Color(0xFFF28482);
const _appOrange = Color(0xFFF4A261);

class DietScreen extends ConsumerStatefulWidget {
  const DietScreen({super.key});

  @override
  ConsumerState<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends ConsumerState<DietScreen> {
  final DietDocumentService _dietDocumentService = DietDocumentService();

  bool _isUploading = false;

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

  Future<void> _uploadPdf() async {
    final userId = AppContext.instance.userId;
    final householdId = ref.read(currentHouseholdIdProvider);
    if (userId == null || householdId == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final picked = result.files.first;
    final bytes = picked.bytes;
    if (bytes == null) return;

    if (!mounted) return;
    setState(() {
      _isUploading = true;
    });

    try {
      await _dietDocumentService.uploadDietPdf(
        householdId: householdId,
        userId: userId,
        bytes: bytes,
      );
      if (!mounted) return;
      _showSuccessSnackBar('Diet uploaded');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _removePdf(DietDocument currentDiet) async {
    final userId = AppContext.instance.userId;
    final householdId = ref.read(currentHouseholdIdProvider);
    if (userId == null || householdId == null) return;

    try {
      await _dietDocumentService.removeDietPdf(
        householdId: householdId,
        userId: userId,
        currentDiet: currentDiet,
      );
      if (!mounted) return;
      _showSuccessSnackBar('Diet deleted');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _openPdf(DietDocument currentDiet) async {
    try {
      final uri = Uri.parse(currentDiet.url);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Unable to open PDF')));
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dietAsync = ref.watch(dietStreamProvider);

    return Scaffold(
      backgroundColor: _bgColor, // Sfondo Crema
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 40),

              Expanded(
                child: dietAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_appTeal),
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Text(
                      error.toString(),
                      style: GoogleFonts.manrope(color: _appCoral),
                    ),
                  ),
                  data: (currentDiet) {
                    if (currentDiet == null) {
                      return _buildUploadView();
                    }

                    return _buildPdfReadyView(currentDiet);
                  },
                ),
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
      children: [
        // Pulsante Indietro Minimalista (senza sfondo)
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
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
          ),
        ),
        // Titolo Centrato
        Text(
          'Diet Plan',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _inkColor,
            letterSpacing: -0.5,
          ),
        ),
        // Spazio vuoto per bilanciare l'header
        const Expanded(child: SizedBox()),
      ],
    );
  }

  // --- UPLOAD VIEW: PANNELLO "VETRO SMOKED" ---
  Widget _buildUploadView() {
    return Center(
      child: GestureDetector(
        onTap: _isUploading ? null : _uploadPdf,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              // Ombra morbida per elevare il pannello
              BoxShadow(
                color: _inkColor.withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 300, // Altezza fissa per un bell'effetto visivo
                decoration: BoxDecoration(
                  color: _inkColor.withOpacity(0.03), // Leggera patina scura
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.7), // Bordo bianco satinato
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4), // Cerchio più chiaro
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _appOrange.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(_appOrange),
                              ),
                            )
                          : const Icon(
                              Icons.cloud_upload_outlined,
                              color: _appOrange,
                              size: 40,
                            ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Upload your Diet',
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _inkColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap here to select a PDF file',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _inkColor.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- PDF VIEW: PANNELLO "VETRO SATINATO" ---
  Widget _buildPdfReadyView(DietDocument currentDiet) {
    final uploadedAt = currentDiet.uploadedAt;
    final subtitle =
        'Added on ${uploadedAt.day.toString().padLeft(2, '0')}/${uploadedAt.month.toString().padLeft(2, '0')}/${uploadedAt.year}';

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: _inkColor.withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: _inkColor.withOpacity(0.03), // Leggera patina
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.7),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _appCoral.withOpacity(0.1), // Sfondo leggero rosso
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: _appCoral,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Diet Document',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _inkColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _inkColor.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // TASTO APRI (Pulsante Pieno Teal)
                    GestureDetector(
                      onTap: () => _openPdf(currentDiet),
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
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Open PDF',
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
        ),

        const SizedBox(height: 32),

        // TASTO RIMUOVI/SOSTITUISCI (Pulsante Outlined Rosso)
        GestureDetector(
          onTap: () => _removePdf(currentDiet),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _appCoral.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  color: _appCoral,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Remove and upload new',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _appCoral,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}