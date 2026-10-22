import 'dart:convert';

import '../lib/core/handover/handover.dart';

void main() {
  final engine = HandoverDecisionEngine();
  final result = engine.evaluate(
    trafficClass: TrafficClass.conversational,
    velocityMps: 1.4,
    currentNetworkId: 'wifi_1',
    networks: [
      NetworkSnapshot(
        id: 'wifi_1',
        technology: NetworkTechnology.wlan,
        rssDbm: -89,
        dataRateMbps: .02,
        delayMs: 350,
        ber: .001,
        parameterSource: ParameterSource.synthetic,
      ),
      NetworkSnapshot(
        id: 'lte_1',
        technology: NetworkTechnology.lte,
        rssDbm: -65,
        dataRateMbps: 20,
        delayMs: 20,
        ber: 1e-7,
        parameterSource: ParameterSource.synthetic,
      ),
    ],
  );
  print(const JsonEncoder.withIndent('  ').convert(result.toJson()));
}
