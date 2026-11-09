import 'package:flutter/material.dart';

/// Невелика кольорова мітка-«пігулка»: статус завдання, заявки,
/// реєстрації на захід або категорія.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  /// Світлий фон для міток поверх обкладинки заходу.
  final bool onImage;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.onImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: onImage
            ? Colors.white.withValues(alpha: 0.92)
            : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: onImage ? Colors.black87 : color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
