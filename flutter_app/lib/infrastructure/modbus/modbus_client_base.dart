import '../../domain/modbus_models.dart';

abstract class AppModbusClient {
  bool get isConnected;

  Future<void> connect(ModbusEndpoint endpoint);
  Future<void> disconnect();
  Future<double> read(ModbusEndpoint endpoint, ModbusPointConfig point);
  Future<void> write(
    ModbusEndpoint endpoint,
    ModbusPointConfig point,
    double value,
  );
}
