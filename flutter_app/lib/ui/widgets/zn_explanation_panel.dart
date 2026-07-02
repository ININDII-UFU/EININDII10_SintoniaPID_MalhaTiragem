import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'section_card.dart';

/// Conteúdo didático explicando o método de Ziegler-Nichols da curva de
/// reação (malha aberta), baseado no infográfico `assets/geral.png`.
///
/// É puramente informativo: não depende de [TuningSession] nem de nenhum
/// outro estado do app, o que permite reutilizá-lo/testá-lo isoladamente.
class ZieglerNicholsExplanationSection extends StatelessWidget {
  const ZieglerNicholsExplanationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'COMO FUNCIONA — ZIEGLER-NICHOLS (CURVA DE REAÇÃO)',
          style: TextStyle(
            color: AppPalette.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0.4,
          ),
        ),
        SizedBox(height: 12),
        _PlantModelCard(),
        SizedBox(height: 12),
        _ParameterMeaningCard(),
        SizedBox(height: 12),
        _CalculateGainCard(),
        SizedBox(height: 12),
        _StepByStepCard(),
        SizedBox(height: 12),
        _NumericExampleCard(),
        SizedBox(height: 12),
        _ZieglerNicholsTableCard(),
        SizedBox(height: 12),
        _KiTdRelationCard(),
        SizedBox(height: 12),
        _NotesCard(),
      ],
    );
  }
}

class _PlantModelCard extends StatelessWidget {
  const _PlantModelCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'MODELO DA PLANTA CONSIDERADO',
      icon: Icons.functions,
      accent: AppPalette.brandPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _InfoText('Planta de primeira ordem com atraso (FOPDT):'),
          const SizedBox(height: 8),
          const _FormulaBox('Gp(s) = K · e^(−L·s) / (T·s + 1)'),
          const SizedBox(height: 10),
          const _InfoText(
            'K = ganho do processo (variação de saída em regime / variação '
            'de entrada)\nL = tempo morto (atraso puro)\nT = constante de '
            'tempo (dinâmica do processo)',
          ),
        ],
      ),
    );
  }
}

class _ParameterMeaningCard extends StatelessWidget {
  const _ParameterMeaningCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'SIGNIFICADO DOS PARÂMETROS',
      icon: Icons.info_outline,
      accent: AppPalette.success,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Bullet('K', 'Inclinação estática da resposta em regime.'),
          _Bullet('L', 'Atraso entre a entrada e o início da resposta.'),
          _Bullet(
            'T',
            'Tempo necessário para a saída atingir 63,2% do valor final '
                'após o atraso.',
          ),
        ],
      ),
    );
  }
}

class _CalculateGainCard extends StatelessWidget {
  const _CalculateGainCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'COMO CALCULAR K',
      icon: Icons.calculate_outlined,
      accent: AppPalette.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _InfoText(
            '1. Aplique um degrau de amplitude Δu na entrada.\n'
            '2. Aguarde a saída estabilizar em yfinal.\n'
            '3. Calcule o ganho do processo:',
          ),
          const SizedBox(height: 8),
          const _FormulaBox('K = Δy / Δu = (yfinal − yinicial) / Δu'),
          const SizedBox(height: 8),
          const _InfoText(
            'Δy = variação total da saída\nΔu = amplitude do degrau '
            'aplicado na entrada',
          ),
        ],
      ),
    );
  }
}

class _StepByStepCard extends StatelessWidget {
  const _StepByStepCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'PASSO A PASSO PARA OBTER L E T',
      icon: Icons.checklist,
      accent: AppPalette.ultimate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Step(1, 'Aplique um degrau na entrada do processo.'),
          const _Step(
            2,
            'Aguarde a saída estabilizar em um novo valor (yfinal).',
          ),
          const _Step(3, 'Desenhe a curva da saída ao longo do tempo.'),
          const _Step(
            4,
            'Identifique o ponto de inflexão (maior inclinação) da curva.',
          ),
          const _Step(
            5,
            'Trace a reta tangente à curva nesse ponto e prolongue-a até '
                'interceptar o nível inicial (0%) — o tempo nesse ponto é '
                'o tempo morto L.',
          ),
          const _Step(
            6,
            'No gráfico, localize o tempo em que a saída atinge 63,2% do '
                'valor final — o intervalo entre t0 e esse ponto é a '
                'constante de tempo T.',
          ),
          const SizedBox(height: 6),
          const _InfoText(
            'Resumo: L = intervalo entre o instante do degrau (t=0) e o '
            'início da resposta (interseção da tangente com 0%). T = '
            'intervalo entre t0 e o instante em que y = 63,2% de yfinal. '
            'A mesma reta tangente pode ser desenhada direto no gráfico ao '
            'vivo da tela de Operação com a ferramenta "Tangente".',
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset('assets/FOPDT_aproximation.png'),
          ),
        ],
      ),
    );
  }
}

