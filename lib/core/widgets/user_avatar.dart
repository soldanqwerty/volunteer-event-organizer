import 'package:flutter/material.dart';

/// Кругла аватарка користувача. Показує фото за посиланням,
/// а якщо його немає або воно не завантажилось — ініціали.
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String initials;
  final double radius;

  const UserAvatar({
    super.key,
    required this.photoUrl,
    required this.initials,
    this.radius = 20,
  });

  /// «Ігор Катеринюк» → «ІК».
  static String initialsFrom(String? displayName) {
    final parts = (displayName ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = radius * 2;

    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primary,
      child: Text(
        initials,
        style: TextStyle(
          color: colorScheme.onPrimary,
          fontSize: radius * 0.6,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (photoUrl == null || photoUrl!.isEmpty) return fallback;

    return ClipOval(
      child: Image.network(
        photoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // На вебі: якщо сайт не дозволяє читати зображення (CORS),
        // показати його звичайним HTML-тегом <img>.
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: size,
            height: size,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}
