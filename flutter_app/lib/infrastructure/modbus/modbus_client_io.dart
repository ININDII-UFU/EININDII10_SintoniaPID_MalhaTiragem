import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../domain/modbus_models.dart';
import 'modbus_client_base.dart';

AppModbusClient createPlatformModbusClient() => ModbusTcpClient();

class ModbusTcpClient implements AppModbusClient {
  Socket? _socket;
  int _transactionId = 0;
  Future<void> _chain = Future.value();

  @override
  bool get isConnected => _socket != null;

  @override
  Future<void> connect(ModbusEndpoint endpoint) async {
    await disconnect();
    _socket = await Socket.connect(
      endpoint.host,
      endpoint.port,
      timeout: const Duration(seconds: 4),
    );
    _socket!.setOption(SocketOption.tcpNoDelay, true);
  }

  @override
  Future<void> disconnect() async {
    final socket = _socket;
    _socket = null;
    if (socket != null) {
      await socket.close();
      await socket.done.timeout(
        const Duration(seconds: 1),
        onTimeout: () {},
      );
    }
  }

  @override
  Future<double> read(ModbusEndpoint endpoint, ModbusPointConfig point) {
    return _enqueue(() async {
      await _ensureConnected(endpoint);
      final quantity = 1;
      final pdu = Uint8List(5)
        ..[0] = point.area.readFunction
        ..[1] = point.address >> 8
        ..[2] = point.address & 0xFF
        ..[3] = quantity >> 8
        ..[4] = quantity & 0xFF;
      final response = await _request(endpoint.unitId, pdu);
      _throwIfException(response);
      if (point.area == ModbusDataArea.coil ||
          point.area == ModbusDataArea.discreteInput) {
        if (response.length < 3) throw const FormatException('Resposta curta.');
        return point.decode(response[2] & 0x01);
      }
      if (response.length < 4) throw const FormatException('Resposta curta.');
      final raw = (response[2] << 8) | response[3];
      return point.decode(raw);
    });
  }

  @override
  Future<void> write(
    ModbusEndpoint endpoint,
    ModbusPointConfig point,
    double value,
  ) {
    return _enqueue(() async {
      if (!point.canWrite) {
        throw StateError('${point.area.label} não aceita escrita.');
      }
      await _ensureConnected(endpoint);
      final raw = point.encode(value);
      final function = point.area == ModbusDataArea.coil ? 5 : 6;
      final writeValue = point.area == ModbusDataArea.coil
          ? (raw == 0 ? 0x0000 : 0xFF00)
          : raw;
      final pdu = Uint8List(5)
        ..[0] = function
        ..[1] = point.address >> 8
        ..[2] = point.address & 0xFF
        ..[3] = writeValue >> 8
        ..[4] = writeValue & 0xFF;
      final response = await _request(endpoint.unitId, pdu);
      _throwIfException(response);
    });
  }

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _chain = _chain.then((_) => action()).then(
      completer.complete,
      onError: completer.completeError,
    );
    return completer.future;
  }

  Future<void> _ensureConnected(ModbusEndpoint endpoint) async {
    if (_socket == null) await connect(endpoint);
  }

  Future<Uint8List> _request(int unitId, Uint8List pdu) async {
    final socket = _socket;
    if (socket == null) throw StateError('Modbus desconectado.');

    final tid = (_transactionId = (_transactionId + 1) & 0xFFFF);
    final frame = Uint8List(7 + pdu.length);
    frame[0] = tid >> 8;
    frame[1] = tid & 0xFF;
    frame[2] = 0;
    frame[3] = 0;
    final length = pdu.length + 1;
    frame[4] = length >> 8;
    frame[5] = length & 0xFF;
    frame[6] = unitId & 0xFF;
    frame.setRange(7, frame.length, pdu);

    final bytes = <int>[];
    late StreamSubscription<List<int>> sub;
    final completer = Completer<Uint8List>();
    sub = socket.listen(
      (chunk) {
        bytes.addAll(chunk);
        if (bytes.length < 7) return;
        final expected = 6 + ((bytes[4] << 8) | bytes[5]);
        if (bytes.length >= expected && !completer.isCompleted) {
          completer.complete(Uint8List.fromList(bytes.take(expected).toList()));
        }
      },
      onError: completer.completeError,
      onDone: () {
        if (!completer.isCompleted) {
          completer.completeError(StateError('Conexão Modbus encerrada.'));
        }
      },
      cancelOnError: true,
    );

    socket.add(frame);
    await socket.flush();
    final response = await completer.future.timeout(const Duration(seconds: 3));
    await sub.cancel();

    final responseTid = (response[0] << 8) | response[1];
    if (responseTid != tid) throw const FormatException('Transaction ID inválido.');
    return response.sublist(7);
  }

  void _throwIfException(Uint8List pdu) {
    if (pdu.isEmpty) throw const FormatException('PDU vazia.');
    if ((pdu[0] & 0x80) != 0) {
      final code = pdu.length > 1 ? pdu[1] : 0;
      throw StateError('Exceção Modbus $code.');
    }
  }
}