class _NumericExampleCard extends StatelessWidget {
  const _NumericExampleCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'EXEMPLO NUMÉRICO',
      icon: Icons.pin_outlined,
      accent: AppPalette.brandSecondary,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoText(
            'Dados medidos do gráfico: Δu = 10 (unid. de entrada); '
            'yinicial = 20; yfinal = 70; t0 (interseção) = 2,0 s; '
            't63 (63,2%) = 10,0 s.',
          ),
          SizedBox(height: 8),
          _InfoText(
            'Δy = yfinal − yinicial = 70 − 20 = 50\n'
            'K = Δy/Δu = 50/10 = 5 (unid. saída / unid. entrada)\n'
            'L = t0 = 2,0 s\n'
            'T = t63 − t0 = 10,0 − 2,0 = 8,0 s',
          ),
        ],
      ),
    );
  }
}

class _ZieglerNicholsTableCard extends StatelessWidget {
  const _ZieglerNicholsTableCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'TABELA DE ZIEGLER-NICHOLS (CURVA DE REAÇÃO)',
      icon: Icons.table_chart_outlined,
      accent: AppPalette.brandPrimary,
      child: Table(
        border: TableBorder.all(color: AppPalette.border),
        columnWidths: const {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(1.3),
          2: FlexColumnWidth(1.3),
          3: FlexColumnWidth(1.3),
        },
        children: [
          _TableHeaderRow(['Controlador', 'Kp', 'Ti', 'Td']),
          _TableDataRow(['P', 'T / (K·L)', '—', '—']),
          _TableDataRow(['PI', '0,9 · T / (K·L)', '3,33 · L', '—']),
          _TableDataRow(['PID', '1,2 · T / (K·L)', '2 · L', '0,5 · L']),
        ],
      ),
    );
  }
}

class _KiTdRelationCard extends StatelessWidget {
  const _KiTdRelationCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'RELAÇÃO Ki ↔ Ti E Kd ↔ Td NA SIMULAÇÃO',
      icon: Icons.sync_alt,
      accent: AppPalette.simulation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _InfoText(
            'A maioria dos controladores de campo grava a sintonia como Kp, '
            'Ti (tempo integral) e Td (tempo derivativo), não como Kp, Ki e '
            'Kd. Por isso, nesta tela, os pontos Modbus "Ki (Ti)" e '
            '"Kd (Td)" armazenam na verdade Ti e Td — é essa conversão que '
            'a simulação e o envio de sintonia ao CLP usam por baixo dos '
            'panos.',
          ),
          const SizedBox(height: 8),
          const _FormulaBox('Ti = Kp / Ki      Td = Kd / Kp'),
          const SizedBox(height: 8),
          const _InfoText(
            'Se Ki = 0 (controlador P, sem ação integral), Ti fica '
            'indefinido e nada é gravado no ponto "Ki (Ti)". O mesmo vale '
            'para Kd = 0 no ponto "Kd (Td)" — é o caso dos controladores P '
            'e PI na tabela acima.',
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'OBSERVAÇÕES',
      icon: Icons.warning_amber_outlined,
      accent: AppPalette.warning,
      child: const _InfoText(
        '• Este método fornece um ponto de partida — ajustes finos '
        'geralmente são necessários.\n'
        '• Indicado para processos que podem ser aproximados por um '
        'modelo de 1ª ordem com atraso (FOPDT).\n'
        '• Produz resposta rápida, porém com maior sobressinal.\n'
        '• Em processos com grande atraso ou não linearidade, considere '
        'outros métodos (Cohen-Coon, IMC, etc.).',
      ),
    );
  }
}

class _FormulaBox extends StatelessWidget {
  const _FormulaBox(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppPalette.surfaceAlt,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppPalette.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppPalette.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.label, this.description);

  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Text(
              label,
              style: const TextStyle(
                color: AppPalette.brandPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                color: AppPalette.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.number, this.text);

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppPalette.ultimate,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppPalette.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeaderRow extends TableRow {
  _TableHeaderRow(List<String> cells)
    : super(
        decoration: const BoxDecoration(color: AppPalette.brandPrimary),
        children: [
          for (final cell in cells)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              child: Text(
                cell,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
        ],
      );
}

class _TableDataRow extends TableRow {
  _TableDataRow(List<String> cells)
    : super(
        children: [
          for (var i = 0; i < cells.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              child: Text(
                cells[i],
                style: TextStyle(
                  color: AppPalette.textPrimary,
                  fontWeight: i == 0 ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 12.5,
                ),
              ),
            ),
        ],
      );
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
