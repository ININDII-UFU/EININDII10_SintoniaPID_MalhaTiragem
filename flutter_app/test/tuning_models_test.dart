import 'package:flutter_test/flutter_test.dart';
import 'package:pid_zn_tuner/domain/modbus_models.dart';
import 'package:pid_zn_tuner/domain/point_import.dart';
import 'package:pid_zn_tuner/domain/tuning_models.dart';
import 'package:pid_zn_tuner/infrastructure/modbus/modbus_bridge_protocol.dart';

void main() {
  test('calcula Ziegler-Nichols por reação ao degrau', () {
    const strategy = ReactionCurveTuningStrategy();
    final results = strategy.tune(
      const FopdtParameters(gain: 2, deadTime: 1, timeConstant: 5),
    );
    final pid = results.singleWhere((r) => r.kind == ControllerKind.pid);

    expect(pid.gains.kp, closeTo(3.0, 1e-9));
    expect(pid.gains.ki, closeTo(1.5, 1e-9));
    expect(pid.gains.kd, closeTo(1.5, 1e-9));
  });

  test('calcula Ziegler-Nichols por ganho último', () {
    const strategy = UltimateGainTuningStrategy();
    final results = strategy.tune(const UltimateParameters(ku: 4, pu: 6));
    final pi = results.singleWhere((r) => r.kind == ControllerKind.pi);

    expect(pi.gains.kp, closeTo(1.8, 1e-9));
    expect(pi.gains.ti, closeTo(5.0, 1e-9));
    expect(pi.gains.ki, closeTo(0.36, 1e-9));
  });

  test('parser aceita CSV simples', () {
    const parser = CsvPointParser();
    final points = parser.parse('tempo,saida\n0,0\n1;0.2\n2 0.5');

    expect(points.length, 3);
    expect(points.last.t, 2);
    expect(points.last.y, 0.5);
  });

  test('converte valores Modbus escalados e booleanos', () {
    const sp = ModbusPointConfig(
      variable: LoopVariable.sp,
      address: 0,
      area: ModbusDataArea.holdingRegister,
      format: ModbusValueFormat.uint16,
      scale: 0.1,
      offset: 0,
    );
    const am = ModbusPointConfig(
      variable: LoopVariable.am,
      address: 2,
      area: ModbusDataArea.coil,
      format: ModbusValueFormat.boolean,
      scale: 1,
      offset: 0,
    );

    expect(sp.decode(543), closeTo(54.3, 1e-9));
    expect(sp.encode(54.3), 543);
    expect(am.decode(1), 1);
    expect(am.encode(0), 0);
    expect(am.encode(1), 1);
  });

  test('serializa protocolo do bridge Modbus', () {
    const endpoint = ModbusEndpoint(
      host: '192.168.0.10',
      port: 502,
      unitId: 1,
      pollPeriodMs: 1000,
      bridgeUrl: 'ws://127.0.0.1:4000',
    );
    final point = ModbusPointMap.defaults()[LoopVariable.pv];

    final decodedEndpoint = ModbusBridgeProtocol.endpointFromJson(
      ModbusBridgeProtocol.endpointToJson(endpoint),
    );
    final decodedPoint = ModbusBridgeProtocol.pointFromJson(
      ModbusBridgeProtocol.pointToJson(point),
    );

    expect(decodedEndpoint.host, endpoint.host);
    expect(decodedEndpoint.bridgeUrl, endpoint.bridgeUrl);
    expect(decodedPoint.variable, LoopVariable.pv);
    expect(decodedPoint.scale, point.scale);
  });
}
