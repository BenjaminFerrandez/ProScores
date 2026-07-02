import 'package:flutter_test/flutter_test.dart';
import 'package:proscores/services/probability_service.dart';

void main() {
  test('normalizeImplied removes the bookmaker margin (sums to 1)', () {
    // odds 2.0/4.0/4.0 -> implied 0.5/0.25/0.25 = 1.0 already, margin 0
    final p = ProbabilityService.normalizeImplied([2.0, 4.0, 4.0]);
    expect(p[0], closeTo(0.5, 1e-9));
    expect(p.reduce((a, b) => a + b), closeTo(1.0, 1e-9));
  });

  test('normalizeImplied normalizes when margin > 0', () {
    // implied 0.5556 each, sum 1.111 -> normalized 0.5 each
    final p = ProbabilityService.normalizeImplied([1.8, 1.8]);
    expect(p[0], closeTo(0.5, 1e-9));
    expect(p[1], closeTo(0.5, 1e-9));
  });
}
