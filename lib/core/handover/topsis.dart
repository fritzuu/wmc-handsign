import 'dart:math';

import 'configuration.dart';
import 'models.dart';

class TopsisRanker {
  List<NetworkRank> rank(
    List<NetworkSnapshot> networks,
    CriterionWeights weights, {
    String? preferredNetworkId,
  }) {
    final available = networks.where((n) => n.available).toList();
    final ids = <String>{};
    for (final n in networks) {
      if (!ids.add(n.id)) throw ArgumentError('ID jaringan duplikat: ${n.id}');
    }
    if (available.isEmpty) return const [];
    final matrix = [
      for (final n in available) [n.dataRateMbps, n.delayMs, n.ber],
    ];
    final weighted = List.generate(
      available.length,
      (_) => List<double>.filled(3, 0),
    );
    for (var j = 0; j < 3; j++) {
      // Scale before squaring to avoid overflow/underflow in vector norms.
      final scale = matrix.map((row) => row[j]).reduce(max);
      if (scale == 0) continue;
      final norm = sqrt(
        matrix.fold<double>(
          0,
          (sum, row) => sum + pow(row[j] / scale, 2).toDouble(),
        ),
      );
      for (var i = 0; i < available.length; i++) {
        weighted[i][j] = (matrix[i][j] / scale) / norm * weights.values[j];
      }
    }
    final ideal = List<double>.filled(3, 0);
    final worst = List<double>.filled(3, 0);
    for (var j = 0; j < 3; j++) {
      final column = weighted.map((row) => row[j]);
      ideal[j] = j == 0 ? column.reduce(max) : column.reduce(min);
      worst[j] = j == 0 ? column.reduce(min) : column.reduce(max);
    }
    final ranks = <NetworkRank>[];
    for (var i = 0; i < available.length; i++) {
      var positive = 0.0;
      var negative = 0.0;
      for (var j = 0; j < 3; j++) {
        positive += pow(weighted[i][j] - ideal[j], 2).toDouble();
        negative += pow(weighted[i][j] - worst[j], 2).toDouble();
      }
      final dPlus = sqrt(positive);
      final dMinus = sqrt(negative);
      final score = dPlus + dMinus == 0 ? .5 : dMinus / (dPlus + dMinus);
      ranks.add(NetworkRank(available[i].id, score));
    }
    ranks.sort((a, b) {
      if (a.networkId == b.networkId) return 0;
      final order = b.score.compareTo(a.score);
      if (order != 0) return order;
      if (a.networkId == preferredNetworkId) return -1;
      if (b.networkId == preferredNetworkId) return 1;
      return a.networkId.compareTo(b.networkId);
    });
    return List.unmodifiable(ranks);
  }
}
