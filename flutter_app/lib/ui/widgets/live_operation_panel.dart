import 'package:flutter/material.dart';

import '../../application/tuning_session.dart';
import '../../domain/modbus_models.dart';
import '../../domain/signal_point.dart';
import '../theme/app_palette.dart';
import 'response_chart.dart';
import 'section_card.dart';

class LiveOperationWorkspace extends StatefulWidget {
  const LiveOperationWorkspace({super.key, required this.session});

  final TuningSession session;

  @override
  State<LiveOperationWorkspace> createState() => _LiveOperationWorkspaceState();
}

class _LiveOperationWorkspaceState extends State<LiveOperationWorkspace> {
  bool _showPv = true;
  bool _showSp = true;
  bool _showMv = true;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 900;
          final display = _ControllerDisplay(session: session);
          final graph = _LiveGraph(
            session: session,
            showPv: _showPv,
            showSp: _showSp,
            showMv: _showMv,
            onShowPv: (v) => setState(() => _showPv = v),
            onShowSp: (v) => setState(() => _showSp = v),
            onShowMv: (v) => setState(() => _showMv = v),
          );
          return ListView(
            children: [
              if (narrow) ...[
                display,
                const SizedBox(height: 14),
                graph,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 285, child: display),
                    const SizedBox(width: 14),
                    Expanded(child: graph),
                  ],
                ),
              const SizedBox(height: 14),
              _OperationGuide(source: session.processSource),
            ],
          );
        },
      ),
    );
  }
}

class OperationConfigPanel extends StatelessWidget {
  const OperationConfigPanel({super.key, required this.session});

  final TuningSession session;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        SectionCard(
          title: 'FONTE DO PROCESSO',
          icon: Icons.account_tree_outlined,
          accent: AppPalette.brandPrimary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<ProcessSource>(
                segments: [
                  for (final source in ProcessSource.values)
                    ButtonSegment(
                      value: source,
                      label: Text(source.label),
                      icon: Icon(
                        source == ProcessSource.simulated
                            ? Icons.memory
                            : Icons.lan,
                      ),
                    ),
                ],
                selected: {session.processSource},
                onSelectionChanged: (values) =>
                    session.setProcessSource(values.first),
              ),
              const SizedBox(height: 12),
              Text(
                session.connectionStatus,
                style: const TextStyle(
                  color: AppPalette.textSecondary,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ConnectionCard(session: session),
        const SizedBox(height: 12),
        _PointsCard(session: session),
      ],
    );
  }
}

class _ControllerDisplay extends StatelessWidget {
  const _ControllerDisplay({required this.session});

  final TuningSession session;

