import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../domain/modbus_models.dart';
import 'modbus_bridge_protocol.dart';
import 'modbus_client_base.dart';

AppModbusClient createPlatformModbusClient() => ModbusBridgeClient();

class ModbusBridgeClient implements AppModbusClient {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  int _nextId = 0;

  @override
  bool get isConnected => _channel != null;

  @override
  Future<void> connect(ModbusEndpoint endpoint) async {
    await disconnect();
    _channel = WebSocketChannel.connect(Uri.parse(endpoint.bridgeUrl));
    _subscription = _channel!.stream.listen(
      _onMessage,
      onError: _failAll,
      onDone: () => _failAll(StateError('Bridge Modbus desconectado.')),
    );
    await _send('connect', endpoint: endpoint);
  }

  @override
  Future<void> disconnect() async {
    final channel = _channel;
    _channel = null;
    await _subscription?.cancel();
    _subscription = null;
    if (channel != null) {
      await channel.sink.close();
    }
    _failAll(StateError('Bridge Modbus desconectado.'));
  }

  @override
  Future<double> read(ModbusEndpoint endpoint, ModbusPointConfig point) async {
    await _ensureConnected(endpoint);
    final response = await _send('read', endpoint: endpoint, point: point);
    return (response['value'] as num).toDouble();
  }

  @override
  Future<void> write(
    ModbusEndpoint endpoint,
    ModbusPointConfig point,
    double value,
  ) async {
    await _ensureConnected(endpoint);
    await _send('write', endpoint: endpoint, point: point, value: value);
  }

  Future<void> _ensureConnected(ModbusEndpoint endpoint) async {
    if (_channel == null) await connect(endpoint);
  }

  Future<Map<String, dynamic>> _send(
    String type, {
    ModbusEndpoint? endpoint,
    ModbusPointConfig? point,
    double? value,
  }) async {
    final channel = _channel;
    if (channel == null) throw StateError('Bridge Modbus desconectado.');
    return _sendOn(
      channel,
      type,
      endpoint: endpoint,
      point: point,
      value: value,
    );
  }

  Future<Map<String, dynamic>> _sendOn(
    WebSocketChannel channel,
    String type, {
    ModbusEndpoint? endpoint,
    ModbusPointConfig? point,
    double? value,
  }) {
    final id = ++_nextId;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    final payload = <String, Object?>{'id': id, 'type': type};
    if (endpoint != null) {
      payload['endpoint'] = ModbusBridgeProtocol.endpointToJson(endpoint);
    }
    if (point != null) {
      payload['point'] = ModbusBridgeProtocol.pointToJson(point);
    }
    if (value != null) {
      payload['value'] = value;
    }
    channel.sink.add(jsonEncode(payload));
    return completer.future.timeout(
      const Duration(seconds: 6),
      onTimeout: () {
        _pending.remove(id);
        throw TimeoutException('Bridge Modbus não respondeu.');
      },
    );
  }

  void _onMessage(dynamic raw) {
    final data = jsonDecode(raw as String) as Map<String, dynamic>;
    final id = data['id'] as int?;
    if (id == null) return;
    final completer = _pending.remove(id);
    if (completer == null || completer.isCompleted) return;
    if (data['ok'] == true) {
      completer.complete(data);
    } else {
      completer.completeError(StateError(data['error'] as String? ?? 'Erro'));
    }
  }

  void _failAll(Object error) {
    for (final completer in _pending.values) {
      if (!completer.isCompleted) completer.completeError(error);
    }
    _pending.clear();
    _channel = null;
  }
}
