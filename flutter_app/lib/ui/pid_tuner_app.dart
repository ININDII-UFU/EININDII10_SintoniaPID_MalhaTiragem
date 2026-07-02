import 'package:flutter/material.dart';

import '../application/tuning_session.dart';
import 'theme/app_palette.dart';
import 'theme/app_theme.dart';
import 'widgets/live_operation_panel.dart';

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
  late final List<_AnchorItem> _anchors;
  bool _leftOpen = true;
  bool _rightOpen = true;

  static const double _leftWidth = 248;
  static const double _rightWidth = 430;
  static const double _railWidth = 56;
  static const double _wideBreakpoint = 1120;

  final _operationAnchor = GlobalKey();
  final _resultsAnchor = GlobalKey();
  final _explanationAnchor = GlobalKey();

  @override
  void initState() {
    super.initState();
    _session = TuningSession();
    _anchors = [
      _AnchorItem(
        icon: Icons.settings_input_component,
        title: 'Operação',
        subtitle: 'Simulado ou Modbus',
        color: AppPalette.brandPrimary,
        anchorKey: _operationAnchor,
      ),
      _AnchorItem(
        icon: Icons.calculate_outlined,
        title: 'Resultados',
        subtitle: 'Sintonia e simulação',
        color: AppPalette.reaction,
        anchorKey: _resultsAnchor,
      ),
      _AnchorItem(
        icon: Icons.school_outlined,
        title: 'Como funciona',
        subtitle: 'Ziegler-Nichols',
        color: AppPalette.ultimate,
        anchorKey: _explanationAnchor,
      ),
    ];
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  void _scrollToAnchor(GlobalKey key) {
    final anchorContext = key.currentContext;
    if (anchorContext == null) return;
    Scrollable.ensureVisible(
      anchorContext,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
          drawer: useDrawers
              ? _SectionDrawer(anchors: _anchors, onSelect: _scrollToAnchor)
              : null,
          endDrawer: useDrawers
              ? Drawer(
                  backgroundColor: AppPalette.surface,
                  width: 390,
                  child: SafeArea(
                    child: OperationConfigPanel(session: _session),
                  ),
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
                                anchors: _anchors,
                                onSelect: _scrollToAnchor,
                                onCollapse: () =>
                                    setState(() => _leftOpen = false),
                              )
                            : _CollapsedRail(
                                icon: Icons.route_outlined,
                                label: 'ETAPAS',
                                onTap: () => setState(() => _leftOpen = true),
                              ),
                      ),
                    Expanded(
                      child: LiveOperationWorkspace(
                        session: _session,
                        operationKey: _operationAnchor,
                        resultsKey: _resultsAnchor,
                        explanationKey: _explanationAnchor,
                      ),
                    ),
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
                                    child: OperationConfigPanel(
                                      session: _session,
                                    ),
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

class _AnchorItem {
  const _AnchorItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.anchorKey,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final GlobalKey anchorKey;
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
                    'Operação · Modbus TCP · FOPDT · Ziegler-Nichols',
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
  const _LeftNav({
    required this.anchors,
    required this.onSelect,
    required this.onCollapse,
  });

  final List<_AnchorItem> anchors;
  final ValueChanged<GlobalKey> onSelect;
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
              for (final anchor in anchors)
                _NavTile(
                  icon: anchor.icon,
                  title: anchor.title,
                  subtitle: anchor.subtitle,
                  color: anchor.color,
                  onTap: () => onSelect(anchor.anchorKey),
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
  const _SectionDrawer({required this.anchors, required this.onSelect});

  final List<_AnchorItem> anchors;
  final ValueChanged<GlobalKey> onSelect;

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
                  for (final anchor in anchors)
                    _NavTile(
                      icon: anchor.icon,
                      title: anchor.title,
                      subtitle: anchor.subtitle,
                      color: anchor.color,
                      onTap: () {
                        Navigator.of(context).pop();
                        onSelect(anchor.anchorKey);
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
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
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
                    color: color.withValues(alpha: 0.10),
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
                        style: const TextStyle(
                          color: AppPalette.textSecondary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
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
