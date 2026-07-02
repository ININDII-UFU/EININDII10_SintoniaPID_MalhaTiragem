import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/modbus_models.dart';
import '../domain/point_import.dart';
import '../domain/signal_point.dart';
import '../domain/simulation_models.dart';
import '../domain/tuning_models.dart';
import '../infrastructure/config/app_config_store.dart';
import '../infrastructure/modbus/modbus_client.dart';

enum WorkspaceSection {
  operation('Operação', 'Simulado ou Modbus'),
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
    AppModbusClient? modbusClient,
    AppConfigStore? configStore,
  }) : modbusClient = modbusClient ?? createModbusClient(),
       configStore = configStore ?? createAppConfigStore() {
    modbusEndpoint = this.configStore.loadEndpoint(modbusEndpoint);
    modbusPoints = this.configStore.loadPointMap(modbusPoints);
    loopValues = LoopValues(
      sp: settings.setpoint,
      pv: 0,
      mv: 0,
      am: true,
      lr: true,
    );
    _recalculate();
  }

  final ReactionCurveTuningStrategy reactionStrategy;
  final UltimateGainTuningStrategy ultimateStrategy;
  final ClosedLoopSimulator simulator;
  final PointParser pointParser;
  final FopdtIdentifier identifier;
  final AppModbusClient modbusClient;
  final AppConfigStore configStore;

  WorkspaceSection section = WorkspaceSection.operation;
  TuningMethod method = TuningMethod.reactionCurve;
  ControllerKind controllerKind = ControllerKind.pid;
  ProcessSource processSource = ProcessSource.simulated;

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

  ModbusEndpoint modbusEndpoint = const ModbusEndpoint(
    host: '192.168.0.10',
    port: 502,
    unitId: 1,
    pollPeriodMs: 1000,
    bridgeUrl: 'ws://127.0.0.1:4000',
  );
  ModbusPointMap modbusPoints = ModbusPointMap.defaults();
  String connectionStatus = 'Sistema simulado selecionado.';
  bool liveRunning = false;
  bool modbusConnected = false;
  late LoopValues loopValues;
  double manualStep = 10;

  final List<double> liveTime = [];
  final List<double> liveSp = [];
  final List<double> livePv = [];
  final List<double> liveMv = [];

  List<TuningResult> results = const [];
  SimulationResult? simulation;
  List<SignalPoint> importedPoints = const [];
  String importMessage = 'Cole dados no formato tempo,saida para comparar.';

  Timer? _pollTimer;
  DateTime? _lastLiveTick;
  double _liveElapsed = 0;

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

  void setProcessSource(ProcessSource value) {
    processSource = value;
    connectionStatus = value == ProcessSource.simulated
        ? 'Sistema simulado selecionado.'
        : 'Modbus selecionado. Conecte quando o CLP estiver disponível.';
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

  void updateModbusEndpoint({
    String? host,
    int? port,
    int? unitId,
    int? pollPeriodMs,
    String? bridgeUrl,
  }) {
    modbusEndpoint = modbusEndpoint.copyWith(
      host: host,
      port: port,
      unitId: unitId,
      pollPeriodMs: pollPeriodMs,
      bridgeUrl: bridgeUrl,
    );
    configStore.saveEndpoint(modbusEndpoint);
    notifyListeners();
  }

  void updateModbusPoint(
    LoopVariable variable, {
    int? address,
    ModbusDataArea? area,
    ModbusValueFormat? format,
    double? scale,
    double? offset,
  }) {
    modbusPoints = modbusPoints.update(
      variable,
      (point) => point.copyWith(
        address: address,
        area: area,
        format: format,
        scale: scale,
        offset: offset,
      ),
    );
    configStore.savePointMap(modbusPoints);
    notifyListeners();
  }

  void setManualStep(double value) {
    manualStep = value;
    notifyListeners();
  }

  Future<void> connectModbus() async {
    processSource = ProcessSource.modbus;
    connectionStatus =
        'Conectando em ${modbusEndpoint.host}:${modbusEndpoint.port}...';
    notifyListeners();
    try {
      await modbusClient.connect(modbusEndpoint);
      modbusConnected = true;
      connectionStatus =
          'Conectado em ${modbusEndpoint.host}:${modbusEndpoint.port}.';
      await pollOnce();
    } catch (error) {
      modbusConnected = false;
      connectionStatus = 'Falha ao conectar: $error';
      notifyListeners();
    }
  }

  Future<void> disconnectModbus() async {
    stopLive();
    await modbusClient.disconnect();
    modbusConnected = false;
    connectionStatus = 'Desconectado.';
    notifyListeners();
  }

  void startLive() {
    liveRunning = true;
    _lastLiveTick = DateTime.now();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      Duration(milliseconds: modbusEndpoint.pollPeriodMs),
      (_) => pollOnce(),
    );
    pollOnce();
    notifyListeners();
  }

  void stopLive() {
    _pollTimer?.cancel();
    _pollTimer = null;
    liveRunning = false;
    notifyListeners();
  }

  void clearLiveHistory() {
    liveTime.clear();
    liveSp.clear();
    livePv.clear();
    liveMv.clear();
    _liveElapsed = 0;
    _lastLiveTick = DateTime.now();
    notifyListeners();
  }

  Future<void> pollOnce() async {
    if (processSource == ProcessSource.modbus) {
      await _pollModbusOnce();
    } else {
      _pollSimulatedOnce();
    }
  }

  Future<void> writeSp(double value) async {
    loopValues = loopValues.copyWith(sp: value);
    settings = settings.copyWith(setpoint: value);
    _recalculate();
    if (processSource == ProcessSource.modbus && modbusConnected) {
      await _writePoint(LoopVariable.sp, value);
    }
    notifyListeners();
  }

  Future<void> writeMv(double value) async {
    loopValues = loopValues.copyWith(mv: value.clamp(0.0, 100.0));
    if (processSource == ProcessSource.modbus && modbusConnected) {
      await _writePoint(LoopVariable.mv, loopValues.mv);
    }
    notifyListeners();
  }

  Future<void> nudgeMv(double delta) => writeMv(loopValues.mv + delta);

  Future<void> setAutoMode(bool automatic) async {
    loopValues = loopValues.copyWith(am: automatic);
    if (processSource == ProcessSource.modbus && modbusConnected) {
      await _writePoint(LoopVariable.am, automatic ? 1 : 0);
    }
    notifyListeners();
  }

  Future<void> setLocalMode(bool local) async {
    loopValues = loopValues.copyWith(lr: local);
    if (processSource == ProcessSource.modbus && modbusConnected) {
      await _writePoint(LoopVariable.lr, local ? 1 : 0);
    }
    notifyListeners();
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

  Future<void> _pollModbusOnce() async {
    if (!modbusConnected) {
      connectionStatus = 'Modbus selecionado, mas ainda desconectado.';
      notifyListeners();
      return;
    }
    try {
      final sp = await modbusClient.read(
        modbusEndpoint,
        modbusPoints[LoopVariable.sp],
      );
      final pv = await modbusClient.read(
        modbusEndpoint,
        modbusPoints[LoopVariable.pv],
      );
      final mv = await modbusClient.read(
        modbusEndpoint,
        modbusPoints[LoopVariable.mv],
      );
      final am = await modbusClient.read(
        modbusEndpoint,
        modbusPoints[LoopVariable.am],
      );
      final lr = await modbusClient.read(
        modbusEndpoint,
        modbusPoints[LoopVariable.lr],
      );
      loopValues = LoopValues(
        sp: sp,
        pv: pv,
        mv: mv,
        am: am >= 0.5,
        lr: lr >= 0.5,
      );
      _appendLivePoint();
      connectionStatus =
          'Leitura OK: ${DateTime.now().toIso8601String().substring(11, 19)}';
    } catch (error) {
      connectionStatus = 'Erro Modbus: $error';
    }
    notifyListeners();
  }

  void _pollSimulatedOnce() {
    final now = DateTime.now();
    final last = _lastLiveTick ?? now;
    final dt = now.difference(last).inMilliseconds / 1000.0;
    _lastLiveTick = now;
    final step = dt <= 0 ? modbusEndpoint.pollPeriodMs / 1000.0 : dt;
    var mv = loopValues.mv;
    if (loopValues.am) {
      final error = loopValues.sp - loopValues.pv;
      mv = (50 + 18 * error).clamp(0.0, 100.0);
    }
    final target = loopValues.sp + (mv - 50) * 0.02;
    final pv =
        loopValues.pv + (target - loopValues.pv) * (step / 5).clamp(0.0, 1.0);
    loopValues = loopValues.copyWith(pv: pv, mv: mv);
    _appendLivePoint();
    connectionStatus = 'Sistema simulado em execução.';
    notifyListeners();
  }

  void _appendLivePoint() {
    final now = DateTime.now();
    final last = _lastLiveTick ?? now;
    final dt = now.difference(last).inMilliseconds / 1000.0;
    _lastLiveTick = now;
    _liveElapsed += dt <= 0 ? modbusEndpoint.pollPeriodMs / 1000.0 : dt;
    liveTime.add(_liveElapsed);
    liveSp.add(loopValues.sp);
    livePv.add(loopValues.pv);
    liveMv.add(loopValues.mv);
    const maxPoints = 2000;
    while (liveTime.length > maxPoints) {
      liveTime.removeAt(0);
      liveSp.removeAt(0);
      livePv.removeAt(0);
      liveMv.removeAt(0);
    }
  }

  Future<void> _writePoint(LoopVariable variable, double value) async {
    try {
      await modbusClient.write(modbusEndpoint, modbusPoints[variable], value);
      connectionStatus = '${variable.label} escrito com sucesso.';
    } catch (error) {
      connectionStatus = 'Falha ao escrever ${variable.label}: $error';
    }
  }

  String _fmt(double value) => value.toStringAsPrecision(4);

  @override
  void dispose() {
    _pollTimer?.cancel();
    modbusClient.disconnect();
    super.dispose();
  }
}
