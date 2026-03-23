// lib/features/rooms/presentation/room_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import '../data/room_repository.dart';

class RoomManagementScreen extends ConsumerStatefulWidget {
  const RoomManagementScreen({super.key});
  @override ConsumerState<RoomManagementScreen> createState() => _State();
}

class _State extends ConsumerState<RoomManagementScreen> {
  final _numberCtrl = TextEditingController();
  final _floorCtrl  = TextEditingController();
  final _typeCtrl   = TextEditingController();
  String? _importResult;
  bool _loading = false;

  Future<void> _addRoom() async {
    final user = ref.read(currentUserProvider)!;
    final hotelId = user.appMetadata['hotel_id'] as String;
    setState(() => _loading = true);
    try {
      await RoomRepository().addRoom(
        hotelId: hotelId,
        roomNumber: _numberCtrl.text.trim(),
        floor: int.tryParse(_floorCtrl.text),
        roomType: _typeCtrl.text.trim().isEmpty ? null : _typeCtrl.text.trim(),
      );
      _numberCtrl.clear(); _floorCtrl.clear(); _typeCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room added')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['csv'],
    );
    if (result == null) return;

    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    final content = String.fromCharCodes(bytes);
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();

    // Parse header
    final headers = lines.first.split(',').map((h) => h.trim().toLowerCase()).toList();
    final rows = lines.skip(1).map((line) {
      final vals = line.split(',');
      return Map<String, dynamic>.fromIterables(headers, vals.map((v) => v.trim()));
    }).toList();

    final user = ref.read(currentUserProvider)!;
    final hotelId = user.appMetadata['hotel_id'] as String;

    setState(() => _loading = true);
    try {
      final res = await RoomRepository().importFromCsv(hotelId: hotelId, rows: rows);
      setState(() => _importResult =
        'Imported: ${res['imported']}  Skipped (duplicates): ${res['skipped']}\n'
        '${(res['errors'] as List).isNotEmpty ? "Errors:\n${(res['errors'] as List).join('\n')}" : ""}');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Room Management')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Add Room', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(controller: _numberCtrl, decoration: const InputDecoration(labelText: 'Room Number *')),
          const SizedBox(height: 8),
          TextField(controller: _floorCtrl, decoration: const InputDecoration(labelText: 'Floor'), keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          TextField(controller: _typeCtrl, decoration: const InputDecoration(labelText: 'Room Type')),
          const SizedBox(height: 16),
          FilledButton(onPressed: _loading ? null : _addRoom, child: const Text('Add Room')),
          const Divider(height: 40),
          Text('Import from CSV', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Format: room_number, floor, room_type (max 500 rows)\nDuplicates are skipped automatically.',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loading ? null : _importCsv,
            icon: const Icon(Icons.upload_file),
            label: const Text('Choose CSV File'),
          ),
          if (_importResult != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_importResult!),
            ),
          ],
        ]),
      ),
    );
  }
}
