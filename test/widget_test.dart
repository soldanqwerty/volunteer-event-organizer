import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:volunteer_event_organizer/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const VolunteerHubApp());

    // Just verify the MaterialApp renders.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
