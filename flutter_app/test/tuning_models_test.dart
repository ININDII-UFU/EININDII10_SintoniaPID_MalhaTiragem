import 'package:flutter_test/flutter_test.dart';
import 'package:pid_zn_tuner/domain/point_import.dart';
import 'package:pid_zn_tuner/domain/tuning_models.dart';

void main() {
  test('calcula Ziegler-Nichols por reação ao degrau', () {
    const strategy = ReactionCurveTuningStrategy();
    final results = strategy.tune(
      const FopdtParameters(gain: 2, deadTime: 1, timeConstant: 5),
    );
    final pid = results.singleWhere((r) => r.kind == ControllerKind.pid);

    expect(pid.gains.kp, closeTo(3.0, 1e-9));
    expect(pid.gains.ki, closeTo(1.5, 1e-9));
    expect(pid.gains.kd, closeTo(1.5, 1e-9));
  });

  test('calcula Ziegler-Nichols por ganho último', () {
    const strategy = UltimateGainTuningStrategy();
    final results = strategy.tune(const UltimateParameters(ku: 4, pu: 6));
    final pi = results.singleWhere((r) => r.kind == ControllerKind.pi);

    expect(pi.gains.kp, closeTo(1.8, 1e-9));
    expect(pi.gains.ti, closeTo(5.0, 1e-9));
    expect(pi.gains.ki, closeTo(0.36, 1e-9));
  });

  test('parser aceita CSV simples', () {
    const parser = CsvPointParser();
    final points = parser.parse('tempo,saida\n0,0\n1;0.2\n2 0.5');

    expect(points.length, 3);
    expect(points.last.t, 2);
    expect(points.last.y, 0.5);
  });
}
