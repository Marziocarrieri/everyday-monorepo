import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class CohostDietScreen extends StatefulWidget {
  const CohostDietScreen({super.key});

  @override
  State<CohostDietScreen> createState() => _CohostDietScreenState();
}

class _CohostDietScreenState extends State<CohostDietScreen> {
  bool _isUploading = false;
  
  // MOCK: true se vogliamo vedere il file caricato, false se vogliamo vedere la dropzone
  bool _hasDietFile = false; 

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

  // ==========================================
  // FUNZIONI SIMULATE
  // ==========================================
  Future<void> _simulateUploadPdf() async {
    setState(() => _isUploading = true);
    
    // Simuliamo un tempo di caricamento
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    setState(() {
      _isUploading = false;
      _hasDietFile = true; // Mostriamo la vista col file
    });
    _showSuccessSnackBar('Simulazione: Diet uploaded successfully');
  }

  void _simulateRemovePdf() {
    setState(() {
      _hasDietFile = false; // Torniamo alla dropzone
    });
    _showSuccessSnackBar('Simulazione: Diet removed');
  }

  void _simulateOpenPdf() {
    _showSuccessSnackBar('Simulazione: Apertura PDF in corso...');
  }

  // ==========================================
  // BUILD PRINCIPALE DELLO SCHERMO
  // ==========================================
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
              const SizedBox(height: 40),

              // MOSTRA O L'UPLOAD O IL FILE (Basato sul mock)
              Expanded(
                child: _hasDietFile
                    ? _buildPdfReadyView()
                    : _buildUploadView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SEZIONE 1: HEADER
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
          'Diet Plan',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF5A8B9E),
          ),
        ),
        const SizedBox(width: 48), // Bilancia la freccia
      ],
    );
  }

  // ==========================================
  // SEZIONE 2: STATO "NESSUN FILE" (DROPZONE)
  // ==========================================
  Widget _buildUploadView() {
    return GestureDetector(
      onTap: _isUploading ? null : _simulateUploadPdf,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF4A261).withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.6),
                ], 
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: const Color(0xFFF4A261).withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF4A261).withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : const Icon(
                          Icons.cloud_upload_outlined,
                          color: Color(0xFFF4A261),
                          size: 40,
                        ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Upload your Diet',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF3D342C),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap here to select a PDF file',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF3D342C).withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SEZIONE 3: STATO "FILE CARICATO"
  // ==========================================
  Widget _buildPdfReadyView() {
    return Column(
      children: [
        // CARD DEL FILE IN VETRO
        ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF5A8B9E).withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5A8B9E).withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Color(0xFFE76F51),
                    size: 60,
                  ), 
                  const SizedBox(height: 16),
                  Text(
                    'Diet Document',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3D342C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Added recently', // Mock date
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3D342C).withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // TASTO APRI
                  GestureDetector(
                    onTap: _simulateOpenPdf,
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
                            color: const Color(0xFF5A8B9E).withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Open PDF',
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
        ),

        const SizedBox(height: 20),

        // TASTO RIMUOVI/SOSTITUISCI
        GestureDetector(
          onTap: _simulateRemovePdf,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFE76F51).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFE76F51),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Remove and upload new',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE76F51),
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