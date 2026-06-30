import 'signal_point.dart';
import 'tuning_models.dart';

class ImportedStepData {
  const ImportedStepData({
    required this.points,
    required this.identified,
    required this.message,
  });

  final List<SignalPoint> points;
  final FopdtParameters? identified;
  final String message;
}

abstract class PointParser {
  List<SignalPoint> parse(String raw);
}

class CsvPointParser implements PointParser {
  const CsvPointParser();

  @override
  List<SignalPoint> parse(String raw) {
    final points = <SignalPoint>[];
    for (final line in raw.split(RegExp(r'\r?\n'))) {
      final cleaned = line.trim();
      if (cleaned.isEmpty) continue;
      final parts = cleaned
          .split(RegExp(r'[;\t, ]+'))
          .where((part) => part.trim().isNotEmpty)
          .toList();
      if (parts.length < 2) continue;
      final t = _parseNumber(parts[0]);
      final y = _parseNumber(parts[1]);
      if (t == null || y == null) continue;
      points.add(SignalPoint(t, y));
    }
    points.sort((a, b) => a.t.compareTo(b.t));
    return points;
  }

  double? _parseNumber(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }
}

abstract class FopdtIdentifier {
  FopdtParameters? identify(List<SignalPoint> points, double stepAmplitude);
}

class TangentFopdtIdentifier implements FopdtIdentifier {
  const TangentFopdtIdentifier();

  @override
  FopdtParameters? identify(List<SignalPoint> points, double stepAmplitude) {
    if (points.length < 6 || stepAmplitude == 0) return null;
    final ordered = [...points]..sort((a, b) => a.t.compareTo(b.t));
    final initialCount = (ordered.length * 0.08).ceil().clamp(
      1,
      ordered.length,
    );
    final finalCount = (ordered.length * 0.15).ceil().clamp(1, ordered.length);
    final y0 = _average(ordered.take(initialCount).map((p) => p.y));
    final yf = _average(
      ordered.skip(ordered.length - finalCount).map((p) => p.y),
    );
    final deltaY = yf - y0;
    if (deltaY.abs() < 1e-9) return null;
    final direction = deltaY.sign;

    var bestIndex = 1;
    var bestSlope = double.negativeInfinity;
    for (var i = 1; i < ordered.length; i++) {
      final dt = ordered[i].t - ordered[i - 1].t;
      if (dt <= 0) continue;
      final slope = (ordered[i].y - ordered[i - 1].y) / dt;
      final directedSlope = slope * direction;
      if (directedSlope > bestSlope) {
        bestSlope = directedSlope;
        bestIndex = i;
      }
    }

    final p = ordered[bestIndex];
    final previous = ordered[bestIndex - 1];
    final slope = (p.y - previous.y) / (p.t - previous.t);
    if (slope.abs() < 1e-9) return null;

    final l = p.t - (p.y - y0) / slope;
    final finalCross = p.t + (yf - p.y) / slope;
    final t = finalCross - l;
    final gain = deltaY / stepAmplitude;
    if (!gain.isFinite || !l.isFinite || !t.isFinite || t <= 0) return null;

    return FopdtParameters(
      gain: gain,
      deadTime: l < 0 ? 0.0 : l,
      timeConstant: t,
    );
  }

  double _average(Iterable<double> values) {
    final list = values.toList();
    return list.reduce((a, b) => a + b) / list.length;
  }
}
