// hotel_guest_app/lib/presentation/new_request_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_guest_app/l10n/app_localizations.dart';
import 'package:hotel_guest_app/providers/providers.dart';

const _kOtherTileKey = 'other';

class _ServiceTile {
  final String key;
  final String icon;
  final String Function(AppLocalizations) label;
  const _ServiceTile(this.key, this.icon, this.label);
}

const Map<String, List<_ServiceTile>> _serviceTilesByCategory = {
  'housekeeping': [
    _ServiceTile('extra_towels', '🧺', _lExtraTowels),
    _ServiceTile('extra_pillows', '🛏️', _lExtraPillows),
    _ServiceTile('clean_room', '🧹', _lCleanRoom),
    _ServiceTile('do_not_disturb', '🚫', _lDoNotDisturb),
    _ServiceTile('toiletries', '🧴', _lToiletries),
    _ServiceTile('ice_water', '🧊', _lIceWater),
  ],
  'maintenance': [
    _ServiceTile('ac_issue', '❄️', _lAcIssue),
    _ServiceTile('tv_issue', '📺', _lTvIssue),
    _ServiceTile('wifi_issue', '📶', _lWifiIssue),
    _ServiceTile('plumbing_issue', '🚿', _lPlumbingIssue),
    _ServiceTile('light_bulb', '💡', _lLightBulb),
    _ServiceTile('power_outlet', '🔌', _lPowerOutlet),
  ],
  'reception': [
    _ServiceTile('late_checkout', '🕐', _lLateCheckout),
    _ServiceTile('extra_key', '🔑', _lExtraKey),
    _ServiceTile('taxi_request', '🚕', _lTaxiRequest),
    _ServiceTile('luggage_help', '🧳', _lLuggageHelp),
    _ServiceTile('wake_up_call', '⏰', _lWakeUpCall),
    _ServiceTile('invoice_request', '🧾', _lInvoiceRequest),
  ],
};

String _lExtraTowels(AppLocalizations l) => l.serviceExtraTowels;
String _lExtraPillows(AppLocalizations l) => l.serviceExtraPillows;
String _lCleanRoom(AppLocalizations l) => l.serviceCleanRoom;
String _lDoNotDisturb(AppLocalizations l) => l.serviceDoNotDisturb;
String _lToiletries(AppLocalizations l) => l.serviceToiletries;
String _lIceWater(AppLocalizations l) => l.serviceIceWater;
String _lAcIssue(AppLocalizations l) => l.serviceAcIssue;
String _lTvIssue(AppLocalizations l) => l.serviceTvIssue;
String _lWifiIssue(AppLocalizations l) => l.serviceWifiIssue;
String _lPlumbingIssue(AppLocalizations l) => l.servicePlumbingIssue;
String _lLightBulb(AppLocalizations l) => l.serviceLightBulb;
String _lPowerOutlet(AppLocalizations l) => l.servicePowerOutlet;
String _lLateCheckout(AppLocalizations l) => l.serviceLateCheckout;
String _lExtraKey(AppLocalizations l) => l.serviceExtraKey;
String _lTaxiRequest(AppLocalizations l) => l.serviceTaxiRequest;
String _lLuggageHelp(AppLocalizations l) => l.serviceLuggageHelp;
String _lWakeUpCall(AppLocalizations l) => l.serviceWakeUpCall;
String _lInvoiceRequest(AppLocalizations l) => l.serviceInvoiceRequest;

class NewRequestScreen extends ConsumerStatefulWidget {
  const NewRequestScreen({super.key});
  @override
  ConsumerState<NewRequestScreen> createState() =>
      _NewRequestScreenState();
}

