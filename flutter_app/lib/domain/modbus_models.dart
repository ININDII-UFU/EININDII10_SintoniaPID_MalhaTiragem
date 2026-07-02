enum ProcessSource {
  simulated('Sistema simulado'),
  modbus('Modbus TCP');

  const ProcessSource(this.label);
  final String label;
}

enum ModbusDataArea {
  holdingRegister('Holding register', 3),
  inputRegister('Input register', 4),
  coil('Coil', 1),
  discreteInput('Discrete input', 2);

  const ModbusDataArea(this.label, this.readFunction);
  final String label;
  final int readFunction;

  bool get canWrite => this == holdingRegister || this == coil;
}

enum ModbusValueFormat {
  uint16('UInt16'),
  int16('Int16'),
  boolean('Booleano');

  const ModbusValueFormat(this.label);
  final String label;
}

enum LoopVariable {
  sp('SP', 'Setpoint'),
  pv('PV', 'Process variable'),
  am('AM', 'Auto/manual'),
  lr('LR', 'Local/remoto'),
  mv('MV', 'Manipulada');

  const LoopVariable(this.label, this.description);
  final String label;
  final String description;
}

class ModbusEndpoint {
  const ModbusEndpoint({
    required this.host,
    required this.port,
    required this.unitId,
    required this.pollPeriodMs,
    required this.bridgeUrl,
  });

  final String host;
  final int port;
  final int unitId;
  final int pollPeriodMs;
  final String bridgeUrl;

  ModbusEndpoint copyWith({
    String? host,
    int? port,
    int? unitId,
    int? pollPeriodMs,
    String? bridgeUrl,
  }) {
    return ModbusEndpoint(
      host: host ?? this.host,
      port: port ?? this.port,
      unitId: unitId ?? this.unitId,
      pollPeriodMs: pollPeriodMs ?? this.pollPeriodMs,
      bridgeUrl: bridgeUrl ?? this.bridgeUrl,
    );
  }
}

class ModbusPointConfig {
  const ModbusPointConfig({
    required this.variable,
    required this.address,
    required this.area,
    required this.format,
    required this.scale,
    required this.offset,
  });

  final LoopVariable variable;
  final int address;
  final ModbusDataArea area;
  final ModbusValueFormat format;
  final double scale;
  final double offset;

  bool get canWrite => area.canWrite;

  double decode(int raw) {
    final normalized = switch (format) {
      ModbusValueFormat.int16 => raw >= 0x8000 ? raw - 0x10000 : raw,
      ModbusValueFormat.boolean => raw == 0 ? 0.0 : 1.0,
      ModbusValueFormat.uint16 => raw.toDouble(),
    };
    return normalized * scale + offset;
  }

  int encode(double value) {
    final scaled = scale == 0 ? value : (value - offset) / scale;
    if (format == ModbusValueFormat.boolean) {
      return scaled >= 0.5 ? 1 : 0;
    }
    final rounded = scaled.round();
    return rounded.clamp(-32768, 65535) & 0xFFFF;
  }

  ModbusPointConfig copyWith({
    int? address,
    ModbusDataArea? area,
    ModbusValueFormat? format,
    double? scale,
    double? offset,
  }) {
    return ModbusPointConfig(
      variable: variable,
      address: address ?? this.address,
      area: area ?? this.area,
      format: format ?? this.format,
      scale: scale ?? this.scale,
      offset: offset ?? this.offset,
    );
  }
}

class ModbusPointMap {
  const ModbusPointMap(this.points);

  final Map<LoopVariable, ModbusPointConfig> points;

  ModbusPointConfig operator [](LoopVariable variable) => points[variable]!;

  ModbusPointMap update(
    LoopVariable variable,
    ModbusPointConfig Function(ModbusPointConfig point) change,
  ) {
    return ModbusPointMap({...points, variable: change(points[variable]!)});
  }

  static ModbusPointMap defaults() {
    return ModbusPointMap({
      LoopVariable.sp: const ModbusPointConfig(
        variable: LoopVariable.sp,
        address: 0,
        area: ModbusDataArea.holdingRegister,
        format: ModbusValueFormat.uint16,
        scale: 0.1,
        offset: 0,
      ),
      LoopVariable.pv: const ModbusPointConfig(
        variable: LoopVariable.pv,
        address: 1,
        area: ModbusDataArea.holdingRegister,
        format: ModbusValueFormat.uint16,
        scale: 0.1,
        offset: 0,
      ),
      LoopVariable.am: const ModbusPointConfig(
        variable: LoopVariable.am,
        address: 2,
        area: ModbusDataArea.coil,
        format: ModbusValueFormat.boolean,
        scale: 1,
        offset: 0,
      ),
      LoopVariable.lr: const ModbusPointConfig(
        variable: LoopVariable.lr,
        address: 3,
        area: ModbusDataArea.coil,
        format: ModbusValueFormat.boolean,
        scale: 1,
        offset: 0,
      ),
      LoopVariable.mv: const ModbusPointConfig(
        variable: LoopVariable.mv,
        address: 4,
        area: ModbusDataArea.holdingRegister,
        format: ModbusValueFormat.uint16,
        scale: 0.1,
        offset: 0,
      ),
    });
  }
}

class LoopValues {
  const LoopValues({
    required this.sp,
    required this.pv,
    required this.mv,
    required this.am,
    required this.lr,
  });

  final double sp;
  final double pv;
  final double mv;
  final bool am;
  final bool lr;

  LoopValues copyWith({
    double? sp,
    double? pv,
    double? mv,
    bool? am,
    bool? lr,
  }) {
    return LoopValues(
      sp: sp ?? this.sp,
      pv: pv ?? this.pv,
      mv: mv ?? this.mv,
      am: am ?? this.am,
      lr: lr ?? this.lr,
    );
  }
}
