// hotel_guest_app/lib/presentation/landing_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_guest_app/core/session.dart';
import 'package:hotel_guest_app/data/guest_repository.dart';
import 'package:hotel_guest_app/l10n/app_localizations.dart';
import 'package:hotel_guest_app/providers/providers.dart';

class LandingScreen extends ConsumerStatefulWidget {
  /// hotel_id from URL query param ?hotel=<id>
  final String? hotelId;
  final String? roomNumber;
  const LandingScreen({super.key, this.hotelId, this.roomNumber});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  final _nameCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  bool _loading = false;
  HotelBranding? _hotel;

  @override
  void initState() {
    super.initState();
    if (widget.roomNumber != null && widget.roomNumber!.isNotEmpty) {
      _roomCtrl.text = widget.roomNumber!;
    }
    _loadHotel();
  }

  Future<void> _loadHotel() async {
    final id = widget.hotelId;
    if (id == null || id.isEmpty) return;
    final hotel = await GuestRepository().getHotelBranding(id);
    if (mounted) setState(() => _hotel = hotel);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  Future<void> _enter() async {
    final loc = AppLocalizations.of(context)!;
    final name = _nameCtrl.text.trim();
    final room = _roomCtrl.text.trim();
    final hotel = widget.hotelId;

    if (name.isEmpty || room.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.landingErrorMissingFields)),
      );
      return;
    }
    if (hotel == null || hotel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.landingErrorMissingHotel),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await GuestSession.save(
          guestName: name, roomNumber: room, hotelId: hotel);
      ref.invalidate(sessionProvider);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(loc.errorGeneric(e.toString())),
              backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _HotelHeader(hotel: _hotel),
                  const SizedBox(height: 12),
                  Text(
                    _hotel?.name == null
                        ? loc.landingWelcome
                        : loc.landingWelcomeWithName(_hotel!.name),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFC9A84C),
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.landingSubtitle,
                    style: const TextStyle(
                        color: Color(0xFF94A3B8), fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  _buildField(_nameCtrl, loc.landingNameHint, Icons.person),
                  const SizedBox(height: 16),
                  _buildField(
                      _roomCtrl, loc.landingRoomHint, Icons.door_front_door,
                      type: TextInputType.number),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _enter,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFC9A84C),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black))
                          : Text(loc.landingEnter),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.landingAddToHome,
                    style: const TextStyle(
                        color: Color(0xFF64748B), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
      TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? type}) =>
    TextField(
        controller: ctrl,
        keyboardType: type,
        style: const TextStyle(color: Color(0xFFE2E8F0)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF64748B)),
          prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
          filled: true,
          fillColor: const Color(0xFF0F1F3D),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF1E3A5F)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF1E3A5F)),
          ),
        ),
      );
}

class _HotelHeader extends StatelessWidget {
  final HotelBranding? hotel;
  const _HotelHeader({this.hotel});

  @override
  Widget build(BuildContext context) {
    final logo = hotel?.logoUrl;
    if (logo != null && logo.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          logo,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const _FallbackHotelIcon(),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return const SizedBox(
              width: 96,
              height: 96,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFC9A84C),
                ),
              ),
            );
          },
        ),
      );
    }
    return const _FallbackHotelIcon();
  }
}

class _FallbackHotelIcon extends StatelessWidget {
  const _FallbackHotelIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1F3D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC9A84C), width: 2),
      ),
      child: const Icon(
        Icons.hotel,
        color: Color(0xFFC9A84C),
        size: 48,
      ),
    );
  }
}
