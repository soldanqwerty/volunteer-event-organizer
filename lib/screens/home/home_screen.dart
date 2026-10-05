import 'package:flutter/material.dart';

import '../profile/profile_screen.dart';

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
      appBar: AppBar(
        title: const Text('Головна'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
