import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:pid_zn_tuner/ui/pid_tuner_app.dart';

void main() {
  testWidgets('abre a aplicação de sintonia PID', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(const PidTunerApp());
    expect(find.text('Sintonia PID Ziegler-Nichols'), findsWidgets);
    expect(find.text('VALORES DE SINTONIA'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
