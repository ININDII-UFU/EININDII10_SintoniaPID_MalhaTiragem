import '../../domain/modbus_models.dart';

abstract class AppConfigStore {
  ModbusEndpoint loadEndpoint(ModbusEndpoint fallback);
  ModbusPointMap loadPointMap(ModbusPointMap fallback);
  void saveEndpoint(ModbusEndpoint endpoint);
  void savePointMap(ModbusPointMap pointMap);
}
