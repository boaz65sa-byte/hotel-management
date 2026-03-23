// lib/features/tickets/data/photo_upload_service.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'package:hotel_app/core/database/sync_queue.dart';

const _maxBytes = 10 * 1024 * 1024; // 10MB

class PhotoUploadService {
  final bool isOnline;
  PhotoUploadService({required this.isOnline});

  Future<XFile?> pickPhoto() async {
    return ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
  }

  Future<void> uploadPhoto({
    required String ticketId,
    required String hotelId,
    required String uploadedBy,
    required XFile photo,
  }) async {
    final bytes = await photo.readAsBytes();
    if (bytes.length > _maxBytes) {
      throw Exception('Photo exceeds 10MB limit');
    }

    final ext = p.extension(photo.path).replaceFirst('.', '');
    final filename = '${const Uuid().v4()}.$ext';
    final storagePath = '$hotelId/$ticketId/$filename';

    if (isOnline) {
      await supabase.storage.from('ticket-photos').uploadBinary(storagePath, bytes);
      // Private bucket — create signed URL (7-day expiry) for display
      final signedUrl = await supabase.storage
        .from('ticket-photos')
        .createSignedUrl(storagePath, 60 * 60 * 24 * 7);
      await supabase.from('ticket_photos').insert({
        'hotel_id': hotelId,
        'ticket_id': ticketId,
        'uploaded_by': uploadedBy,
        'photo_url': signedUrl,
        'file_size_bytes': bytes.length,
      });
    } else {
      // Save bytes to temp file and queue for later upload
      final tempPath = '${Directory.systemTemp.path}/$filename';
      await File(tempPath).writeAsBytes(bytes);
      await SyncQueue.enqueue('upload_photo', {
        'ticket_id': ticketId,
        'hotel_id': hotelId,
        'uploaded_by': uploadedBy,
        'local_path': tempPath,
        'storage_path': storagePath,
        'file_size_bytes': bytes.length,
      });
    }
  }
}
