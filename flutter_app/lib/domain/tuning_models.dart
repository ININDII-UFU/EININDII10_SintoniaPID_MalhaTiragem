enum ControllerKind {
  p('P'),
  pi('PI'),
  pid('PID');

  const ControllerKind(this.label);
  final String label;
}

enum TuningMethod {
  reactionCurve('Reação ao degrau', 'K, L, T'),
  ultimateGain('Ganho último', 'Ku, Pu');

  const TuningMethod(this.label, this.shortLabel);
  final String label;
  final String shortLabel;
}

class FopdtParameters {
  const FopdtParameters({
    required this.gain,
    required this.deadTime,
    required this.timeConstant,
  });

  final double gain;
  final double deadTime;
  final double timeConstant;

  bool get isValid => gain != 0 && deadTime > 0 && timeConstant > 0;
  double get delayRatio => deadTime / timeConstant;

  FopdtParameters copyWith({
    double? gain,
    double? deadTime,
    double? timeConstant,
  }) {
    return FopdtParameters(
      gain: gain ?? this.gain,
      deadTime: deadTime ?? this.deadTime,
      timeConstant: timeConstant ?? this.timeConstant,
    );
  }
}

class UltimateParameters {
  const UltimateParameters({required this.ku, required this.pu});

  final double ku;
  final double pu;

  bool get isValid => ku > 0 && pu > 0;

  UltimateParameters copyWith({double? ku, double? pu}) {
    return UltimateParameters(ku: ku ?? this.ku, pu: pu ?? this.pu);
  }
}

class PidGains {
  const PidGains({
    required this.kp,
    required this.ki,
    required this.kd,
    this.ti,
    this.td,
  });

  final double kp;
  final double ki;
  final double kd;
  final double? ti;
  final double? td;

  PidGains scaled(double factor) => PidGains(
    kp: kp * factor,
    ki: ki * factor,
    kd: kd * factor,
    ti: ti,
    td: td,
  );
}

class TuningResult {
  const TuningResult({
    required this.kind,
    required this.method,
    required this.gains,
  });

  final ControllerKind kind;
  final TuningMethod method;
  final PidGains gains;
}

abstract class TuningStrategy<T> {
  TuningMethod get method;
  List<TuningResult> tune(T parameters);
}

class ReactionCurveTuningStrategy implements TuningStrategy<FopdtParameters> {
  const ReactionCurveTuningStrategy();

  @override
  TuningMethod get method => TuningMethod.reactionCurve;

  @override
  List<TuningResult> tune(FopdtParameters p) {
    if (!p.isValid) return const [];
    final base = p.timeConstant / (p.gain * p.deadTime);
    return [
      TuningResult(
        kind: ControllerKind.p,
        method: method,
        gains: PidGains(kp: base, ki: 0, kd: 0),
      ),
      TuningResult(
        kind: ControllerKind.pi,
        method: method,
        gains: _withTimes(0.9 * base, 3 * p.deadTime, null),
      ),
      TuningResult(
        kind: ControllerKind.pid,
        method: method,
        gains: _withTimes(1.2 * base, 2 * p.deadTime, 0.5 * p.deadTime),
      ),
    ];
  }
}

class UltimateGainTuningStrategy implements TuningStrategy<UltimateParameters> {
  const UltimateGainTuningStrategy();

  @override
  TuningMethod get method => TuningMethod.ultimateGain;

  @override
  List<TuningResult> tune(UltimateParameters p) {
    if (!p.isValid) return const [];
    return [
      TuningResult(
        kind: ControllerKind.p,
        method: method,
        gains: PidGains(kp: 0.5 * p.ku, ki: 0, kd: 0),
      ),
      TuningResult(
        kind: ControllerKind.pi,
        method: method,
        gains: _withTimes(0.45 * p.ku, p.pu / 1.2, null),
      ),
      TuningResult(
        kind: ControllerKind.pid,
        method: method,
        gains: _withTimes(0.6 * p.ku, 0.5 * p.pu, 0.125 * p.pu),
      ),
    ];
  }
}

PidGains _withTimes(double kc, double? ti, double? td) {
  return PidGains(
    kp: kc,
    ki: ti == null ? 0 : kc / ti,
    kd: td == null ? 0 : kc * td,
    ti: ti,
    td: td,
  );
}
