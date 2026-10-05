import 'package:flutter/material.dart';

/// Home screen — shows a hardcoded user name and basic quick actions,
/// per the assignment's "Example #2" (static placeholder data instead
/// of a real backend call).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Hardcoded user data, as allowed by the assignment (no backend yet).
  static const String _userName = 'Ігор';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Головна')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Вітаємо, $_userName',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Text(
              'Найближчі заходи',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('(поки що немає даних — буде додано пізніше)'),
          ],
        ),
      ),
    );
  }
}
