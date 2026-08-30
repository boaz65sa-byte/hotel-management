// lib/features/guest_requests/presentation/hotel_qr_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'dart:io';

// Fallback used when the hotels.guest_pwa_url column is unset/unreachable.
const String kDefaultGuestPwaBaseUrl =
    'https://exquisite-cocada-7966bd.netlify.app';

class HotelQrScreen extends StatefulWidget {
  final String hotelId;
  final String hotelName;

  const HotelQrScreen({
    super.key,
    required this.hotelId,
    required this.hotelName,
  });

  @override
  State<HotelQrScreen> createState() => _HotelQrScreenState();
}

class _HotelQrScreenState extends State<HotelQrScreen> {
  final _qrKey = GlobalKey();
  bool _saving = false;

  String _baseUrl = kDefaultGuestPwaBaseUrl;
  bool _baseUrlLoading = true;
  String? _hotelName;

  String get _pwaUrl => '$_baseUrl/#/?hotel=${widget.hotelId}';

  @override
  void initState() {
    super.initState();
    _loadBaseUrl();
  }

  Future<void> _loadBaseUrl() async {
    try {
      final row = await supabase
          .from('hotels')
          .select('guest_pwa_url, name')
          .eq('id', widget.hotelId)
          .maybeSingle();
      final url = (row?['guest_pwa_url'] as String?)?.trim();
      final name = (row?['name'] as String?)?.trim();
      if (mounted) {
        setState(() {
          if (url != null && url.isNotEmpty) _baseUrl = url;
          if (name != null && name.isNotEmpty) _hotelName = name;
          _baseUrlLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _baseUrlLoading = false);
    }
  }

  Future<Uint8List?> _captureQr() async {
    final boundary = _qrKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  Future<void> _share() async {
    setState(() => _saving = true);
    try {
      final bytes = await _captureQr();
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/hotel_qr_${widget.hotelId}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'QR קוד — ${_hotelName ?? widget.hotelName}',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final bytes = await _captureQr();
      if (bytes == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/hotel_qr_${widget.hotelId}.png');
      await file.writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('נשמר ב-${file.path}'),
            backgroundColor: const Color(0xFF4ADE80),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: const Color(0xFFE2E8F0),
        title: const Text('QR קוד מלון',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _hotelName ?? widget.hotelName,
                style: const TextStyle(
                  color: Color(0xFFC9A84C),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'סרקו את הקוד לכניסה לאפליקציית האורחים',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              if (_baseUrlLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: CircularProgressIndicator(color: Color(0xFFC9A84C)),
                )
              else
                RepaintBoundary(
                  key: _qrKey,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: QrImageView(
                      data: _pwaUrl,
                      version: QrVersions.auto,
                      size: 240,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                _pwaUrl,
                style: const TextStyle(
                    color: Color(0xFF64748B), fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _saving ? null : _share,
                    icon: const Icon(Icons.share),
                    label: const Text('שתף'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFC9A84C),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.download),
                    label: const Text('שמור'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE2E8F0),
                      side: const BorderSide(color: Color(0xFF1E3A5F)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
              if (_saving) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(
                    color: Color(0xFFC9A84C)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
