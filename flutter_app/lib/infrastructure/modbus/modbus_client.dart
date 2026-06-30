export 'modbus_client_base.dart';

import 'modbus_client_base.dart';
import 'modbus_client_stub.dart'
    if (dart.library.io) 'modbus_client_io.dart';

AppModbusClient createModbusClient() => createPlatformModbusClient();
