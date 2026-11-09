import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/profile_model.dart';
import 'user_avatar.dart';

/// Верхня панель сторінки (макети S-04 – S-15): заголовок і підзаголовок
/// ліворуч, необов'язковий вміст по центру (пошук), справа — дзвіночок
/// і аватарка поточного користувача.
class AppTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? center;
  final bool showUserName;

  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.center,
    this.showUserName = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profile = context.watch<ProfileModel>();

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            IconButton.outlined(
              tooltip: 'Назад',
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left),
            ),
            const SizedBox(width: 12),
          ],
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
            ],
          ),
          const SizedBox(width: 32),
          Expanded(
            child: center == null
                ? const SizedBox.shrink()
                : Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: center,
                    ),
                  ),
          ),
          Badge(
            smallSize: 8,
            child: IconButton.outlined(
              tooltip: 'Сповіщення',
              onPressed: () {},
              icon: const Icon(Icons.notifications_outlined, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          UserAvatar(
            photoUrl: profile.photoUrl,
            initials: UserAvatar.initialsFrom(profile.displayName),
            radius: 18,
          ),
          if (showUserName) ...[
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName.isEmpty
                      ? 'Без імені'
                      : profile.displayName,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Волонтер',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
