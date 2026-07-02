import '../../domain/modbus_models.dart';
import 'app_config_store_base.dart';

AppConfigStore createPlatformConfigStore() => _NoopConfigStore();

class _NoopConfigStore implements AppConfigStore {
  @override
  ModbusEndpoint loadEndpoint(ModbusEndpoint fallback) => fallback;

  @override
  ModbusPointMap loadPointMap(ModbusPointMap fallback) => fallback;

  @override
  void saveEndpoint(ModbusEndpoint endpoint) {}

  @override
  void savePointMap(ModbusPointMap pointMap) {}
}
