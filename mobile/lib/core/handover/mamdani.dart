import 'dart:math';

import 'models.dart';

class GaussianMembership {
  final double center;
  final double sigma;
  GaussianMembership(this.center, this.sigma) {
    requireFinite('center', center, minimum: 0, maximum: 1);
    requireFinite('sigma', sigma, minimum: 0);
    if (sigma == 0) throw ArgumentError('Sigma harus positif');
  }
  double degree(double x) {
    requireFinite('input', x, minimum: 0, maximum: 1);
    final distance = (x - center) / sigma;
    return exp(-.5 * distance * distance);
  }
}

class FuzzyRule {
  final List<int> antecedents;
  final int consequent;
  FuzzyRule(List<int> antecedents, this.consequent)
    : antecedents = List.unmodifiable(antecedents);
}

/// AND=min, implication=min, aggregation=max, centroid on [0, 1].
class MamdaniSystem {
  final List<List<GaussianMembership>> inputs;
  final List<GaussianMembership> outputs;
  final List<FuzzyRule> rules;
  final int integrationSteps;

  MamdaniSystem({
    required List<List<GaussianMembership>> inputs,
    required List<GaussianMembership> outputs,
    required List<FuzzyRule> rules,
    this.integrationSteps = 400,
  }) : inputs = List.unmodifiable(
         inputs.map((s) => List<GaussianMembership>.unmodifiable(s)),
       ),
       outputs = List.unmodifiable(outputs),
       rules = List.unmodifiable(rules) {
    if (inputs.isEmpty ||
        inputs.any((s) => s.isEmpty) ||
        outputs.isEmpty ||
        rules.isEmpty ||
        integrationSteps < 20) {
      throw ArgumentError('Konfigurasi Mamdani tidak lengkap');
    }
    for (final rule in rules) {
      if (rule.antecedents.length != inputs.length ||
          rule.consequent < 0 ||
          rule.consequent >= outputs.length)
        throw ArgumentError('Aturan fuzzy tidak valid');
      for (var i = 0; i < inputs.length; i++) {
        if (rule.antecedents[i] < 0 ||
            rule.antecedents[i] >= inputs[i].length) {
          throw ArgumentError('Indeks antecedent tidak valid');
        }
      }
    }
  }

  double evaluate(List<double> values) {
    if (values.length != inputs.length)
      throw ArgumentError('Jumlah input FIS tidak sesuai');
    final degrees = [
      for (var i = 0; i < inputs.length; i++)
        [for (final mf in inputs[i]) mf.degree(values[i])],
    ];
    final activations = List<double>.filled(outputs.length, 0);
    for (final rule in rules) {
      var strength = 1.0;
      for (var i = 0; i < inputs.length; i++) {
        strength = min(strength, degrees[i][rule.antecedents[i]]);
      }
      activations[rule.consequent] = max(
        activations[rule.consequent],
        strength,
      );
    }
    var numerator = 0.0;
    var denominator = 0.0;
    for (var step = 0; step <= integrationSteps; step++) {
      final x = step / integrationSteps;
      var aggregated = 0.0;
      for (var i = 0; i < outputs.length; i++) {
        aggregated = max(aggregated, min(activations[i], outputs[i].degree(x)));
      }
      final trapezoid = step == 0 || step == integrationSteps ? .5 : 1.0;
      numerator += x * aggregated * trapezoid;
      denominator += aggregated * trapezoid;
    }
    if (denominator == 0) throw StateError('Tidak ada aturan fuzzy yang aktif');
    return unitInterval(numerator / denominator);
  }
}

List<GaussianMembership> evenlySpacedMemberships(int count) => [
  for (var i = 0; i < count; i++)
    GaussianMembership(i / (count - 1), .45 / (count - 1)),
];

/// Samples Mamdani on a regular grid, then builds a monotone
/// envelope. Multilinear interpolation preserves the envelope's order
/// between nodes. This calibration is a project adaptation, not raw inference.
class MonotoneMamdaniSurface {
  final MamdaniSystem system;
  final List<bool> increasing;
  final bool lowerEnvelope;
  late final List<int> _segments;
  late final List<int> _strides;
  late final List<double> _values;

  MonotoneMamdaniSurface(
    this.system, {
    required List<bool> increasing,
    this.lowerEnvelope = true,
  }) : increasing = List.unmodifiable(increasing) {
    if (increasing.length != system.inputs.length) {
      throw ArgumentError('Arah kalibrasi harus sesuai jumlah input');
    }
    _segments = [
      for (final labels in system.inputs) max(12, 2 * (labels.length - 1)),
    ];
    _strides = List<int>.filled(_segments.length, 1);
    for (var axis = _segments.length - 2; axis >= 0; axis--) {
      _strides[axis] = _strides[axis + 1] * (_segments[axis + 1] + 1);
    }
    final size = (_segments.first + 1) * _strides.first;
    _values = List<double>.generate(
      size,
      (index) => system.evaluate([
        for (var axis = 0; axis < _segments.length; axis++)
          ((index ~/ _strides[axis]) % (_segments[axis] + 1)) / _segments[axis],
      ]),
    );

    // Lower envelope: high-output to low-output, taking min.
    // Upper envelope: low-output to high-output, taking max.
    // Both sweeps preserve the order already established on other axes.
    for (var axis = 0; axis < _segments.length; axis++) {
      final stride = _strides[axis];
      final count = _segments[axis] + 1;
      for (var index = 0; index < size; index++) {
        if ((index ~/ stride) % count != 0) continue;
        final backwards = lowerEnvelope == increasing[axis];
        var previous = index + (backwards ? count - 1 : 0) * stride;
        for (var step = 1; step < count; step++) {
          final current = previous + (backwards ? -stride : stride);
          _values[current] = lowerEnvelope
              ? min(_values[current], _values[previous])
              : max(_values[current], _values[previous]);
          previous = current;
        }
      }
    }
  }

  double evaluate(List<double> inputs) {
    if (inputs.length != _segments.length)
      throw ArgumentError('Jumlah input kalibrasi tidak sesuai');
    final lower = <int>[];
    final fractions = <double>[];
    for (var axis = 0; axis < inputs.length; axis++) {
      requireFinite('input', inputs[axis], minimum: 0, maximum: 1);
      final position = inputs[axis] * _segments[axis];
      final base = min(position.floor(), _segments[axis] - 1);
      lower.add(base);
      fractions.add(position - base);
    }
    double interpolate(int axis, int index, double weight) {
      if (axis == inputs.length) return weight * _values[index];
      final base = index + lower[axis] * _strides[axis];
      final fraction = fractions[axis];
      return interpolate(axis + 1, base, weight * (1 - fraction)) +
          interpolate(axis + 1, base + _strides[axis], weight * fraction);
    }

    return unitInterval(interpolate(0, 0, 1));
  }
}
