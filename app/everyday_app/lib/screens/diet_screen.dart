import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_context.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  bool _isLoading = true;
  bool _isUploading = false;
  Map<String, dynamic>? _currentDiet;

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
    _loadDiet();
  }

  Future<void> _loadDiet() async {
    final userId = AppContext.instance.userId;
    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _currentDiet = null;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final response = await Supabase.instance.client
          .from('diet_document')
          .select('id, user_id, url, uploaded_at')
          .eq('user_id', userId)
          .order('uploaded_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _currentDiet = response;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  String? _extractStoragePathFromUrl(String url) {
    const marker = '/storage/v1/object/public/diets/';
    final index = url.indexOf(marker);
    if (index < 0) return null;
    return url.substring(index + marker.length);
  }

  Future<void> _uploadPdf() async {
    final userId = AppContext.instance.userId;
    if (userId == null) return;

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
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '$userId/$timestamp.pdf';

      await Supabase.instance.client.storage
          .from('diets')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: false,
            ),
          );

      final publicUrl = Supabase.instance.client.storage
          .from('diets')
          .getPublicUrl(storagePath);

      await Supabase.instance.client.from('diet_document').insert({
        'user_id': userId,
        'url': publicUrl,
      });

      await _loadDiet();
      if (!mounted) return;
      _showSuccessSnackBar('Diet uploaded');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _removePdf() async {
    final current = _currentDiet;
    if (current == null) return;
    final userId = AppContext.instance.userId;
    if (userId == null) return;

    try {
      final url = current['url'] as String;
      final storagePath = _extractStoragePathFromUrl(url);
      if (storagePath != null && storagePath.isNotEmpty) {
        await Supabase.instance.client.storage.from('diets').remove([
          storagePath,
        ]);
      }

      await Supabase.instance.client
          .from('diet_document')
          .delete()
          .eq('id', current['id'])
          .eq('user_id', userId);

      await _loadDiet();
      if (!mounted) return;
      _showSuccessSnackBar('Diet deleted');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _openPdf() async {
    final current = _currentDiet;
    if (current == null) return;

    try {
      final uri = Uri.parse(current['url'] as String);
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

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _currentDiet != null
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

  Widget _buildUploadView() {
    return GestureDetector(
      onTap: _isUploading ? null : _uploadPdf,
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
                ], // Toni pesca/arancio
              ),
              borderRadius: BorderRadius.circular(32),
              // Un bel bordo tratteggiato (simulato) o marcato per far capire che è una dropzone
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

  Widget _buildPdfReadyView() {
    final current = _currentDiet;
    if (current == null) return const SizedBox.shrink();

    final uploadedAt = DateTime.tryParse(
      current['uploaded_at'] as String? ?? '',
    );
    final subtitle = uploadedAt == null
        ? 'Added recently'
        : 'Added on ${uploadedAt.day.toString().padLeft(2, '0')}/${uploadedAt.month.toString().padLeft(2, '0')}/${uploadedAt.year}';

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
                  ), // Icona PDF Rossa/Corallo
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
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3D342C).withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // TASTO APRI
                  GestureDetector(
                    onTap: _openPdf,
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
