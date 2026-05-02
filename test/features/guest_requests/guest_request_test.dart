// test/features/guest_requests/guest_request_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/guest_requests/domain/guest_request_model.dart';

void main() {
  group('GuestRequest.fromJson', () {
    test('parses all fields', () {
      final json = {
        'id': 'req-1',
        'hotel_id': 'h-1',
        'room_number': '205',
        'guest_name': 'דנה כהן',
        'category': 'housekeeping',
        'description': 'מגבות נוספות',
        'status': 'open',
        'assigned_dept': 'housekeeping',
        'assigned_to': null,
        'created_by': 'guest',
        'created_at': '2026-05-01T10:00:00.000Z',
        'updated_at': '2026-05-01T10:00:00.000Z',
      };
      final req = GuestRequest.fromJson(json);
      expect(req.id, 'req-1');
      expect(req.roomNumber, '205');
      expect(req.guestName, 'דנה כהן');
      expect(req.category, 'housekeeping');
      expect(req.description, 'מגבות נוספות');
      expect(req.status, 'open');
      expect(req.assignedDept, 'housekeeping');
      expect(req.assignedTo, isNull);
      expect(req.createdBy, 'guest');
    });

    test('defaults nullable fields to null', () {
      final json = {
        'id': 'req-2',
        'hotel_id': 'h-1',
        'room_number': '101',
        'guest_name': 'אורח',
        'category': 'reception',
        'status': 'open',
        'created_by': 'reception',
        'created_at': '2026-05-01T10:00:00.000Z',
        'updated_at': '2026-05-01T10:00:00.000Z',
      };
      final req = GuestRequest.fromJson(json);
      expect(req.description, isNull);
      expect(req.assignedDept, isNull);
      expect(req.assignedTo, isNull);
    });
  });

  group('GuestFeedback.fromJson', () {
    test('parses all fields', () {
      final json = {
        'id': 'fb-1',
        'hotel_id': 'h-1',
        'room_number': '205',
        'guest_name': 'דנה כהן',
        'rating': 5,
        'comment': 'שירות מצוין!',
        'created_at': '2026-05-01T12:00:00.000Z',
      };
      final fb = GuestFeedback.fromJson(json);
      expect(fb.rating, 5);
      expect(fb.comment, 'שירות מצוין!');
    });

    test('parses null comment', () {
      final json = {
        'id': 'fb-2',
        'hotel_id': 'h-1',
        'room_number': '101',
        'guest_name': 'אורח',
        'rating': 4,
        'comment': null,
        'created_at': '2026-05-01T12:00:00.000Z',
      };
      final fb = GuestFeedback.fromJson(json);
      expect(fb.comment, isNull);
    });
  });
}
