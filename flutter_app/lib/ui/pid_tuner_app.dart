import 'package:flutter/material.dart';

import '../application/tuning_session.dart';
import '../domain/simulation_models.dart';
import '../domain/tuning_models.dart';
import 'theme/app_palette.dart';
import 'theme/app_theme.dart';
import 'widgets/response_chart.dart';
import 'widgets/section_card.dart';

class PidTunerApp extends StatelessWidget {
  const PidTunerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sintonia PID Ziegler-Nichols',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const ShellPage(),
    );
  }
}

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  late final TuningSession _session;
  bool _leftOpen = true;
  bool _rightOpen = true;

  static const double _leftWidth = 248;
  static const double _rightWidth = 430;
  static const double _railWidth = 56;
  static const double _wideBreakpoint = 1120;

  @override
  void initState() {
    super.initState();
    _session = TuningSession();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > _wideBreakpoint;
    final useDrawers = !isWide;

    return AnimatedBuilder(
      animation: _session,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppPalette.background,
          drawer: useDrawers ? _SectionDrawer(session: _session) : null,
          endDrawer: useDrawers
              ? Drawer(
                  backgroundColor: AppPalette.surface,
                  width: 390,
                  child: SafeArea(child: _ConfigPanel(session: _session)),
                )
              : null,
          body: Column(
            children: [
              _AppHeader(
                useDrawers: useDrawers,
                leftOpen: _leftOpen,
                rightOpen: _rightOpen,
                onToggleLeft: () => setState(() => _leftOpen = !_leftOpen),
                onToggleRight: () => setState(() => _rightOpen = !_rightOpen),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isWide)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        width: _leftOpen ? _leftWidth : _railWidth,
                        decoration: const BoxDecoration(
                          color: AppPalette.surface,
                          border: Border(
                            right: BorderSide(color: AppPalette.border),
                          ),
                        ),
                        child: _leftOpen
                            ? _LeftNav(
                                session: _session,
                                onCollapse: () =>
                                    setState(() => _leftOpen = false),
                              )
                            : _CollapsedRail(
                                icon: Icons.route_outlined,
                                label: 'ETAPAS',
                                onTap: () => setState(() => _leftOpen = true),
                              ),
                      ),
                    Expanded(child: _Workspace(session: _session)),
                    if (isWide)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        width: _rightOpen ? _rightWidth : _railWidth,
                        decoration: const BoxDecoration(
                          color: AppPalette.surface,
                          border: Border(
                            left: BorderSide(color: AppPalette.border),
                          ),
                        ),
                        child: _rightOpen
                            ? Column(
                                children: [
                                  _RightHeader(
                                    onCollapse: () =>
                                        setState(() => _rightOpen = false),
                                  ),
                                  Expanded(
                                    child: _ConfigPanel(session: _session),
                                  ),
                                ],
                              )
                            : _CollapsedRail(
                                icon: Icons.tune,
                                label: 'ENTRADAS',
                                onTap: () => setState(() => _rightOpen = true),
                              ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader({
    required this.useDrawers,
    required this.leftOpen,
    required this.rightOpen,
    required this.onToggleLeft,
    required this.onToggleRight,
  });

  final bool useDrawers;
  final bool leftOpen;
  final bool rightOpen;
  final VoidCallback onToggleLeft;
  final VoidCallback onToggleRight;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppPalette.headerGradient),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Builder(
              builder: (ctx) => IconButton(
                tooltip: 'Etapas',
                icon: Icon(
                  useDrawers
                      ? Icons.menu
                      : (leftOpen ? Icons.chevron_left : Icons.menu_open),
                  color: Colors.white,
                ),
                onPressed: () =>
                    useDrawers ? Scaffold.of(ctx).openDrawer() : onToggleLeft(),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: const Icon(
                Icons.settings_input_component,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sintonia PID Ziegler-Nichols',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'FOPDT · Malha aberta · Ganho último · Simulação',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school_outlined, color: Colors.white, size: 14),
                  SizedBox(width: 5),
                  Text(
                    'LASEC · UFU',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Builder(
              builder: (ctx) => IconButton(
                tooltip: 'Entradas',
                icon: Icon(
                  useDrawers
                      ? Icons.tune
                      : (rightOpen ? Icons.chevron_right : Icons.tune),
                  color: Colors.white,
                ),
                onPressed: () => useDrawers
                    ? Scaffold.of(ctx).openEndDrawer()
                    : onToggleRight(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeftNav extends StatelessWidget {
  const _LeftNav({required this.session, required this.onCollapse});

  final TuningSession session;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppPalette.border)),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'ETAPAS',
                  style: TextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Esconder painel',
                onPressed: onCollapse,
                icon: const Icon(Icons.chevron_left),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            children: [
              for (final section in WorkspaceSection.values)
                _NavTile(
                  icon: _iconForSection(section),
                  title: section.label,
                  subtitle: section.subtitle,
                  color: _colorForSection(section),
                  selected: session.section == section,
                  onTap: () => session.selectSection(section),
                ),
              const SizedBox(height: 16),
              const _Footer(),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionDrawer extends StatelessWidget {
  const _SectionDrawer({required this.session});

  final TuningSession session;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppPalette.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: AppPalette.headerGradient,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_graph, color: Colors.white, size: 28),
                  SizedBox(height: 10),
                  Text(
                    'PID ZN Tuner',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Ensaios, sintonia e curvas',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  for (final section in WorkspaceSection.values)
                    _NavTile(
                      icon: _iconForSection(section),
                      title: section.label,
                      subtitle: section.subtitle,
                      color: _colorForSection(section),
                      selected: session.section == section,
                      onTap: () {
                        session.selectSection(section);
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? color.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: selected ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: selected
                              ? AppPalette.textPrimary
                              : AppPalette.textSecondary,
                          fontSize: 13.5,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppPalette.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RightHeader extends StatelessWidget {
  const _RightHeader({required this.onCollapse});

  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppPalette.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppPalette.brandPrimary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.tune,
              color: AppPalette.brandPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'ENTRADAS',
              style: TextStyle(
                color: AppPalette.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Esconder painel',
            onPressed: onCollapse,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _ConfigPanel extends StatefulWidget {
  const _ConfigPanel({required this.session});

  final TuningSession session;

  @override
  State<_ConfigPanel> createState() => _ConfigPanelState();
}

class _ConfigPanelState extends State<_ConfigPanel> {
  final _csvController = TextEditingController(
    text: '0,0\n1,0\n2,0.2\n3,0.65\n4,1.05\n5,1.35\n7,1.65\n10,1.86\n14,1.96',
  );

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        if (s.section == WorkspaceSection.reaction) ...[
          _ReactionInputs(session: s),
        ] else if (s.section == WorkspaceSection.ultimate) ...[
          _UltimateInputs(session: s),
        ] else ...[
          _SimulationInputs(session: s),
          const SizedBox(height: 12),
          _ImportPointsCard(session: s, controller: _csvController),
        ],
      ],
    );
  }
}

class _ReactionInputs extends StatelessWidget {
  const _ReactionInputs({required this.session});

  final TuningSession session;

  @override
  Widget build(BuildContext context) {
    final p = session.fopdt;
    return Column(
      children: [
        SectionCard(
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
        ),
        const SizedBox(height: 12),
        _RatioAdvice(parameters: p),
      ],
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

class _Workspace extends StatelessWidget {
  const _Workspace({required this.session});

  final TuningSession session;

  @override
  Widget build(BuildContext context) {
    final sim = session.simulation;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 760;
          return ListView(
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
          : Wrap(
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

class _CollapsedRail extends StatelessWidget {
  const _CollapsedRail({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: AppPalette.textSecondary, size: 20),
            const SizedBox(height: 12),
            RotatedBox(
              quarterTurns: 3,
              child: Text(
                label,
                style: const TextStyle(
                  color: AppPalette.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.school_outlined,
                size: 14,
                color: AppPalette.textMuted,
              ),
              SizedBox(width: 6),
              Text(
                'LASEC · UFU',
                style: TextStyle(
                  color: AppPalette.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Sintonia PID para processos industriais aproximados por FOPDT.',
            style: TextStyle(
              color: AppPalette.textMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _iconForSection(WorkspaceSection section) {
  switch (section) {
    case WorkspaceSection.reaction:
      return Icons.stacked_line_chart;
    case WorkspaceSection.ultimate:
      return Icons.waves;
    case WorkspaceSection.simulation:
      return Icons.auto_graph;
  }
}

Color _colorForSection(WorkspaceSection section) {
  switch (section) {
    case WorkspaceSection.reaction:
      return AppPalette.reaction;
    case WorkspaceSection.ultimate:
      return AppPalette.ultimate;
    case WorkspaceSection.simulation:
      return AppPalette.simulation;
  }
}

String _fmt(double value) {
  final a = value.abs();
  if (a >= 10000 || (a > 0 && a < 0.001)) return value.toStringAsExponential(3);
  if (a >= 100) return value.toStringAsFixed(2);
  if (a >= 10) return value.toStringAsFixed(3);
  return value.toStringAsFixed(4);
}
