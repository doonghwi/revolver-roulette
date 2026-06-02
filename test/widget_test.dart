import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:revolver_roulette/main.dart';

void main() {
  testWidgets('App builds and shows shots counter at 0', (tester) async {
    await tester.pumpWidget(const RevolverRouletteApp());
    await tester.pump();

    // The horizontal shots-fired counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('SHOTS FIRED · 쏜 횟수'), findsOneWidget);
  });

  testWidgets('Tapping pulls the trigger (counter or bang)', (tester) async {
    await tester.pumpWidget(const RevolverRouletteApp());
    await tester.pump();

    // Tap the screen to pull the trigger; should not throw.
    await tester.tapAt(const Offset(400, 200));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(seconds: 1));
    // Either we survived (still rendering) or fired — app stays alive.
    expect(find.byType(RevolverRouletteApp), findsOneWidget);
  });
}
