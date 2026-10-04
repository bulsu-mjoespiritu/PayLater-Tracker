// Basic smoke test: confirms the app builds and shows its Home screen
// without throwing, and that the app bar carries the right title.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spaylater_bill_manager/main.dart';

void main() {
  testWidgets('App launches and shows the Home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PayLaterTrackerApp());

    // First frame shows the loading spinner while storage is read.
    await tester.pump();
    // Let the async storage read complete.
    await tester.pumpAndSettle();

    expect(find.text('PayLater Tracker'), findsOneWidget);
  });
}
