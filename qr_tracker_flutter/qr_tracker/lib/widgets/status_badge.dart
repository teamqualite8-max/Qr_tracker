// lib/widgets/status_badge.dart

import 'package:flutter/material.dart';
import '../models/part.dart';
import '../theme.dart';

class StatusBadge extends StatelessWidget {
  final PartStatus status;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColorFromEnum(status);
    final icon = switch (status) {
      PartStatus.post2Done => Icons.check_circle,
      PartStatus.post1Done => Icons.radio_button_checked,
      PartStatus.notProcessed => Icons.radio_button_unchecked,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2, color: color),
          const SizedBox(width: 5),
          Text(
            status.displayLabel,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
