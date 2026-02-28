import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  // Questa variabile simula se abbiamo caricato un PDF o no.
  // In futuro la collegherai a Supabase per controllare se l'utente ha un file salvato.
  bool _hasUploadedDiet = false;

  // Funzione finta per simulare il caricamento
  void _uploadPdf() {
    // Qui metterai la logica del file picker
    setState(() {
      _hasUploadedDiet = true;
    });
  }

  // Funzione finta per rimuovere il PDF
  void _removePdf() {
    setState(() {
      _hasUploadedDiet = false;
    });
  }

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

              // LA MAGIA: Mostra l'upload se è falso, mostra il PDF se è vero!
              Expanded(
                child: _hasUploadedDiet ? _buildPdfReadyView() : _buildUploadView(),
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
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF5A8B9E).withValues(alpha: 0.1), width: 1),
              boxShadow: [BoxShadow(color: const Color(0xFF5A8B9E).withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF5A8B9E), size: 20),
          ),
        ),
        Text('Diet Plan', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF5A8B9E))),
        const SizedBox(width: 48), // Bilancia la freccia
      ],
    );
  }

  // --- STATO 1: NESSUN PDF CARICATO ---
  Widget _buildUploadView() {
    return GestureDetector(
      onTap: _uploadPdf, // Cliccando sull'area si apre il selettore file
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [const Color(0xFFF4A261).withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.6)], // Toni pesca/arancio
              ),
              borderRadius: BorderRadius.circular(32),
              // Un bel bordo tratteggiato (simulato) o marcato per far capire che è una dropzone
              border: Border.all(color: const Color(0xFFF4A261).withValues(alpha: 0.4), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: const Color(0xFFF4A261).withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: const Icon(Icons.cloud_upload_outlined, color: Color(0xFFF4A261), size: 40),
                ),
                const SizedBox(height: 24),
                Text('Upload your Diet', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF3D342C))),
                const SizedBox(height: 8),
                Text('Tap here to select a PDF file', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF3D342C).withValues(alpha: 0.5))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- STATO 2: PDF CARICATO E PRONTO ---
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
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [const Color(0xFF5A8B9E).withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: const Color(0xFF5A8B9E).withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFE76F51), size: 60), // Icona PDF Rossa/Corallo
                  const SizedBox(height: 16),
                  Text('My_Diet_Plan.pdf', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF3D342C))),
                  const SizedBox(height: 8),
                  Text('Added today', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF3D342C).withValues(alpha: 0.5))),
                  const SizedBox(height: 30),
                  
                  // TASTO APRI
                  GestureDetector(
                    onTap: () {
                      debugPrint("Apro il PDF...");
                      // Logica per aprire il PDF
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF5A8B9E), Color(0xFF3A5F6E)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: const Color(0xFF5A8B9E).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
                      ),
                      child: Center(
                        child: Text('Open PDF', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 20),

        // TASTO RIMUOVI/SOSTITUISCI (Sottile, meno invasivo)
        GestureDetector(
          onTap: _removePdf,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFE76F51).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete_outline_rounded, color: Color(0xFFE76F51), size: 20),
                const SizedBox(width: 8),
                Text('Remove and upload new', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFFE76F51))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}