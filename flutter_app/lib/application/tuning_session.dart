import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/modbus_models.dart';
import '../domain/point_import.dart';
import '../domain/signal_point.dart';
import '../domain/simulation_models.dart';
import '../domain/tuning_models.dart';
import '../infrastructure/config/app_config_store.dart';
import '../infrastructure/modbus/modbus_client.dart';

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
      am: false,
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

  /// Escala do eixo de PV/SP no gráfico ao vivo — MV sempre usa 0-100%
  /// (eixo secundário), mas PV pode representar qualquer grandeza física
  /// (temperatura, vazão, nível, etc.), então unidade e faixa são
  /// configuráveis pelo usuário.
  String pvUnit = '%';
  double pvMin = 0;
  double pvMax = 100;

  final List<double> liveTime = [];
  final List<double> liveSp = [];
  final List<double> livePv = [];
  final List<double> liveMv = [];

  // Estado interno da planta FOPDT simulada (modo "Sistema simulado"):
  // histórico de MV para aplicar o atraso morto (deadTime) e integrador/
  // erro anterior do controlador PID quando em modo Auto.
  final List<SignalPoint> _simMvHistory = [];
  double _simTime = 0;
  double _simIntegral = 0;
  double _simPreviousError = 0;

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

  void setProcessSource(ProcessSource value) {
    processSource = value;
    connectionStatus = value == ProcessSource.simulated
        ? 'Sistema simulado selecionado.'
        : 'Modbus selecionado. Conecte quando o CLP estiver disponível.';
    if (value == ProcessSource.simulated) {
      _resetSimPlant();
    }
    notifyListeners();
  }

  void updatePvScale({String? unit, double? min, double? max}) {
    pvUnit = unit ?? pvUnit;
    pvMin = min ?? pvMin;
    pvMax = max ?? pvMax;
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
    _resetSimPlant();
    notifyListeners();
  }

  void _resetSimPlant() {
    _simMvHistory.clear();
    _simTime = 0;
    _simIntegral = 0;
    _simPreviousError = 0;
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

  /// Envia o resultado de sintonia selecionado (Kp, Ti e Td) ao CLP real via
  /// Modbus, gravando nos pontos [LoopVariable.kp]/[LoopVariable.ki]/
  /// [LoopVariable.kd]. Ti e Td vão nos registradores rotulados "Ki"/"Kd"
  /// porque é assim que a maioria dos controladores de campo armazena a
  /// sintonia (forma Kp/Ti/Td, não Kp/Ki/Kd).
  Future<void> sendTuningToPlc() async {
    final result = selectedResult;
    if (result == null) return;
    if (processSource != ProcessSource.modbus || !modbusConnected) {
      connectionStatus = 'Conecte ao Modbus para enviar a sintonia ao CLP.';
      notifyListeners();
      return;
    }
    final ti = result.gains.ti ?? 0;
    final td = result.gains.td ?? 0;
    await _writePoint(LoopVariable.kp, result.gains.kp);
    await _writePoint(LoopVariable.ki, ti);
    await _writePoint(LoopVariable.kd, td);
    loopValues = loopValues.copyWith(kp: result.gains.kp, ki: ti, kd: td);
    connectionStatus = 'Sintonia (Kp/Ti/Td) enviada ao CLP.';
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
      final kp = await modbusClient.read(
        modbusEndpoint,
        modbusPoints[LoopVariable.kp],
      );
      final ki = await modbusClient.read(
        modbusEndpoint,
        modbusPoints[LoopVariable.ki],
      );
      final kd = await modbusClient.read(
        modbusEndpoint,
        modbusPoints[LoopVariable.kd],
      );
      loopValues = LoopValues(
        sp: sp,
        pv: pv,
        mv: mv,
        am: am >= 0.5,
        lr: lr >= 0.5,
        kp: kp,
        ki: ki,
        kd: kd,
      );
      _appendLivePoint();
      connectionStatus =
          'Leitura OK: ${DateTime.now().toIso8601String().substring(11, 19)}';
    } catch (error) {
      connectionStatus = 'Erro Modbus: $error';
    }
    notifyListeners();
  }

  /// MV neutro (%) ao redor do qual o degrau de entrada da planta FOPDT é
  /// medido — mv=50% equivale a Δu=0. É o mesmo ponto de referência usado
  /// pelo controlador PID em modo Auto (mv = 50% + saída do PID).
  static const double _simMvBaseline = 50;

  void _pollSimulatedOnce() {
    final now = DateTime.now();
    final last = _lastLiveTick ?? now;
    final dt = now.difference(last).inMilliseconds / 1000.0;
    _lastLiveTick = now;
    final step = dt <= 0 ? modbusEndpoint.pollPeriodMs / 1000.0 : dt;

    final selected = selectedResult;
    var mv = loopValues.mv;
    if (loopValues.am) {
      final gains = (selected?.gains ?? const PidGains(kp: 1, ki: 0, kd: 0))
          .scaled(settings.gainScale);
      final error = loopValues.sp - loopValues.pv;
      _simIntegral += error * step;
      final derivative = step > 0
          ? (error - _simPreviousError) / step
          : 0.0;
      final unsaturated =
          gains.kp * error + gains.ki * _simIntegral + gains.kd * derivative;
      mv = (_simMvBaseline + unsaturated).clamp(0.0, 100.0);
      if (mv != _simMvBaseline + unsaturated && gains.ki != 0) {
        _simIntegral -= error * step;
      }
      _simPreviousError = error;
    }

    // Planta FOPDT real: Gp(s) = K·e^(-Ls)/(Ts+1), acionada pelo desvio de
    // MV em relação ao ponto neutro (mesma convenção de Δu usada no cartão
    // "Como calcular K"), com atraso morto aplicado via histórico de MV.
    _simTime += step;
    _simMvHistory.add(SignalPoint(_simTime, mv));
    final horizon = fopdt.deadTime + step * 2 + 1;
    while (_simMvHistory.length > 1 &&
        _simTime - _simMvHistory.first.t > horizon) {
      _simMvHistory.removeAt(0);
    }
    final delayedMv = _delayedSimMv(_simTime - fopdt.deadTime);
    final timeConstant = fopdt.timeConstant > 0 ? fopdt.timeConstant : 1.0;
    final pvSteadyState = fopdt.gain * (delayedMv - _simMvBaseline);
    final pv =
        loopValues.pv + step / timeConstant * (pvSteadyState - loopValues.pv);

    loopValues = loopValues.copyWith(
      pv: pv,
      mv: mv,
      kp: selected?.gains.kp ?? loopValues.kp,
      ki: selected?.gains.ti ?? loopValues.ki,
      kd: selected?.gains.td ?? loopValues.kd,
    );
    _appendLivePoint();
    connectionStatus = 'Sistema simulado em execução.';
    notifyListeners();
  }

  double _delayedSimMv(double atTime) {
    if (_simMvHistory.isEmpty) return _simMvBaseline;
    if (atTime <= _simMvHistory.first.t) return _simMvHistory.first.y;
    for (var i = _simMvHistory.length - 1; i >= 0; i--) {
      if (_simMvHistory[i].t <= atTime) return _simMvHistory[i].y;
    }
    return _simMvHistory.first.y;
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
