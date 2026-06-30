import 'package:flutter/foundation.dart';

import '../domain/point_import.dart';
import '../domain/signal_point.dart';
import '../domain/simulation_models.dart';
import '../domain/tuning_models.dart';

enum WorkspaceSection {
  reaction('Degrau', 'Malha aberta'),
  ultimate('Oscilação', 'Malha fechada'),
  simulation('Simulação', 'Curvas e pontos');

  const WorkspaceSection(this.label, this.subtitle);
  final String label;
  final String subtitle;
}

class TuningSession extends ChangeNotifier {
  TuningSession({
    this.reactionStrategy = const ReactionCurveTuningStrategy(),
    this.ultimateStrategy = const UltimateGainTuningStrategy(),
    this.simulator = const EulerFopdtPidSimulator(),
    this.pointParser = const CsvPointParser(),
    this.identifier = const TangentFopdtIdentifier(),
  }) {
    _recalculate();
  }

  final ReactionCurveTuningStrategy reactionStrategy;
  final UltimateGainTuningStrategy ultimateStrategy;
  final ClosedLoopSimulator simulator;
  final PointParser pointParser;
  final FopdtIdentifier identifier;

  WorkspaceSection section = WorkspaceSection.reaction;
  TuningMethod method = TuningMethod.reactionCurve;
  ControllerKind controllerKind = ControllerKind.pid;

  FopdtParameters fopdt = const FopdtParameters(
    gain: 2,
    deadTime: 1,
    timeConstant: 5,
  );
  UltimateParameters ultimate = const UltimateParameters(ku: 4, pu: 6);
  SimulationSettings settings = const SimulationSettings(
    setpoint: 1,
    stepAmplitude: 1,
    duration: 35,
    dt: 0.05,
    gainScale: 1,
    useSaturation: false,
    minOutput: 0,
    maxOutput: 100,
    derivativeOnError: true,
  );

  List<TuningResult> results = const [];
  SimulationResult? simulation;
  List<SignalPoint> importedPoints = const [];
  String importMessage = 'Cole dados no formato tempo,saida para comparar.';

  TuningResult? get selectedResult {
    for (final result in results) {
      if (result.kind == controllerKind) return result;
    }
    return results.isEmpty ? null : results.last;
  }

  void selectSection(WorkspaceSection value) {
    section = value;
    notifyListeners();
  }

  void setMethod(TuningMethod value) {
    method = value;
    _recalculate();
  }

  void setControllerKind(ControllerKind value) {
    controllerKind = value;
    _recalculate();
  }

  void updateFopdt({double? gain, double? deadTime, double? timeConstant}) {
    fopdt = fopdt.copyWith(
      gain: gain,
      deadTime: deadTime,
      timeConstant: timeConstant,
    );
    method = TuningMethod.reactionCurve;
    _recalculate();
  }

  void updateUltimate({double? ku, double? pu}) {
    ultimate = ultimate.copyWith(ku: ku, pu: pu);
    method = TuningMethod.ultimateGain;
    _recalculate();
  }

  void updateSettings({
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
    settings = settings.copyWith(
      setpoint: setpoint,
      stepAmplitude: stepAmplitude,
      duration: duration,
      dt: dt,
      gainScale: gainScale,
      useSaturation: useSaturation,
      minOutput: minOutput,
      maxOutput: maxOutput,
      derivativeOnError: derivativeOnError,
    );
    _recalculate();
  }

  void loadPoints(String raw) {
    final points = pointParser.parse(raw);
    importedPoints = points;
    importMessage = points.isEmpty
        ? 'Nenhum ponto numérico encontrado.'
        : '${points.length} pontos carregados.';
    notifyListeners();
  }

  void identifyFromImportedPoints() {
    final identified = identifier.identify(
      importedPoints,
      settings.stepAmplitude,
    );
    if (identified == null) {
      importMessage =
          'Não foi possível estimar K, L e T. Confira se há resposta ao degrau e pontos suficientes.';
      notifyListeners();
      return;
    }
    fopdt = identified;
    method = TuningMethod.reactionCurve;
    importMessage =
        'Modelo identificado por tangente: K=${_fmt(identified.gain)}, L=${_fmt(identified.deadTime)} s, T=${_fmt(identified.timeConstant)} s.';
    _recalculate();
  }

  void _recalculate() {
    results = method == TuningMethod.reactionCurve
        ? reactionStrategy.tune(fopdt)
        : ultimateStrategy.tune(ultimate);
    final selected = selectedResult;
    simulation = selected == null
        ? null
        : simulator.simulate(
            process: fopdt,
            gains: selected.gains,
            settings: settings,
          );
    notifyListeners();
  }

  String _fmt(double value) => value.toStringAsPrecision(4);
}
