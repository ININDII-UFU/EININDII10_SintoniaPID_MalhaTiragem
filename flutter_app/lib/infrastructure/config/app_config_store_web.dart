import 'dart:convert';

import 'package:web/web.dart' as web;

import '../../domain/modbus_models.dart';
import '../modbus/modbus_bridge_protocol.dart';
import 'app_config_store_base.dart';

AppConfigStore createPlatformConfigStore() => WebConfigStore();

class WebConfigStore implements AppConfigStore {
  static const _endpointKey = 'pid_zn_tuner.modbus_endpoint';
  static const _pointsKey = 'pid_zn_tuner.modbus_points';

  @override
  ModbusEndpoint loadEndpoint(ModbusEndpoint fallback) {
    var endpoint = fallback;
    final saved = web.window.localStorage.getItem(_endpointKey);
    if (saved != null && saved.isNotEmpty) {
      try {
        endpoint = ModbusBridgeProtocol.endpointFromJson(
          jsonDecode(saved) as Map<String, dynamic>,
        );
      } catch (_) {}
    }
    return _applyEndpointQuery(endpoint);
  }

  @override
  ModbusPointMap loadPointMap(ModbusPointMap fallback) {
    final saved = web.window.localStorage.getItem(_pointsKey);
    if (saved == null || saved.isEmpty) return fallback;
    try {
      final raw = jsonDecode(saved) as Map<String, dynamic>;
      return ModbusPointMap({
        for (final variable in LoopVariable.values)
          variable: raw[variable.name] == null
              ? fallback[variable]
              : ModbusBridgeProtocol.pointFromJson(
                  raw[variable.name] as Map<String, dynamic>,
                ),
      });
    } catch (_) {
      return fallback;
    }
  }

  @override
  void saveEndpoint(ModbusEndpoint endpoint) {
    web.window.localStorage.setItem(
      _endpointKey,
      jsonEncode(ModbusBridgeProtocol.endpointToJson(endpoint)),
    );
  }

  @override
  void savePointMap(ModbusPointMap pointMap) {
    web.window.localStorage.setItem(
      _pointsKey,
      jsonEncode({
        for (final entry in pointMap.points.entries)
          entry.key.name: ModbusBridgeProtocol.pointToJson(entry.value),
      }),
    );
  }

  ModbusEndpoint _applyEndpointQuery(ModbusEndpoint endpoint) {
    final qp = Uri.base.queryParameters;
    final host = qp['ip'] ?? qp['host'];
    final port = _intParam(qp, ['modbusPort', 'mbport', 'targetPort', 'port']);
    final unitId = _intParam(qp, ['unitId', 'unit']);
    final period = _intParam(qp, ['period', 'poll', 'pollMs']);
    final bridge = qp['bridge'] ?? qp['bridgeUrl'] ?? qp['ws'];

    return endpoint.copyWith(
      host: host == null || host.isEmpty ? null : host,
      port: port,
      unitId: unitId,
      pollPeriodMs: period,
      bridgeUrl: bridge == null || bridge.isEmpty ? null : bridge,
    );
  }

  int? _intParam(Map<String, String> qp, List<String> names) {
    for (final name in names) {
      final value = qp[name];
      if (value == null || value.isEmpty) continue;
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    return null;
  }
}
