import 'package:flutter/material.dart';

import '../../application/tuning_session.dart';
import '../../domain/modbus_models.dart';
import '../../domain/simulation_models.dart';
import '../../domain/tuning_models.dart';
import '../theme/app_palette.dart';
import 'response_chart.dart';
import 'section_card.dart';

/// Cartões de configuração de sintonia (Degrau, Oscilação, Simulação e
/// importação de CSV) exibidos no painel direito "ENTRADAS" da tela de
/// Operação, junto com a conexão Modbus e as variáveis da malha.
class TuningConfigCards extends StatelessWidget {
  const TuningConfigCards({
    super.key,
    required this.session,
    required this.csvController,
  });

  final TuningSession session;
  final TextEditingController csvController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ReactionInputs(session: session),
        const SizedBox(height: 12),
        _RatioAdvice(parameters: session.fopdt),
        const SizedBox(height: 12),
        _UltimateInputs(session: session),
        const SizedBox(height: 12),
        _SimulationInputs(session: session),
        const SizedBox(height: 12),
        _ImportPointsCard(session: session, controller: csvController),
      ],
    );
  }
}

/// Resultados de sintonia (P/PI/PID), curvas de simulação e métricas de
/// desempenho, exibidos abaixo do gráfico ao vivo na tela de Operação.
class TuningResultsSection extends StatelessWidget {
  const TuningResultsSection({super.key, required this.session});

  final TuningSession session;

  @override
  Widget build(BuildContext context) {
    final sim = session.simulation;
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 760;
        return Column(
          children: [
            _ResultsCard(session: session),
            const SizedBox(height: 14),
            if (narrow) ...[
              _MetricsCard(metrics: sim?.metrics),
              const SizedBox(height: 14),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _ChartsCard(session: session)),
                if (!narrow) ...[
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 260,
                    child: _MetricsCard(metrics: sim?.metrics),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ReactionInputs extends StatelessWidget {
  const _ReactionInputs({required this.session});

  final TuningSession session;

  @override
  Widget build(BuildContext context) {
    final p = session.fopdt;
    return SectionCard(
      title: 'MÉTODO DA REAÇÃO AO DEGRAU',
      icon: Icons.stacked_line_chart,
      accent: AppPalette.reaction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _InfoText(
            'Coloque a malha em manual, aplique um degrau conhecido na variável manipulada e registre a saída até estabilizar. O modelo aproximado é G(s)=K e^(-Ls)/(Ts+1).',
          ),
          const SizedBox(height: 12),
          _NumberField(
            label: 'Ganho K do processo',
            value: p.gain,
            helper:
                'Calcule K=(yf-y0)/Δu. Se um degrau de 10% alterou a PV em 5 unidades, K=5/0,10=50.',
            onChanged: (v) => session.updateFopdt(gain: v),
          ),
          _NumberField(
            label: 'Atraso morto L (s)',
            value: p.deadTime,
            helper:
                'Trace a tangente no ponto de maior inclinação. L é o tempo entre o degrau e o cruzamento dessa tangente com o valor inicial.',
            onChanged: (v) => session.updateFopdt(deadTime: v),
          ),
          _NumberField(
            label: 'Constante de tempo T (s)',
            value: p.timeConstant,
            helper:
                'T é a distância entre o cruzamento da tangente no valor inicial e o cruzamento no valor final.',
            onChanged: (v) => session.updateFopdt(timeConstant: v),
          ),
          const SizedBox(height: 8),
          _MethodButton(
            selected: session.method == TuningMethod.reactionCurve,
            label: 'Usar K, L e T na sintonia',
            onPressed: () => session.setMethod(TuningMethod.reactionCurve),
          ),
        ],
      ),
    );
  }
}

class _UltimateInputs extends StatelessWidget {
  const _UltimateInputs({required this.session});

  final TuningSession session;

  @override
  Widget build(BuildContext context) {
    final p = session.ultimate;
    return SectionCard(
      title: 'MÉTODO DO GANHO ÚLTIMO',
      icon: Icons.waves,
      accent: AppPalette.ultimate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _InfoText(
            'Zere as ações I e D, deixe apenas controle proporcional e aumente Kp até obter oscilações sustentadas. Esse ganho é Ku; o tempo entre dois picos consecutivos é Pu.',
          ),
          const SizedBox(height: 12),
          _NumberField(
            label: 'Ganho último Ku',
            value: p.ku,
            helper:
                'Use o Kp que mantém oscilações com amplitude aproximadamente constante.',
            onChanged: (v) => session.updateUltimate(ku: v),
          ),
          _NumberField(
            label: 'Período último Pu (s)',
            value: p.pu,
            helper:
                'Meça o intervalo médio entre picos sucessivos da PV durante a oscilação sustentada.',
            onChanged: (v) => session.updateUltimate(pu: v),
          ),
          const SizedBox(height: 8),
          _MethodButton(
            selected: session.method == TuningMethod.ultimateGain,
            label: 'Usar Ku e Pu na sintonia',
            onPressed: () => session.setMethod(TuningMethod.ultimateGain),
          ),
        ],
      ),
    );
  }
}

class _SimulationInputs extends StatelessWidget {
  const _SimulationInputs({required this.session});