  @override
  Widget build(BuildContext context) {
    final values = session.loopValues;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppPalette.textPrimary.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'VALORES ATUAIS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppPalette.brandAccent,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _DarkValueField(
            label: 'PV',
            value: values.pv,
            decimals: 1,
            enabled: false,
          ),
          _DarkValueField(
            label: 'SP',
            value: values.sp,
            decimals: 1,
            enabled: values.lr,
            onSubmitted: session.writeSp,
          ),
          _ModeButtons(
            left: 'Local',
            right: 'Remoto',
            leftActive: values.lr,
            onLeft: () => session.setLocalMode(true),
            onRight: () => session.setLocalMode(false),
          ),
          const SizedBox(height: 10),
          _DarkValueField(
            label: 'MV',
            value: values.mv,
            decimals: 2,
            enabled: !values.am,
            suffix: '%',
            onSubmitted: session.writeMv,
          ),
          Row(
            children: [
              const Text(
                'A',
                style: TextStyle(color: Color(0xFFBDC3C7), fontSize: 13),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DarkValueField(
                  label: '',
                  value: session.manualStep,
                  decimals: 1,
                  dense: true,
                  enabled: !values.am,
                  onSubmitted: session.setManualStep,
                ),
              ),
              const SizedBox(width: 8),
              _MiniButton(
                label: 'A+',
                enabled: !values.am,
                onTap: () => session.nudgeMv(session.manualStep),
              ),
              const SizedBox(width: 6),
              _MiniButton(
                label: 'A-',
                enabled: !values.am,
                onTap: () => session.nudgeMv(-session.manualStep),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ModeButtons(
            left: 'Auto',
            right: 'Manual',
            leftActive: values.am,
            onLeft: () => session.setAutoMode(true),
            onRight: () => session.setAutoMode(false),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: session.modbusEndpoint.pollPeriodMs,
            dropdownColor: const Color(0xFF2C3E50),
            decoration: const InputDecoration(
              labelText: 'Division time',
              labelStyle: TextStyle(color: Color(0xFFBDC3C7)),
            ),
            style: const TextStyle(color: Colors.white),
            items: const [
              DropdownMenuItem(value: 500, child: Text('0.5 segundo')),
              DropdownMenuItem(value: 1000, child: Text('1 segundo')),
              DropdownMenuItem(value: 2000, child: Text('2 segundos')),
              DropdownMenuItem(value: 3000, child: Text('3 segundos')),
              DropdownMenuItem(value: 5000, child: Text('5 segundos')),
            ],
            onChanged: (value) {
              if (value != null) {
                session.updateModbusEndpoint(pollPeriodMs: value);
                if (session.liveRunning) {
                  session.stopLive();
                  session.startLive();
                }
              }
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: session.liveRunning
                    ? session.stopLive
                    : session.startLive,
                icon: Icon(
                  session.liveRunning ? Icons.pause : Icons.play_arrow,
                  size: 18,
                ),
                label: Text(session.liveRunning ? 'Stop' : 'Play'),
              ),
              OutlinedButton.icon(
                onPressed: session.pollOnce,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Ler'),
              ),
              OutlinedButton.icon(
                onPressed: session.clearLiveHistory,
                icon: const Icon(Icons.cleaning_services_outlined, size: 18),
                label: const Text('Limpar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveGraph extends StatelessWidget {
  const _LiveGraph({
    required this.session,
    required this.showPv,
    required this.showSp,
    required this.showMv,
    required this.onShowPv,
    required this.onShowSp,
    required this.onShowMv,
  });

  final TuningSession session;
  final bool showPv;
  final bool showSp;
  final bool showMv;
  final ValueChanged<bool> onShowPv;
  final ValueChanged<bool> onShowSp;
  final ValueChanged<bool> onShowMv;

  @override
  Widget build(BuildContext context) {
    final series = <ChartSeries>[
      if (showPv)
        ChartSeries(
          label: 'PV',
          points: _points(session.liveTime, session.livePv),
          color: AppPalette.reaction,
        ),
      if (showSp)
        ChartSeries(
          label: 'SP',
          points: _points(session.liveTime, session.liveSp),
          color: AppPalette.success,
          dashed: true,
        ),
      if (showMv)
        ChartSeries(
          label: 'MV',
          points: _points(session.liveTime, session.liveMv),
          color: AppPalette.warning,
        ),
    ];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'GRÁFICO DE CONTROLE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppPalette.brandAccent,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ResponseChart(
            title: session.processSource.label,
            xLabel: 'Tempo (s)',
            yLabel: 'PV / SP / MV',
            height: 420,
            series: series,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            children: [
              _TraceCheck(label: 'PV', value: showPv, onChanged: onShowPv),
              _TraceCheck(label: 'SP', value: showSp, onChanged: onShowSp),
              _TraceCheck(label: 'MV', value: showMv, onChanged: onShowMv),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({required this.session});

  final TuningSession session;

  @override
  Widget build(BuildContext context) {
    final endpoint = session.modbusEndpoint;
    return SectionCard(
      title: 'MODBUS TCP',
      icon: Icons.lan,
      accent: AppPalette.simulation,
      child: Column(
        children: [
          _TextValueField(
            label: 'IP do CLP ou gateway',
            value: endpoint.host,
            helper:
                'Exemplo: 192.168.0.10. O app só conecta ao pressionar Conectar.',
            onChanged: (value) => session.updateModbusEndpoint(host: value),
          ),
          _NumberValueField(
            label: 'Porta Modbus do equipamento',
            value: endpoint.port.toDouble(),
            helper:
                'Informe a porta real do equipamento/gateway. Pode ser 502, 4000, 1502 ou qualquer outra configurada.',
            decimals: 0,
            onChanged: (value) =>
                session.updateModbusEndpoint(port: value.round()),
          ),
          _NumberValueField(
            label: 'Unit ID',
            value: endpoint.unitId.toDouble(),
            helper:
                'Identificador do escravo Modbus. Em TCP puro costuma ser 1.',
            decimals: 0,
            onChanged: (value) =>
                session.updateModbusEndpoint(unitId: value.round()),
          ),
          _TextValueField(
            label: 'Bridge WebSocket para uso web',
            value: endpoint.bridgeUrl,
            helper:
                'No GitHub Pages use wss://seu-servidor:porta. Em teste local use ws://127.0.0.1:4000.',
            onChanged: (value) =>
                session.updateModbusEndpoint(bridgeUrl: value),
          ),
          _NumberValueField(
            label: 'Período de leitura (ms)',
            value: endpoint.pollPeriodMs.toDouble(),
            helper:
                'Intervalo de atualização das variáveis SP, PV, AM, LR e MV.',
            decimals: 0,
            onChanged: (value) =>
                session.updateModbusEndpoint(pollPeriodMs: value.round()),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: session.connectModbus,
                icon: const Icon(Icons.power, size: 18),
                label: const Text('Conectar'),
              ),
              OutlinedButton.icon(
                onPressed: session.modbusConnected
                    ? session.disconnectModbus
                    : null,
                icon: const Icon(Icons.power_off, size: 18),
                label: const Text('Desconectar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PointsCard extends StatelessWidget {
  const _PointsCard({required this.session});

  final TuningSession session;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'VARIÁVEIS DA MALHA',
      icon: Icons.tag,
      accent: AppPalette.ultimate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Use endereços base zero: o registrador 40001 vira endereço 0, 40002 vira 1. Ajuste a escala se o CLP usar inteiro escalado, por exemplo 0,1 para uma casa decimal.',
            style: TextStyle(
              color: AppPalette.textSecondary,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          for (final variable in LoopVariable.values) ...[
            _PointConfigTile(
              session: session,
              variable: variable,
              point: session.modbusPoints[variable],
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _PointConfigTile extends StatelessWidget {
  const _PointConfigTile({
    required this.session,
    required this.variable,
    required this.point,
  });

  final TuningSession session;
  final LoopVariable variable;
  final ModbusPointConfig point;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppPalette.surfaceAlt.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${variable.label} · ${variable.description}',
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _NumberValueField(
                  label: 'Endereço',
                  value: point.address.toDouble(),
                  decimals: 0,
                  helper: '',
                  onChanged: (value) => session.updateModbusPoint(
                    variable,
                    address: value.round(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<ModbusDataArea>(
                  initialValue: point.area,
                  decoration: const InputDecoration(labelText: 'Área'),
                  items: [
                    for (final area in ModbusDataArea.values)
                      DropdownMenuItem(value: area, child: Text(area.label)),
                  ],
                  onChanged: (area) {
                    if (area != null) {
                      session.updateModbusPoint(variable, area: area);
                    }
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<ModbusValueFormat>(
                  initialValue: point.format,
                  decoration: const InputDecoration(labelText: 'Formato'),
                  items: [
                    for (final format in ModbusValueFormat.values)
                      DropdownMenuItem(
                        value: format,
                        child: Text(format.label),
                      ),
                  ],
                  onChanged: (format) {
                    if (format != null) {
                      session.updateModbusPoint(variable, format: format);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberValueField(
                  label: 'Escala',
                  value: point.scale,
                  helper: '',
                  onChanged: (value) =>
                      session.updateModbusPoint(variable, scale: value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OperationGuide extends StatelessWidget {
  const _OperationGuide({required this.source});

  final ProcessSource source;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'COMO USAR',
      icon: Icons.info_outline,
      accent: AppPalette.brandAccent,
      child: Text(
        source == ProcessSource.simulated
            ? 'No sistema simulado você pode testar a tela sem CLP: altere SP, coloque em Manual para escrever MV ou deixe em Auto para ver a PV seguir o setpoint.'
            : 'No desktop o app fala Modbus TCP direto. Na web, primeiro rode o modbus_bridge e informe o endereço WebSocket dele; o navegador fala com o bridge, e o bridge fala Modbus TCP com o CLP.',
        style: const TextStyle(
          color: AppPalette.textSecondary,
          fontSize: 12.5,
          height: 1.45,
        ),
      ),
    );
  }
}

class _DarkValueField extends StatefulWidget {
  const _DarkValueField({
    required this.label,
    required this.value,
    required this.decimals,
    this.enabled = true,
    this.dense = false,
    this.suffix,
    this.onSubmitted,
  });

  final String label;
  final double value;
  final int decimals;
  final bool enabled;
  final bool dense;
  final String? suffix;
  final ValueChanged<double>? onSubmitted;

  @override
  State<_DarkValueField> createState() => _DarkValueFieldState();
}

class _DarkValueFieldState extends State<_DarkValueField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _DarkValueField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.value != widget.value) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      textAlign: TextAlign.right,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        color: widget.enabled
            ? AppPalette.brandAccent
            : const Color(0xFF7F8C8D),
        fontWeight: FontWeight.w800,
        fontSize: widget.dense ? 13 : 16,
      ),
      decoration: InputDecoration(
        suffixText: widget.suffix,
        suffixStyle: const TextStyle(color: AppPalette.brandAccent),
        fillColor: Colors.black.withValues(alpha: widget.enabled ? 0.20 : 0.10),
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: widget.dense ? 8 : 10,
          vertical: widget.dense ? 8 : 10,
        ),
      ),
      onSubmitted: _submit,
      onEditingComplete: () => _submit(_controller.text),
    );
    if (widget.label.isEmpty) return field;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(color: Color(0xFFBDC3C7), fontSize: 13),
          ),
          const SizedBox(height: 4),
          field,
        ],
      ),
    );
  }

  void _submit(String raw) {
    final parsed = double.tryParse(raw.replaceAll(',', '.'));
    if (parsed != null) widget.onSubmitted?.call(parsed);
  }

  String _format(double value) => value.toStringAsFixed(widget.decimals);
}

class _ModeButtons extends StatelessWidget {
  const _ModeButtons({
    required this.left,
    required this.right,
    required this.leftActive,
    required this.onLeft,
    required this.onRight,
  });

  final String left;
  final String right;
  final bool leftActive;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeButton(label: left, active: leftActive, onTap: onLeft),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ModeButton(label: right, active: !leftActive, onTap: onRight),
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: active
            ? AppPalette.brandAccent
            : const Color(0xFF2C3E50),
        foregroundColor: active ? Colors.white : const Color(0xFFBDC3C7),
        side: BorderSide(
          color: active ? AppPalette.brandAccent : const Color(0xFF7F8C8D),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Text(label),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(42, 34),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(label),
    );
  }
}

class _TraceCheck extends StatelessWidget {
  const _TraceCheck({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }
}

class _TextValueField extends StatefulWidget {
  const _TextValueField({
    required this.label,
    required this.value,
    required this.helper,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String helper;
  final ValueChanged<String> onChanged;

  @override
  State<_TextValueField> createState() => _TextValueFieldState();
}

class _TextValueFieldState extends State<_TextValueField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: widget.label,
          helperText: widget.helper,
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

class _NumberValueField extends StatefulWidget {
  const _NumberValueField({
    required this.label,
    required this.value,
    required this.helper,
    required this.onChanged,
    this.decimals = 3,
  });

  final String label;
  final double value;
  final String helper;
  final int decimals;
  final ValueChanged<double> onChanged;

  @override
  State<_NumberValueField> createState() => _NumberValueFieldState();
}

class _NumberValueFieldState extends State<_NumberValueField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _NumberValueField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.value != widget.value) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: widget.label,
          helperText: widget.helper.isEmpty ? null : widget.helper,
        ),
        onChanged: (raw) {
          final parsed = double.tryParse(raw.replaceAll(',', '.'));
          if (parsed != null) widget.onChanged(parsed);
        },
      ),
    );
  }

  String _format(double value) {
    if (widget.decimals == 0) return value.round().toString();
    return value.toStringAsFixed(widget.decimals);
  }
}

List<SignalPoint> _points(List<double> time, List<double> values) {
  return [
    for (var i = 0; i < time.length && i < values.length; i++)
      SignalPoint(time[i], values[i]),
  ];
}
