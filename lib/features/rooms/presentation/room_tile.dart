import 'package:flutter/material.dart';
import '../domain/room_model.dart';

class RoomTile extends StatelessWidget {
  final Room room;
  final VoidCallback onTap;

  const RoomTile({super.key, required this.room, required this.onTap});

  Color get _color => switch (room.status) {
    'available' => Colors.green,
    'on_hold'   => Colors.orange,
    'closed'    => Colors.red,
    _           => Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _color.withOpacity(0.15),
          border: Border.all(color: _color, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(room.roomNumber, style: TextStyle(
              fontWeight: FontWeight.bold, color: _color, fontSize: 16)),
            if (room.roomType != null)
              Text(room.roomType!, style: const TextStyle(fontSize: 10)),
            Icon(_statusIcon, color: _color, size: 16),
          ],
        ),
      ),
    );
  }

  IconData get _statusIcon => switch (room.status) {
    'available' => Icons.check_circle_outline,
    'on_hold'   => Icons.pause_circle_outline,
    'closed'    => Icons.lock_outline,
    _           => Icons.help_outline,
  };
}