class _NewRequestScreenState extends ConsumerState<NewRequestScreen> {
  final _descCtrl = TextEditingController();
  String _category = 'housekeeping';
  String? _selectedTileKey;
  bool _loading = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  List<(String, String)> _categories(AppLocalizations loc) => [
    ('housekeeping', '🛏️ ${loc.categoryHousekeeping}'),
    ('maintenance',  '🔧 ${loc.categoryMaintenance}'),
    ('reception',    '🛎️ ${loc.categoryReception}'),
  ];

  void _selectCategory(String category) {
    setState(() {
      _category = category;
      _selectedTileKey = null;
      _descCtrl.clear();
    });
  }

  void _selectTile(_ServiceTile tile, AppLocalizations loc) {
    setState(() {
      _selectedTileKey = tile.key;
      _descCtrl.text = tile.label(loc);
    });
  }

  void _selectOther() {
    setState(() {
      _selectedTileKey = _kOtherTileKey;
      _descCtrl.clear();
    });
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _loading = true);
    try {
      final session = await ref.read(sessionProvider.future);
      if (session == null) throw Exception(loc.errorNoSession);
      await ref.read(guestRepositoryProvider).submitRequest(
            hotelId:     session.hotelId,
            roomNumber:  session.roomNumber,
            guestName:   session.guestName,
            category:    _category,
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
          );
      if (mounted) context.pop();
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
    final categories = _categories(loc);
    final disabledTiles =
        ref.watch(disabledRequestTilesProvider).valueOrNull ?? const {};
    final tiles = (_serviceTilesByCategory[_category] ?? const [])
        .where((tile) => !disabledTiles.contains('$_category:${tile.key}'))
        .toList();
    final isOtherSelected = _selectedTileKey == _kOtherTileKey;
    final isTileSelected =
        _selectedTileKey != null && _selectedTileKey != _kOtherTileKey;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: const Color(0xFFE2E8F0),
        title: Text(loc.newRequestTitle,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.newRequestCategoryLabel,
                  style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: categories
                    .map((c) => GestureDetector(
                          onTap: () => _selectCategory(c.$1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: _category == c.$1
                                  ? const Color(0xFFC9A84C)
                                  : const Color(0xFF0F1F3D),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _category == c.$1
                                    ? const Color(0xFFC9A84C)
                                    : const Color(0xFF1E3A5F),
                              ),
                            ),
                            child: Text(
                              c.$2,
                              style: TextStyle(
                                color: _category == c.$1
                                    ? Colors.black
                                    : const Color(0xFFE2E8F0),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              Text(loc.newRequestQuickSelectLabel,
                  style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.95,
                children: [
                  ...tiles.map((tile) => _ServiceCube(
                        icon: tile.icon,
                        label: tile.label(loc),
                        selected: _selectedTileKey == tile.key,
                        onTap: () => _selectTile(tile, loc),
                      )),
                  _ServiceCube(
                    icon: '✏️',
                    label: loc.newRequestSomethingElse,
                    selected: isOtherSelected,
                    dashed: true,
                    onTap: _selectOther,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                  isTileSelected
                      ? loc.newRequestNoteLabel
                      : loc.newRequestDetailsLabel,
                  style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _descCtrl,
                maxLines: isTileSelected ? 2 : 4,
                style: const TextStyle(color: Color(0xFFE2E8F0)),
                decoration: InputDecoration(
                  hintText: isTileSelected
                      ? loc.newRequestNoteHint
                      : loc.newRequestDetailsHint,
                  hintStyle: const TextStyle(color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFF0F1F3D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFF1E3A5F)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFF1E3A5F)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
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
                      : Text(loc.newRequestSubmit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCube extends StatelessWidget {
  final String icon;
  final String label;
  final bool selected;
  final bool dashed;
  final VoidCallback onTap;
  const _ServiceCube({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFC9A84C)
              : const Color(0xFF0F1F3D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFFC9A84C)
                : (dashed
                    ? const Color(0xFF64748B)
                    : const Color(0xFF1E3A5F)),
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: selected
                        ? Colors.black
                        : const Color(0xFFE2E8F0),
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
