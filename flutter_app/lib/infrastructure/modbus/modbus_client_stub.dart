import '../../domain/modbus_models.dart';
import 'modbus_client_base.dart';

AppModbusClient createPlatformModbusClient() => _UnsupportedModbusClient();

class _UnsupportedModbusClient implements AppModbusClient {
  @override
  bool get isConnected => false;

  @override
  Future<void> connect(ModbusEndpoint endpoint) {
    throw UnsupportedError(
      'Modbus TCP precisa de socket TCP. Use o app desktop para conectar ao CLP.',
    );
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<double> read(ModbusEndpoint endpoint, ModbusPointConfig point) {
    throw UnsupportedError('Modbus TCP indisponível nesta plataforma.');
  }

  @override
  Future<void> write(
    ModbusEndpoint endpoint,
    ModbusPointConfig point,
    double value,
  ) {
    throw UnsupportedError('Modbus TCP indisponível nesta plataforma.');
  }
}
