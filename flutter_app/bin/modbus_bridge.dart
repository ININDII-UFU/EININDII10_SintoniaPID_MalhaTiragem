import 'dart:convert';
import 'dart:io';

import 'package:pid_zn_tuner/domain/modbus_models.dart';
import 'package:pid_zn_tuner/infrastructure/modbus/modbus_bridge_protocol.dart';
import 'package:pid_zn_tuner/infrastructure/modbus/modbus_client_io.dart';

Future<void> main(List<String> args) async {
  final bindHost = _arg(args, '--bind') ?? '127.0.0.1';
  final bindPort = int.tryParse(_arg(args, '--port') ?? '') ?? 4000;
  final server = await HttpServer.bind(bindHost, bindPort);
  stdout.writeln('Modbus bridge escutando em ws://$bindHost:$bindPort');
  stdout.writeln('Use Ctrl+C para encerrar.');

  await for (final request in server) {
    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.text
        ..write('Modbus bridge ativo. Conecte via WebSocket.')
        ..close();
      continue;
    }

    final socket = await WebSocketTransformer.upgrade(request);
    _serveClient(socket);
  }
}

void _serveClient(WebSocket socket) {
  final client = ModbusTcpClient();
  socket.listen(
    (raw) async {
      final Map<String, dynamic> message;
      try {
        message = jsonDecode(raw as String) as Map<String, dynamic>;
      } catch (error) {
        socket.add(jsonEncode({'ok': false, 'error': 'JSON inválido: $error'}));
        return;
      }

      final id = message['id'];
      try {
        final result = await _handleMessage(client, message);
        socket.add(jsonEncode({'id': id, 'ok': true, ...result}));
      } catch (error) {
        socket.add(jsonEncode({'id': id, 'ok': false, 'error': '$error'}));
      }
    },
    onDone: client.disconnect,
    onError: (_) => client.disconnect(),
    cancelOnError: true,
  );
}

Future<Map<String, Object?>> _handleMessage(
  ModbusTcpClient client,
  Map<String, dynamic> message,
) async {
  final type = message['type'] as String?;
  switch (type) {
    case 'connect':
      await client.connect(_endpoint(message));
      return {'connected': true};
    case 'disconnect':
      await client.disconnect();
      return {'connected': false};
    case 'read':
      final value = await client.read(_endpoint(message), _point(message));
      return {'value': value};
    case 'write':
      final value = (message['value'] as num).toDouble();
      await client.write(_endpoint(message), _point(message), value);
      return {'written': true};
    default:
      throw ArgumentError('Tipo de mensagem desconhecido: $type');
  }
}

ModbusEndpoint _endpoint(Map<String, dynamic> message) {
  return ModbusBridgeProtocol.endpointFromJson(
    message['endpoint'] as Map<String, dynamic>,
  );
}

ModbusPointConfig _point(Map<String, dynamic> message) {
  return ModbusBridgeProtocol.pointFromJson(
    message['point'] as Map<String, dynamic>,
  );
}

String? _arg(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index < 0 || index + 1 >= args.length) return null;
  return args[index + 1];
}
