import '../test/core/handover_cases.dart';

void main() {
  var passed = 0;
  handoverCases((name, body) {
    body();
    passed++;
    print('PASS $name');
  });
  print('$passed core checks passed');
}
