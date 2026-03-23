// lib/features/tickets/data/photo_upload_service.dart
// Stub — full implementation in Task 6
import 'package:image_picker/image_picker.dart';

class PhotoUploadService {
  final bool isOnline;
  PhotoUploadService({required this.isOnline});

  Future<XFile?> pickPhoto() async => null;

  Future<void> uploadPhoto({
    required String ticketId,
    required String hotelId,
    required String uploadedBy,
    required XFile photo,
  }) async {
    throw UnimplementedError('Photo upload implemented in Task 6');
  }
}
