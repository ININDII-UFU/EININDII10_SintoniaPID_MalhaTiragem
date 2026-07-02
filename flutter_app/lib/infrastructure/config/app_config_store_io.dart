import 'dart:convert';
import 'dart:io';

import '../../domain/modbus_models.dart';
import '../modbus/modbus_bridge_protocol.dart';
import 'app_config_store_base.dart';

AppConfigStore createPlatformConfigStore() => IoConfigStore();

class IoConfigStore implements AppConfigStore {
  IoConfigStore() : _file = _resolveFile();

  final File _file;

  static File _resolveFile() {
    final base =
        Platform.environment['APPDATA'] ??
        Platform.environment['HOME'] ??
        Directory.current.path;
    final dir = Directory('$base/pid_zn_tuner');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return File('${dir.path}/modbus_config.json');
  }

  Map<String, dynamic> _readAll() {
    if (!_file.existsSync()) return {};
    try {
      final raw = _file.readAsStringSync();
      if (raw.isEmpty) return {};
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  void _writeAll(Map<String, dynamic> data) {
    _file.writeAsStringSync(jsonEncode(data));
  }

  @override
  ModbusEndpoint loadEndpoint(ModbusEndpoint fallback) {
    final saved = _readAll()['endpoint'];
    if (saved is Map<String, dynamic>) {
      try {
        return ModbusBridgeProtocol.endpointFromJson(saved);
      } catch (_) {}
    }
    return fallback;
  }

  @override
  ModbusPointMap loadPointMap(ModbusPointMap fallback) {
    final saved = _readAll()['points'];
    if (saved is Map<String, dynamic>) {
      try {
        return ModbusPointMap({
          for (final variable in LoopVariable.values)
            variable: saved[variable.name] == null
                ? fallback[variable]
                : ModbusBridgeProtocol.pointFromJson(
                    saved[variable.name] as Map<String, dynamic>,
                  ),
        });
      } catch (_) {}
    }
    return fallback;
  }

  @override
  void saveEndpoint(ModbusEndpoint endpoint) {
    final data = _readAll();
    data['endpoint'] = ModbusBridgeProtocol.endpointToJson(endpoint);
    _writeAll(data);
  }

  @override
  void savePointMap(ModbusPointMap pointMap) {
    final data = _readAll();
    data['points'] = {
      for (final entry in pointMap.points.entries)
        entry.key.name: ModbusBridgeProtocol.pointToJson(entry.value),
    };
    _writeAll(data);
  }
}
