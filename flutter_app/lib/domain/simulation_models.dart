import 'signal_point.dart';
import 'tuning_models.dart';

class SimulationSettings {
  const SimulationSettings({
    required this.setpoint,
    required this.stepAmplitude,
    required this.duration,
    required this.dt,
    required this.gainScale,
    required this.useSaturation,
    required this.minOutput,
    required this.maxOutput,
    required this.derivativeOnError,
  });

  final double setpoint;
  final double stepAmplitude;
  final double duration;
  final double dt;
  final double gainScale;
  final bool useSaturation;
  final double minOutput;
  final double maxOutput;
  final bool derivativeOnError;

  bool get isValid => setpoint.isFinite && duration > 0 && dt > 0;

  SimulationSettings copyWith({
    double? setpoint,
    double? stepAmplitude,
    double? duration,
    double? dt,
    double? gainScale,
    bool? useSaturation,
    double? minOutput,
    double? maxOutput,
    bool? derivativeOnError,
  }) {
    return SimulationSettings(
      setpoint: setpoint ?? this.setpoint,
      stepAmplitude: stepAmplitude ?? this.stepAmplitude,
      duration: duration ?? this.duration,
      dt: dt ?? this.dt,
      gainScale: gainScale ?? this.gainScale,
      useSaturation: useSaturation ?? this.useSaturation,
      minOutput: minOutput ?? this.minOutput,
      maxOutput: maxOutput ?? this.maxOutput,
      derivativeOnError: derivativeOnError ?? this.derivativeOnError,
    );
  }
}

class SimulationResult {
  const SimulationResult({
    required this.time,
    required this.setpoint,
    required this.openLoop,
    required this.closedLoop,
    required this.manipulated,
    required this.metrics,
  });

  final List<double> time;
  final List<double> setpoint;
  final List<double> openLoop;
  final List<double> closedLoop;
  final List<double> manipulated;
  final ResponseMetrics metrics;

  List<SignalPoint> asPoints(List<double> values) {
    return [
      for (var i = 0; i < time.length && i < values.length; i++)
        SignalPoint(time[i], values[i]),
    ];
  }
}

class ResponseMetrics {
  const ResponseMetrics({
    required this.overshootPercent,
    required this.settlingTime,
    required this.steadyStateError,
    required this.iae,
  });

  final double overshootPercent;
  final double? settlingTime;
  final double steadyStateError;
  final double iae;
}

abstract class ClosedLoopSimulator {
  SimulationResult simulate({
    required FopdtParameters process,
    required PidGains gains,
    required SimulationSettings settings,
  });
}

class EulerFopdtPidSimulator implements ClosedLoopSimulator {
  const EulerFopdtPidSimulator();

  @override
  SimulationResult simulate({
    required FopdtParameters process,
    required PidGains gains,
    required SimulationSettings settings,
  }) {
    if (!process.isValid || !settings.isValid) {
      return const SimulationResult(
        time: [],
        setpoint: [],
        openLoop: [],
        closedLoop: [],
        manipulated: [],
        metrics: ResponseMetrics(
          overshootPercent: 0,
          settlingTime: null,
          steadyStateError: 0,
          iae: 0,
        ),
      );
    }

    final n = (settings.duration / settings.dt).ceil() + 1;
    final delaySteps = (process.deadTime / settings.dt).round().clamp(0, n);
    final time = List<double>.generate(n, (i) => i * settings.dt);
    final sp = List<double>.filled(n, settings.setpoint);
    final open = List<double>.filled(n, 0);
    final closed = List<double>.filled(n, 0);
    final u = List<double>.filled(n, 0);
    final scaled = gains.scaled(settings.gainScale);

    for (var k = 1; k < n; k++) {
      final delayedIndex = k - delaySteps;
      final input = delayedIndex >= 0 ? settings.stepAmplitude : 0.0;
      open[k] =
          open[k - 1] +
          settings.dt /
              process.timeConstant *
              (-open[k - 1] + process.gain * input);
    }

    var integral = 0.0;
    var previousError = settings.setpoint;
    var previousOutput = 0.0;

    for (var k = 1; k < n; k++) {
      final error = settings.setpoint - closed[k - 1];
      integral += error * settings.dt;
      final derivative = settings.derivativeOnError
          ? (error - previousError) / settings.dt
          : -(closed[k - 1] - previousOutput) / settings.dt;

      final unsaturated =
          scaled.kp * error + scaled.ki * integral + scaled.kd * derivative;
      var command = unsaturated;
      if (settings.useSaturation) {
        command = command.clamp(settings.minOutput, settings.maxOutput);
        if (command != unsaturated && scaled.ki != 0) {
          integral -= error * settings.dt;
        }
      }
      u[k] = command;

      final delayedIndex = k - delaySteps;
      final delayedInput = delayedIndex >= 0 ? u[delayedIndex] : 0.0;
      closed[k] =
          closed[k - 1] +
          settings.dt /
              process.timeConstant *
              (-closed[k - 1] + process.gain * delayedInput);

      previousError = error;
      previousOutput = closed[k - 1];
    }

    return SimulationResult(
      time: time,
      setpoint: sp,
      openLoop: open,
      closedLoop: closed,
      manipulated: u,
      metrics: _metrics(time, closed, settings.setpoint, settings.dt),
    );
  }

  ResponseMetrics _metrics(
    List<double> time,
    List<double> y,
    double setpoint,
    double dt,
  ) {
    if (time.isEmpty || y.isEmpty) {
      return const ResponseMetrics(
        overshootPercent: 0,
        settlingTime: null,
        steadyStateError: 0,
        iae: 0,
      );
    }
    final maxY = y.reduce((a, b) => a > b ? a : b);
    final overshoot = setpoint == 0
        ? 0.0
        : ((maxY - setpoint) / setpoint.abs() * 100).clamp(
            0.0,
            double.infinity,
          );
    final band = setpoint.abs() * 0.02 + 1e-9;
    double? settling;
    for (var i = 0; i < y.length; i++) {
      var settled = true;
      for (var k = i; k < y.length; k++) {
        if ((y[k] - setpoint).abs() > band) {
          settled = false;
          break;
        }
      }
      if (settled) {
        settling = time[i];
        break;
      }
    }
    var iae = 0.0;
    for (final value in y) {
      iae += (setpoint - value).abs() * dt;
    }
    return ResponseMetrics(
      overshootPercent: overshoot,
      settlingTime: settling,
      steadyStateError: setpoint - y.last,
      iae: iae,
    );
  }
}