  final TuningSession session;

  @override
  Widget build(BuildContext context) {
    final st = session.settings;
    return SectionCard(
      title: 'SIMULAÇÃO E AJUSTE FINO',
      icon: Icons.tune,
      accent: AppPalette.simulation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Controlador para as curvas',
            style: TextStyle(
              color: AppPalette.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final kind in ControllerKind.values)
                ChoiceChip(
                  label: Text(kind.label),
                  selected: session.controllerKind == kind,
                  onSelected: (_) => session.setControllerKind(kind),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _NumberField(
            label: 'Setpoint da simulação',
            value: st.setpoint,
            helper: 'Valor desejado para a PV no ensaio de malha fechada.',
            onChanged: (v) => session.updateSettings(setpoint: v),
          ),
          _NumberField(
            label: 'Degrau da entrada em malha aberta Δu',
            value: st.stepAmplitude,
            helper:
                'Usado para desenhar a resposta sem controle e para identificar K a partir de pontos colados.',
            onChanged: (v) => session.updateSettings(stepAmplitude: v),
          ),
          _NumberField(
            label: 'Tempo total (s)',
            value: st.duration,
            helper: 'Use tempo suficiente para ver overshoot e acomodação.',
            onChanged: (v) => session.updateSettings(duration: v),
          ),
          _NumberField(
            label: 'Passo numérico dt (s)',
            value: st.dt,
            helper:
                'Valores menores dão curvas mais suaves. Uma regra prática é dt ≤ min(L,T)/20.',
            onChanged: (v) => session.updateSettings(dt: v),
          ),
          _NumberField(
            label: 'Fator nos ganhos',
            value: st.gainScale,
            helper:
                'Use 0,7 ou 0,5 para suavizar ZN quando houver muito overshoot.',
            onChanged: (v) => session.updateSettings(gainScale: v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Derivada no erro'),
            subtitle: const Text('Desligado calcula a derivada na saída.'),
            value: st.derivativeOnError,
            onChanged: (v) => session.updateSettings(derivativeOnError: v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Saturar variável manipulada'),
            value: st.useSaturation,
            onChanged: (v) => session.updateSettings(useSaturation: v),
          ),
          if (st.useSaturation) ...[
            _NumberField(
              label: 'MV mínima',
              value: st.minOutput,
              helper: 'Limite inferior do atuador.',
              onChanged: (v) => session.updateSettings(minOutput: v),
            ),
            _NumberField(
              label: 'MV máxima',
              value: st.maxOutput,
              helper: 'Limite superior do atuador.',
              onChanged: (v) => session.updateSettings(maxOutput: v),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImportPointsCard extends StatelessWidget {
  const _ImportPointsCard({required this.session, required this.controller});

  final TuningSession session;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'PONTOS DO ENSAIO',
      icon: Icons.table_chart_outlined,
      accent: AppPalette.brandAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _InfoText(
            'Cole duas colunas: tempo e saída. Separadores aceitos: vírgula, ponto e vírgula, tabulação ou espaço. Depois carregue os pontos para comparar com a simulação.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: 6,
            maxLines: 9,
            decoration: const InputDecoration(
              labelText: 'CSV tempo, saída',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => session.loadPoints(controller.text),
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Carregar pontos'),
              ),
              OutlinedButton.icon(
                onPressed: session.importedPoints.isEmpty
                    ? null
                    : session.identifyFromImportedPoints,
                icon: const Icon(Icons.auto_fix_high, size: 18),
                label: const Text('Estimar K, L, T'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            session.importMessage,
            style: const TextStyle(
              color: AppPalette.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsCard extends StatelessWidget {
  const _ResultsCard({required this.session});

  final TuningSession session;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'VALORES DE SINTONIA',
      icon: Icons.calculate_outlined,
      accent: AppPalette.brandPrimary,
      trailing: Text(
        session.method.shortLabel,
        style: const TextStyle(
          color: AppPalette.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
      child: session.results.isEmpty
          ? const Text('Informe valores válidos para calcular a sintonia.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final result in session.results)
                      _TuningResultTile(
                        result: result,
                        selected: session.controllerKind == result.kind,
                        scale: session.settings.gainScale,
                        onTap: () => session.setControllerKind(result.kind),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                _SendToPlcButton(session: session),
              ],
            ),
    );
  }
}

class _SendToPlcButton extends StatelessWidget {
  const _SendToPlcButton({required this.session});

  final TuningSession session;

  @override
  Widget build(BuildContext context) {
    final canSend =
        session.processSource == ProcessSource.modbus &&
        session.modbusConnected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton.icon(
          onPressed: canSend ? session.sendTuningToPlc : null,
          icon: const Icon(Icons.send, size: 18),
          label: const Text('Enviar Kp/Ti/Td ao CLP'),
        ),
        if (!canSend) ...[
          const SizedBox(height: 6),
          const _InfoText(
            'Conecte ao Modbus para gravar o resultado selecionado nos '
            'pontos Kp, Ki (Ti) e Kd (Td).',
          ),
        ],
      ],
    );
  }
}

class _TuningResultTile extends StatelessWidget {
  const _TuningResultTile({
    required this.result,
    required this.selected,
    required this.scale,
    required this.onTap,
  });

  final TuningResult result;
  final bool selected;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gains = result.gains.scaled(scale);
    return SizedBox(
      width: 238,
      child: Material(
        color: selected
            ? AppPalette.brandPrimary.withValues(alpha: 0.08)
            : AppPalette.surfaceAlt.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? AppPalette.brandPrimary : AppPalette.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        result.kind.label,
                        style: const TextStyle(
                          color: AppPalette.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (selected)
                      const Icon(
                        Icons.check_circle,
                        color: AppPalette.brandPrimary,
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _Kv('Kp', gains.kp),
                _Kv('Ki', gains.ki),
                _Kv('Kd', gains.kd),
                const Divider(height: 14),
                _Kv('Ti', result.gains.ti),
                _Kv('Td', result.gains.td),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Kv extends StatelessWidget {
  const _Kv(this.label, this.value);

  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              label,
              style: const TextStyle(
                color: AppPalette.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value == null ? '-' : _fmt(value!),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppPalette.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartsCard extends StatelessWidget {
  const _ChartsCard({required this.session});

  final TuningSession session;

  @override
  Widget build(BuildContext context) {
    final sim = session.simulation;
    final pvSeries = <ChartSeries>[
      if (sim != null)
        ChartSeries(
          label: 'SP',
          points: sim.asPoints(sim.setpoint),
          color: AppPalette.textPrimary,
          dashed: true,
        ),
      if (sim != null)
        ChartSeries(
          label: 'Malha aberta',
          points: sim.asPoints(sim.openLoop),
          color: AppPalette.reaction,
          dashed: true,
        ),
      if (sim != null)
        ChartSeries(
          label: 'PV PID',
          points: sim.asPoints(sim.closedLoop),
          color: AppPalette.brandAccent,
        ),
      if (session.importedPoints.isNotEmpty)
        ChartSeries(
          label: 'Pontos',
          points: session.importedPoints,
          color: AppPalette.textPrimary,
          dots: true,
        ),
    ];
    final mvSeries = <ChartSeries>[
      if (sim != null)
        ChartSeries(
          label: 'MV',
          points: sim.asPoints(sim.manipulated),
          color: AppPalette.ultimate,
        ),
    ];

    return SectionCard(
      title: 'CURVAS',
      icon: Icons.show_chart,
      accent: AppPalette.brandAccent,
      child: Column(
        children: [
          ResponseChart(
            title: 'Resposta do processo',
            xLabel: 'Tempo (s)',
            yLabel: 'PV',
            height: 330,
            series: pvSeries,
          ),
          const SizedBox(height: 14),
          ResponseChart(
            title: 'Variável manipulada',
            xLabel: 'Tempo (s)',
            yLabel: 'MV',
            height: 220,
            series: mvSeries,
          ),
        ],
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.metrics});

  final ResponseMetrics? metrics;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    return SectionCard(
      title: 'DESEMPENHO',
      icon: Icons.speed,
      accent: AppPalette.warning,
      child: m == null
          ? const Text('Sem simulação válida.')
          : Column(
              children: [
                _MetricTile(
                  'Overshoot',
                  '${m.overshootPercent.toStringAsFixed(1)} %',
                ),
                _MetricTile(
                  'Acomodação 2%',
                  m.settlingTime == null
                      ? 'não atingiu'
                      : '${m.settlingTime!.toStringAsFixed(2)} s',
                ),
                _MetricTile('Erro final', _fmt(m.steadyStateError)),
                _MetricTile('IAE', _fmt(m.iae)),
              ],
            ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppPalette.textSecondary),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.helper,
    required this.onChanged,
  });

  final String label;
  final double value;
  final String helper;
  final ValueChanged<double> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _fmt(widget.value));
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.value != widget.value) {
      _controller.text = _fmt(widget.value);
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
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          helperText: widget.helper,
        ),
        onChanged: (raw) {
          final parsed = double.tryParse(raw.replaceAll(',', '.'));
          if (parsed != null && parsed.isFinite) widget.onChanged(parsed);
        },
      ),
    );
  }
}

class _MethodButton extends StatelessWidget {
  const _MethodButton({
    required this.selected,
    required this.label,
    required this.onPressed,
  });

  final bool selected;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: selected
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.check, size: 18),
              label: Text(label),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: Text(label),
            ),
    );
  }
}

class _RatioAdvice extends StatelessWidget {
  const _RatioAdvice({required this.parameters});

  final FopdtParameters parameters;

  @override
  Widget build(BuildContext context) {
    final ratio = parameters.timeConstant == 0 ? 0 : parameters.delayRatio;
    final ok = ratio >= 0.2 && ratio <= 0.4;
    return SectionCard(
      title: 'VALIDADE PRÁTICA',
      icon: ok ? Icons.verified_outlined : Icons.warning_amber_outlined,
      accent: ok ? AppPalette.success : AppPalette.warning,
      child: Text(
        'L/T = ${ratio.toStringAsFixed(3)}. '
        '${ok ? 'Faixa muito compatível com a recomendação didática 0,2 < L/T < 0,4.' : 'ZN ainda pode ser usado como ponto inicial, mas considere reduzir Kp ou usar ganho parcial se a resposta oscilar demais.'}',
        style: const TextStyle(color: AppPalette.textSecondary, height: 1.45),
      ),
    );
  }
}

class _InfoText extends StatelessWidget {
  const _InfoText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppPalette.textSecondary,
        fontSize: 12.5,
        height: 1.45,
      ),
    );
  }
}

String _fmt(double value) {
  final a = value.abs();
  if (a >= 10000 || (a > 0 && a < 0.001)) return value.toStringAsExponential(3);
  if (a >= 100) return value.toStringAsFixed(2);
  if (a >= 10) return value.toStringAsFixed(3);
  return value.toStringAsFixed(4);
}
