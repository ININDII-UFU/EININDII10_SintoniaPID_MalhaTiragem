import '../../domain/modbus_models.dart';

class ModbusBridgeProtocol {
  ModbusBridgeProtocol._();

  static Map<String, Object?> endpointToJson(ModbusEndpoint endpoint) {
    return {
      'host': endpoint.host,
      'port': endpoint.port,
      'unitId': endpoint.unitId,
      'pollPeriodMs': endpoint.pollPeriodMs,
      'bridgeUrl': endpoint.bridgeUrl,
    };
  }

  static ModbusEndpoint endpointFromJson(Map<String, dynamic> json) {
    return ModbusEndpoint(
      host: json['host'] as String,
      port: (json['port'] as num).toInt(),
      unitId: (json['unitId'] as num).toInt(),
      pollPeriodMs: (json['pollPeriodMs'] as num?)?.toInt() ?? 1000,
      bridgeUrl: json['bridgeUrl'] as String? ?? 'ws://127.0.0.1:4000',
    );
  }

  static Map<String, Object?> pointToJson(ModbusPointConfig point) {
    return {
      'variable': point.variable.name,
      'address': point.address,
      'area': point.area.name,
      'format': point.format.name,
      'scale': point.scale,
      'offset': point.offset,
    };
  }

  static ModbusPointConfig pointFromJson(Map<String, dynamic> json) {
    return ModbusPointConfig(
      variable: _byName(LoopVariable.values, json['variable'] as String),
      address: (json['address'] as num).toInt(),
      area: _byName(ModbusDataArea.values, json['area'] as String),
      format: _byName(ModbusValueFormat.values, json['format'] as String),
      scale: (json['scale'] as num).toDouble(),
      offset: (json['offset'] as num).toDouble(),
    );
  }

  static T _byName<T extends Enum>(List<T> values, String name) {
    return values.firstWhere((value) => value.name == name);
  }
}
