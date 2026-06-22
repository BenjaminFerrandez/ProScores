# ProScores MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Flutter mobile app showing upcoming World Cup 2026 matches, their prediction markets with adjusted probabilities, and a brute-force combo generator driven by stake / target / risk.

**Architecture:** Layered with Riverpod. UI ↔ providers ↔ pure business services (`RiskClassifier`, `ProbabilityService`, `ComboGenerator`) ↔ repositories (interfaces + HTTP implementations for The Odds API and API-Football) ↔ models. Pure logic is unit-tested first (TDD); repositories are tested against recorded JSON.

**Tech Stack:** Flutter 3.32.4 / Dart 3.8.1, `flutter_riverpod`, `http`, `google_fonts`, `intl`. Tests with `flutter_test` + `mocktail`.

## Global Constraints

- Colors: `#202322` (dark/bg), `#F3F9F8` (light/cards), `#049F7C` (teal/accent). Define once in `lib/config/theme.dart`.
- Fonts: **Outfit** (headings, w600–w800) + **DM Sans** (body) via `google_fonts`. Numbers (odds, percentages) use `FontFeature.tabularFigures()`.
- API keys live ONLY in `lib/config/api_keys.dart` (git-ignored). A versioned template `api_keys.example.dart` holds empty values.
- Combo generator: brute force, **max 3 legs**, product-of-odds within **±10%** of target, **never two legs on the same match**, return **3** proposals sorted by combo probability descending.
- Risk tiers by adjusted probability: Peu risqué ≥0.70, Modéré 0.50–0.70, Risqué 0.30–0.50, Très risqué <0.30.
- Probability weighting starts 50/50 (bookmaker vs model), weight defined as a named constant for later calibration.
- Every user-facing prono screen shows a responsible-gaming note.
- Competition: World Cup. `kWorldCupLeagueId` constant (API-Football league id, default `1`) and `kSeason` (default `2026`) in `lib/config/constants.dart`.

---

### Task 1: Scaffold project, dependencies, config, theme

**Files:**
- Create: `pubspec.yaml` (via `flutter create`, then edit deps)
- Create: `lib/config/constants.dart`
- Create: `lib/config/api_keys.example.dart`
- Create: `lib/config/api_keys.dart` (git-ignored)
- Create: `lib/config/theme.dart`
- Create: `lib/main.dart`
- Create: `.gitignore` (append rules)

**Interfaces:**
- Produces: `AppColors` (`dark`, `light`, `teal`), `buildAppTheme()` → `ThemeData`; constants `kWorldCupLeagueId`, `kSeason`, `kBookmakerWeight`, `kComboTolerance`, `kMaxLegs`, `kComboCount`; `oddsApiKey`, `footballApiKey` (String).

- [ ] **Step 1: Create the Flutter project**

Run from `C:\Users\lucas\Desktop\B3\DevMobile`:
```bash
flutter create --org com.proscores --project-name proscores ProScores
```
Note: the repo already exists with a `.git`; `flutter create` populates it in place. Expected: project files generated, `flutter` reports "All done!".

- [ ] **Step 2: Add dependencies**

Run from `ProScores/`:
```bash
flutter pub add flutter_riverpod http google_fonts intl
flutter pub add --dev mocktail
```
Expected: `pubspec.yaml` updated, `flutter pub get` succeeds.

- [ ] **Step 3: Write config constants**

Create `lib/config/constants.dart`:
```dart
/// API-Football league id for the World Cup. Confirm at integration time.
const int kWorldCupLeagueId = 1;

/// Season year used for API-Football fixture queries.
const int kSeason = 2026;

/// Weight given to the bookmaker implied probability vs the model
/// probability when blending. 0.5 == 50/50. Tune after observing results.
const double kBookmakerWeight = 0.5;

/// Acceptable relative gap between a combo's total odds and the target
/// multiplier (0.10 == ±10%).
const double kComboTolerance = 0.10;

/// Maximum number of legs in a generated combo.
const int kMaxLegs = 3;

/// Number of combo proposals to return.
const int kComboCount = 3;
```

- [ ] **Step 4: Write the API keys template and real file**

Create `lib/config/api_keys.example.dart`:
```dart
// Copy this file to api_keys.dart and fill in your keys.
// api_keys.dart is git-ignored.
const String oddsApiKey = '';
const String footballApiKey = '';
```
Create `lib/config/api_keys.dart` (same shape, real keys pasted by the user):
```dart
const String oddsApiKey = 'PUT_YOUR_ODDS_API_KEY';
const String footballApiKey = 'PUT_YOUR_API_FOOTBALL_KEY';
```

- [ ] **Step 5: Git-ignore secrets and brainstorm artifacts**

Append to `.gitignore`:
```
# Secrets
/lib/config/api_keys.dart

# Brainstorm companion
.superpowers/
```

- [ ] **Step 6: Write the theme**

Create `lib/config/theme.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const dark = Color(0xFF202322);
  static const light = Color(0xFFF3F9F8);
  static const teal = Color(0xFF049F7C);
  static const card = Color(0xFF262B2A);
  static const muted = Color(0xFF9BB3AD);
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final bodyFont = GoogleFonts.dmSansTextTheme(base.textTheme);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.dark,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.teal,
      surface: AppColors.card,
    ),
    textTheme: bodyFont.copyWith(
      headlineSmall: GoogleFonts.outfit(
          fontWeight: FontWeight.w800, color: AppColors.light),
      titleMedium: GoogleFonts.outfit(
          fontWeight: FontWeight.w700, color: AppColors.light),
      titleSmall: GoogleFonts.outfit(
          fontWeight: FontWeight.w700, color: AppColors.light),
    ),
  );
}

/// Text style for numbers (odds, percentages) with aligned figures.
TextStyle tabularNumberStyle(TextStyle base) =>
    base.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
```

- [ ] **Step 7: Write a minimal main.dart**

Create `lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';

void main() => runApp(const ProviderScope(child: ProScoresApp()));

class ProScoresApp extends StatelessWidget {
  const ProScoresApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'ProScores',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const Scaffold(body: Center(child: Text('ProScores'))),
      );
}
```

- [ ] **Step 8: Verify it builds**

Run: `flutter analyze`
Expected: "No issues found!" (or only info-level lints).

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "chore: scaffold Flutter app, deps, config, theme"
```

---

### Task 2: Data models

**Files:**
- Create: `lib/models/team.dart`
- Create: `lib/models/risk_level.dart`
- Create: `lib/models/selection.dart`
- Create: `lib/models/market.dart`
- Create: `lib/models/match_fixture.dart`
- Create: `lib/models/prediction.dart`
- Create: `lib/models/combo.dart`
- Test: `test/models/models_test.dart`

**Interfaces:**
- Produces:
  - `Team({required int id, required String name, String? flag})`
  - `enum RiskLevel { peuRisque, modere, risque, tresRisque }` with `String get label`
  - `Selection({required String label, required double odd, required double adjustedProbability, RiskLevel? risk})`
  - `enum MarketType { resultat1x2, btts, overUnder25, doubleChance }` with `String get label`
  - `Market({required MarketType type, required List<Selection> selections})`
  - `MatchFixture({required int id, required String competition, String? group, required DateTime kickoff, required Team home, required Team away, List<Market> markets})`
  - `Prediction({required double homeProb, required double drawProb, required double awayProb})`
  - `ComboLeg({required int matchId, required String matchLabel, required Selection selection})`
  - `Combo({required List<ComboLeg> legs, required double totalOdds, required double probability, required double potentialWin})`

- [ ] **Step 1: Write the failing test**

Create `test/models/models_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:proscores/models/risk_level.dart';
import 'package:proscores/models/selection.dart';
import 'package:proscores/models/market.dart';
import 'package:proscores/models/combo.dart';

void main() {
  test('RiskLevel labels are French', () {
    expect(RiskLevel.peuRisque.label, 'Peu risqué');
    expect(RiskLevel.modere.label, 'Modéré');
  });

  test('MarketType labels are French', () {
    expect(MarketType.btts.label, 'Les deux équipes marquent');
    expect(MarketType.overUnder25.label, 'Plus / moins de 2.5 buts');
  });

  test('Selection stores odd and probability', () {
    const s = Selection(label: 'France', odd: 2.10, adjustedProbability: 0.48);
    expect(s.odd, 2.10);
    expect(s.adjustedProbability, 0.48);
  });

  test('Combo computes nothing itself but holds totals', () {
    const leg = ComboLeg(
      matchId: 1,
      matchLabel: 'France - Brésil',
      selection:
          Selection(label: 'France', odd: 2.1, adjustedProbability: 0.48),
    );
    const c = Combo(
        legs: [leg], totalOdds: 2.1, probability: 0.48, potentialWin: 21.0);
    expect(c.legs.single.matchLabel, 'France - Brésil');
    expect(c.potentialWin, 21.0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/models/models_test.dart`
Expected: FAIL — target files don't exist / undefined names.

- [ ] **Step 3: Write the model files**

Create `lib/models/team.dart`:
```dart
class Team {
  final int id;
  final String name;
  final String? flag;
  const Team({required this.id, required this.name, this.flag});
}
```

Create `lib/models/risk_level.dart`:
```dart
enum RiskLevel { peuRisque, modere, risque, tresRisque }

extension RiskLevelLabel on RiskLevel {
  String get label => switch (this) {
        RiskLevel.peuRisque => 'Peu risqué',
        RiskLevel.modere => 'Modéré',
        RiskLevel.risque => 'Risqué',
        RiskLevel.tresRisque => 'Très risqué',
      };
}
```

Create `lib/models/selection.dart`:
```dart
import 'risk_level.dart';

class Selection {
  final String label;
  final double odd;
  final double adjustedProbability;
  final RiskLevel? risk;
  const Selection({
    required this.label,
    required this.odd,
    required this.adjustedProbability,
    this.risk,
  });

  Selection copyWith({RiskLevel? risk}) => Selection(
        label: label,
        odd: odd,
        adjustedProbability: adjustedProbability,
        risk: risk ?? this.risk,
      );
}
```

Create `lib/models/market.dart`:
```dart
import 'selection.dart';

enum MarketType { resultat1x2, btts, overUnder25, doubleChance }

extension MarketTypeLabel on MarketType {
  String get label => switch (this) {
        MarketType.resultat1x2 => 'Vainqueur du match',
        MarketType.btts => 'Les deux équipes marquent',
        MarketType.overUnder25 => 'Plus / moins de 2.5 buts',
        MarketType.doubleChance => 'Double chance',
      };
}

class Market {
  final MarketType type;
  final List<Selection> selections;
  const Market({required this.type, required this.selections});
}
```

Create `lib/models/match_fixture.dart`:
```dart
import 'market.dart';
import 'team.dart';

class MatchFixture {
  final int id;
  final String competition;
  final String? group;
  final DateTime kickoff;
  final Team home;
  final Team away;
  final List<Market> markets;
  const MatchFixture({
    required this.id,
    required this.competition,
    this.group,
    required this.kickoff,
    required this.home,
    required this.away,
    this.markets = const [],
  });

  String get label => '${home.name} - ${away.name}';

  MatchFixture copyWith({List<Market>? markets}) => MatchFixture(
        id: id,
        competition: competition,
        group: group,
        kickoff: kickoff,
        home: home,
        away: away,
        markets: markets ?? this.markets,
      );
}
```

Create `lib/models/prediction.dart`:
```dart
class Prediction {
  final double homeProb;
  final double drawProb;
  final double awayProb;
  const Prediction({
    required this.homeProb,
    required this.drawProb,
    required this.awayProb,
  });
}
```

Create `lib/models/combo.dart`:
```dart
import 'selection.dart';

class ComboLeg {
  final int matchId;
  final String matchLabel;
  final Selection selection;
  const ComboLeg({
    required this.matchId,
    required this.matchLabel,
    required this.selection,
  });
}

class Combo {
  final List<ComboLeg> legs;
  final double totalOdds;
  final double probability;
  final double potentialWin;
  const Combo({
    required this.legs,
    required this.totalOdds,
    required this.probability,
    required this.potentialWin,
  });
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/models/models_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/models test/models
git commit -m "feat: add data models"
```

---

### Task 3: RiskClassifier (pure, TDD)

**Files:**
- Create: `lib/services/risk_classifier.dart`
- Test: `test/services/risk_classifier_test.dart`

**Interfaces:**
- Consumes: `RiskLevel` (Task 2).
- Produces: `RiskClassifier.classify(double probability) → RiskLevel` (static). Boundaries are inclusive at the lower bound: 0.70→peuRisque, 0.50→modere, 0.30→risque.

- [ ] **Step 1: Write the failing test**

Create `test/services/risk_classifier_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:proscores/models/risk_level.dart';
import 'package:proscores/services/risk_classifier.dart';

void main() {
  test('>= 0.70 is peu risqué', () {
    expect(RiskClassifier.classify(0.70), RiskLevel.peuRisque);
    expect(RiskClassifier.classify(0.91), RiskLevel.peuRisque);
  });
  test('0.50–0.70 is modéré', () {
    expect(RiskClassifier.classify(0.50), RiskLevel.modere);
    expect(RiskClassifier.classify(0.699), RiskLevel.modere);
  });
  test('0.30–0.50 is risqué', () {
    expect(RiskClassifier.classify(0.30), RiskLevel.risque);
    expect(RiskClassifier.classify(0.499), RiskLevel.risque);
  });
  test('< 0.30 is très risqué', () {
    expect(RiskClassifier.classify(0.29), RiskLevel.tresRisque);
    expect(RiskClassifier.classify(0.0), RiskLevel.tresRisque);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/risk_classifier_test.dart`
Expected: FAIL — `RiskClassifier` undefined.

- [ ] **Step 3: Write minimal implementation**

Create `lib/services/risk_classifier.dart`:
```dart
import '../models/risk_level.dart';

class RiskClassifier {
  static RiskLevel classify(double probability) {
    if (probability >= 0.70) return RiskLevel.peuRisque;
    if (probability >= 0.50) return RiskLevel.modere;
    if (probability >= 0.30) return RiskLevel.risque;
    return RiskLevel.tresRisque;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/risk_classifier_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/services/risk_classifier.dart test/services/risk_classifier_test.dart
git commit -m "feat: add risk classifier"
```

---

### Task 4: ProbabilityService (pure, TDD)

**Files:**
- Create: `lib/services/probability_service.dart`
- Test: `test/services/probability_service_test.dart`

**Interfaces:**
- Consumes: `kBookmakerWeight` (Task 1).
- Produces:
  - `ProbabilityService.normalizeImplied(List<double> odds) → List<double>` — implied (`1/odd`) then divided by their sum (removes margin); preserves order; sums to 1.0.
  - `ProbabilityService.blend(double bookmakerProb, double modelProb, {double weightBookmaker = kBookmakerWeight}) → double` — weighted average.

- [ ] **Step 1: Write the failing test**

Create `test/services/probability_service_test.dart`:
```dart
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
    // implied 0.5+0.5 = 1.0... use overround: odds 1.8/1.8 -> implied 0.5556 each, sum 1.111
    final p = ProbabilityService.normalizeImplied([1.8, 1.8]);
    expect(p[0], closeTo(0.5, 1e-9));
    expect(p[1], closeTo(0.5, 1e-9));
  });

  test('blend defaults to 50/50', () {
    expect(ProbabilityService.blend(0.40, 0.60), closeTo(0.50, 1e-9));
  });

  test('blend respects custom weight', () {
    expect(ProbabilityService.blend(0.40, 0.60, weightBookmaker: 1.0),
        closeTo(0.40, 1e-9));
    expect(ProbabilityService.blend(0.40, 0.60, weightBookmaker: 0.0),
        closeTo(0.60, 1e-9));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/probability_service_test.dart`
Expected: FAIL — `ProbabilityService` undefined.

- [ ] **Step 3: Write minimal implementation**

Create `lib/services/probability_service.dart`:
```dart
import '../config/constants.dart';

class ProbabilityService {
  /// Implied probabilities normalized so the bookmaker margin is removed.
  static List<double> normalizeImplied(List<double> odds) {
    final implied = odds.map((o) => 1.0 / o).toList();
    final sum = implied.fold<double>(0, (a, b) => a + b);
    return implied.map((p) => p / sum).toList();
  }

  /// Weighted average of bookmaker and model probabilities.
  static double blend(
    double bookmakerProb,
    double modelProb, {
    double weightBookmaker = kBookmakerWeight,
  }) =>
      bookmakerProb * weightBookmaker + modelProb * (1 - weightBookmaker);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/probability_service_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/services/probability_service.dart test/services/probability_service_test.dart
git commit -m "feat: add probability service"
```

---

### Task 5: ComboGenerator (pure, TDD)

**Files:**
- Create: `lib/services/combo_generator.dart`
- Test: `test/services/combo_generator_test.dart`

**Interfaces:**
- Consumes: `Selection`, `Combo`, `ComboLeg`, `RiskLevel` (Task 2); `kComboTolerance`, `kMaxLegs`, `kComboCount` (Task 1).
- Produces:
  - `class CandidateBet { final int matchId; final String matchLabel; final Selection selection; }`
  - `ComboGenerator.generate({required double stake, required double target, required RiskLevel risk, required List<CandidateBet> pool, double tolerance = kComboTolerance, int maxLegs = kMaxLegs, int maxResults = kComboCount}) → List<Combo>` — returns combos whose total odds are within `tolerance` of `target/stake`, never two legs on the same match, combo probability = product of leg probabilities, sorted by probability descending, de-duplicated by leg set, capped at `maxResults`.

- [ ] **Step 1: Write the failing test**

Create `test/services/combo_generator_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:proscores/models/risk_level.dart';
import 'package:proscores/models/selection.dart';
import 'package:proscores/services/combo_generator.dart';

CandidateBet bet(int matchId, String label, double odd, double prob) =>
    CandidateBet(
      matchId: matchId,
      matchLabel: 'match$matchId',
      selection: Selection(
          label: label,
          odd: odd,
          adjustedProbability: prob,
          risk: RiskClassifierLevelFor(prob)),
    );

// helper so the test pool is tagged with a risk level
RiskLevel RiskClassifierLevelFor(double p) =>
    p >= 0.5 ? RiskLevel.modere : RiskLevel.risque;

void main() {
  test('finds a 2-leg combo near the target multiplier', () {
    // target multiplier 2x; legs 1.4*1.45 = 2.03 within ±10%
    final pool = [
      bet(1, 'A', 1.40, 0.60),
      bet(2, 'B', 1.45, 0.58),
      bet(3, 'C', 5.00, 0.55), // far off target alone
    ];
    final combos = ComboGenerator.generate(
      stake: 10,
      target: 20,
      risk: RiskLevel.modere,
      pool: pool,
    );
    expect(combos, isNotEmpty);
    expect(combos.first.legs.length, 2);
    expect(combos.first.totalOdds, closeTo(2.03, 0.01));
    expect(combos.first.potentialWin, closeTo(20.3, 0.1));
    // probability is the product of leg probabilities
    expect(combos.first.probability, closeTo(0.60 * 0.58, 1e-9));
  });

  test('never uses two legs from the same match', () {
    final pool = [
      bet(1, 'A', 1.42, 0.60),
      bet(1, 'A2', 1.42, 0.60), // same matchId
    ];
    final combos = ComboGenerator.generate(
      stake: 10,
      target: 20,
      risk: RiskLevel.modere,
      pool: pool,
    );
    expect(combos, isEmpty);
  });

  test('filters out selections not in the requested risk tier', () {
    final pool = [
      bet(1, 'A', 1.42, 0.40), // risqué, excluded
      bet(2, 'B', 1.42, 0.40),
    ];
    final combos = ComboGenerator.generate(
      stake: 10,
      target: 20,
      risk: RiskLevel.modere,
      pool: pool,
    );
    expect(combos, isEmpty);
  });

  test('sorts by combo probability descending and caps results', () {
    final pool = [
      bet(1, 'A', 1.40, 0.70),
      bet(2, 'B', 1.45, 0.69),
      bet(3, 'C', 1.42, 0.68),
      bet(4, 'D', 1.43, 0.67),
    ];
    final combos = ComboGenerator.generate(
      stake: 10,
      target: 20,
      risk: RiskLevel.modere,
      pool: pool,
      maxResults: 2,
    );
    expect(combos.length, 2);
    expect(combos[0].probability, greaterThanOrEqualTo(combos[1].probability));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/combo_generator_test.dart`
Expected: FAIL — `ComboGenerator` / `CandidateBet` undefined.

- [ ] **Step 3: Write minimal implementation**

Create `lib/services/combo_generator.dart`:
```dart
import '../config/constants.dart';
import '../models/combo.dart';
import '../models/risk_level.dart';
import '../models/selection.dart';

class CandidateBet {
  final int matchId;
  final String matchLabel;
  final Selection selection;
  const CandidateBet({
    required this.matchId,
    required this.matchLabel,
    required this.selection,
  });
}

class ComboGenerator {
  static List<Combo> generate({
    required double stake,
    required double target,
    required RiskLevel risk,
    required List<CandidateBet> pool,
    double tolerance = kComboTolerance,
    int maxLegs = kMaxLegs,
    int maxResults = kComboCount,
  }) {
    if (stake <= 0) return [];
    final multiplier = target / stake;
    final low = multiplier * (1 - tolerance);
    final high = multiplier * (1 + tolerance);

    final filtered =
        pool.where((b) => b.selection.risk == risk).toList(growable: false);

    final results = <Combo>[];
    // Enumerate combinations of size 2..maxLegs.
    for (var size = 2; size <= maxLegs; size++) {
      _combinations(filtered, size, (combo) {
        // reject two legs on the same match
        final matchIds = combo.map((b) => b.matchId).toSet();
        if (matchIds.length != combo.length) return;
        final totalOdds =
            combo.fold<double>(1.0, (acc, b) => acc * b.selection.odd);
        if (totalOdds < low || totalOdds > high) return;
        final probability = combo.fold<double>(
            1.0, (acc, b) => acc * b.selection.adjustedProbability);
        results.add(Combo(
          legs: combo
              .map((b) => ComboLeg(
                  matchId: b.matchId,
                  matchLabel: b.matchLabel,
                  selection: b.selection))
              .toList(),
          totalOdds: totalOdds,
          probability: probability,
          potentialWin: stake * totalOdds,
        ));
      });
    }

    results.sort((a, b) => b.probability.compareTo(a.probability));
    return results.take(maxResults).toList();
  }

  /// Calls [emit] with every size-[k] combination of [items].
  static void _combinations<T>(
    List<T> items,
    int k,
    void Function(List<T>) emit,
  ) {
    final n = items.length;
    if (k > n) return;
    final indices = List<int>.generate(k, (i) => i);
    while (true) {
      emit([for (final i in indices) items[i]]);
      var i = k - 1;
      while (i >= 0 && indices[i] == n - k + i) {
        i--;
      }
      if (i < 0) break;
      indices[i]++;
      for (var j = i + 1; j < k; j++) {
        indices[j] = indices[j - 1] + 1;
      }
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/combo_generator_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/services/combo_generator.dart test/services/combo_generator_test.dart
git commit -m "feat: add brute-force combo generator"
```

---

### Task 6: Repository interfaces + API clients

**Files:**
- Create: `lib/data/football_repository.dart` (abstract + impl)
- Create: `lib/data/odds_repository.dart` (abstract + impl)
- Test: `test/data/football_repository_test.dart`
- Test: `test/data/odds_repository_test.dart`

**Interfaces:**
- Consumes: `MatchFixture`, `Team`, `Prediction` (Task 2); `footballApiKey`, `oddsApiKey`, `kWorldCupLeagueId`, `kSeason` (Task 1); `package:http`.
- Produces:
  - `abstract class FootballRepository { Future<List<MatchFixture>> upcomingWorldCupFixtures(); Future<Prediction> predictionFor(int fixtureId); }`
  - `class HttpFootballRepository implements FootballRepository { HttpFootballRepository(this.client); final http.Client client; }`
  - `abstract class OddsRepository { Future<Map<String, List<double>>> marketOddsFor(String homeTeam, String awayTeam); }` returning a map keyed by market code (`'1x2'`, `'btts'`, `'ou25'`, `'dc'`) to ordered odds.
  - `class HttpOddsRepository implements OddsRepository { HttpOddsRepository(this.client); final http.Client client; }`

> Note: API-Football and The Odds API JSON shapes below match their documented responses as of 2026-01. If a field differs at integration time, adjust the parser — the test fixtures pin the exact shape the parser expects.

- [ ] **Step 1: Write the failing test for FootballRepository**

Create `test/data/football_repository_test.dart`:
```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:proscores/data/football_repository.dart';

class _MockClient extends Mock implements http.Client {}

void main() {
  setUpAll(() => registerFallbackValue(Uri()));

  test('parses upcoming fixtures', () async {
    final client = _MockClient();
    final body = jsonEncode({
      'response': [
        {
          'fixture': {
            'id': 101,
            'date': '2026-06-22T21:00:00+00:00',
          },
          'league': {'name': 'World Cup', 'round': 'Group Stage - 1'},
          'teams': {
            'home': {'id': 2, 'name': 'France', 'logo': 'fr.png'},
            'away': {'id': 6, 'name': 'Brazil', 'logo': 'br.png'},
          },
        }
      ]
    });
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response(body, 200));

    final repo = HttpFootballRepository(client);
    final fixtures = await repo.upcomingWorldCupFixtures();

    expect(fixtures, hasLength(1));
    expect(fixtures.first.id, 101);
    expect(fixtures.first.home.name, 'France');
    expect(fixtures.first.away.name, 'Brazil');
    expect(fixtures.first.kickoff.toUtc().hour, 21);
  });

  test('parses prediction percentages', () async {
    final client = _MockClient();
    final body = jsonEncode({
      'response': [
        {
          'predictions': {
            'percent': {'home': '48%', 'draw': '29%', 'away': '23%'}
          }
        }
      ]
    });
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response(body, 200));

    final repo = HttpFootballRepository(client);
    final pred = await repo.predictionFor(101);

    expect(pred.homeProb, closeTo(0.48, 1e-9));
    expect(pred.drawProb, closeTo(0.29, 1e-9));
    expect(pred.awayProb, closeTo(0.23, 1e-9));
  });

  test('throws on non-200', () async {
    final client = _MockClient();
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('nope', 429));
    final repo = HttpFootballRepository(client);
    expect(repo.upcomingWorldCupFixtures(), throwsA(isA<ApiException>()));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/football_repository_test.dart`
Expected: FAIL — `HttpFootballRepository` / `ApiException` undefined.

- [ ] **Step 3: Implement FootballRepository**

Create `lib/data/football_repository.dart`:
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../config/constants.dart';
import '../models/match_fixture.dart';
import '../models/prediction.dart';
import '../models/team.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => 'ApiException: $message';
}

abstract class FootballRepository {
  Future<List<MatchFixture>> upcomingWorldCupFixtures();
  Future<Prediction> predictionFor(int fixtureId);
}

class HttpFootballRepository implements FootballRepository {
  HttpFootballRepository(this.client);
  final http.Client client;

  static const _base = 'https://v3.football.api-sports.io';
  Map<String, String> get _headers => {'x-apisports-key': footballApiKey};

  @override
  Future<List<MatchFixture>> upcomingWorldCupFixtures() async {
    final uri = Uri.parse(
        '$_base/fixtures?league=$kWorldCupLeagueId&season=$kSeason&next=20');
    final res = await client.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw ApiException('fixtures HTTP ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (data['response'] as List).cast<Map<String, dynamic>>();
    return list.map(_parseFixture).toList();
  }

  MatchFixture _parseFixture(Map<String, dynamic> j) {
    final fixture = j['fixture'] as Map<String, dynamic>;
    final league = j['league'] as Map<String, dynamic>;
    final teams = j['teams'] as Map<String, dynamic>;
    final home = teams['home'] as Map<String, dynamic>;
    final away = teams['away'] as Map<String, dynamic>;
    return MatchFixture(
      id: fixture['id'] as int,
      competition: league['name'] as String? ?? 'World Cup',
      group: league['round'] as String?,
      kickoff: DateTime.parse(fixture['date'] as String),
      home: Team(
          id: home['id'] as int,
          name: home['name'] as String,
          flag: home['logo'] as String?),
      away: Team(
          id: away['id'] as int,
          name: away['name'] as String,
          flag: away['logo'] as String?),
    );
  }

  @override
  Future<Prediction> predictionFor(int fixtureId) async {
    final uri = Uri.parse('$_base/predictions?fixture=$fixtureId');
    final res = await client.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw ApiException('predictions HTTP ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final response = (data['response'] as List).cast<Map<String, dynamic>>();
    if (response.isEmpty) throw ApiException('no prediction');
    final percent = (response.first['predictions']
        as Map<String, dynamic>)['percent'] as Map<String, dynamic>;
    double pct(String k) =>
        double.parse((percent[k] as String).replaceAll('%', '')) / 100.0;
    return Prediction(
        homeProb: pct('home'), drawProb: pct('draw'), awayProb: pct('away'));
  }
}
```

- [ ] **Step 4: Run FootballRepository test to verify it passes**

Run: `flutter test test/data/football_repository_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Write the failing test for OddsRepository**

Create `test/data/odds_repository_test.dart`:
```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:proscores/data/odds_repository.dart';

class _MockClient extends Mock implements http.Client {}

void main() {
  setUpAll(() => registerFallbackValue(Uri()));

  test('extracts 1x2 odds for the matching game', () async {
    final client = _MockClient();
    final body = jsonEncode([
      {
        'home_team': 'France',
        'away_team': 'Brazil',
        'bookmakers': [
          {
            'markets': [
              {
                'key': 'h2h',
                'outcomes': [
                  {'name': 'France', 'price': 2.10},
                  {'name': 'Brazil', 'price': 3.05},
                  {'name': 'Draw', 'price': 3.40},
                ]
              }
            ]
          }
        ]
      }
    ]);
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response(body, 200));

    final repo = HttpOddsRepository(client);
    final odds = await repo.marketOddsFor('France', 'Brazil');

    // ordered home, draw, away
    expect(odds['1x2'], [2.10, 3.40, 3.05]);
  });

  test('returns empty map when no game matches', () async {
    final client = _MockClient();
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('[]', 200));
    final repo = HttpOddsRepository(client);
    final odds = await repo.marketOddsFor('France', 'Brazil');
    expect(odds, isEmpty);
  });
}
```

- [ ] **Step 6: Run OddsRepository test to verify it fails**

Run: `flutter test test/data/odds_repository_test.dart`
Expected: FAIL — `HttpOddsRepository` undefined.

- [ ] **Step 7: Implement OddsRepository**

Create `lib/data/odds_repository.dart`:
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import 'football_repository.dart' show ApiException;

abstract class OddsRepository {
  /// Map of market code -> ordered odds.
  /// '1x2' -> [home, draw, away].
  Future<Map<String, List<double>>> marketOddsFor(
      String homeTeam, String awayTeam);
}

class HttpOddsRepository implements OddsRepository {
  HttpOddsRepository(this.client);
  final http.Client client;

  static const _base =
      'https://api.the-odds-api.com/v4/sports/soccer_fifa_world_cup/odds';

  @override
  Future<Map<String, List<double>>> marketOddsFor(
      String homeTeam, String awayTeam) async {
    final uri = Uri.parse(
        '$_base?regions=eu&markets=h2h&oddsFormat=decimal&apiKey=$oddsApiKey');
    final res = await client.get(uri, headers: const {});
    if (res.statusCode != 200) {
      throw ApiException('odds HTTP ${res.statusCode}');
    }
    final games = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    final game = games.firstWhere(
      (g) => g['home_team'] == homeTeam && g['away_team'] == awayTeam,
      orElse: () => <String, dynamic>{},
    );
    if (game.isEmpty) return {};

    final bookmakers = (game['bookmakers'] as List).cast<Map<String, dynamic>>();
    if (bookmakers.isEmpty) return {};
    final markets =
        (bookmakers.first['markets'] as List).cast<Map<String, dynamic>>();
    final result = <String, List<double>>{};

    final h2h = markets.where((m) => m['key'] == 'h2h');
    if (h2h.isNotEmpty) {
      final outcomes =
          (h2h.first['outcomes'] as List).cast<Map<String, dynamic>>();
      double price(String name) => (outcomes.firstWhere(
          (o) => o['name'] == name)['price'] as num).toDouble();
      result['1x2'] = [price(homeTeam), price('Draw'), price(awayTeam)];
    }
    return result;
  }
}
```

- [ ] **Step 8: Run OddsRepository test to verify it passes**

Run: `flutter test test/data/odds_repository_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 9: Commit**

```bash
git add lib/data test/data
git commit -m "feat: add API repositories with mocked-response tests"
```

---

### Task 7: Riverpod providers + market assembly

**Files:**
- Create: `lib/providers/repository_providers.dart`
- Create: `lib/services/market_builder.dart`
- Create: `lib/providers/matches_provider.dart`
- Create: `lib/providers/match_detail_provider.dart`
- Create: `lib/providers/combo_provider.dart`
- Test: `test/services/market_builder_test.dart`

**Interfaces:**
- Consumes: repositories (Task 6), `ProbabilityService`, `RiskClassifier`, `ComboGenerator` (Tasks 3-5), models (Task 2).
- Produces:
  - `MarketBuilder.build1x2({required List<double> bookmakerOdds, required Prediction prediction}) → Market` — blends normalized implied probs with the prediction, tags each selection's risk.
  - `httpClientProvider`, `footballRepositoryProvider`, `oddsRepositoryProvider`.
  - `upcomingMatchesProvider` (`FutureProvider<List<MatchFixture>>`).
  - `matchDetailProvider` (`FutureProvider.family<MatchFixture, int>`) returning the fixture with its `markets` populated.
  - `ComboRequest({required double stake, required double target, required RiskLevel risk})` and `comboProvider` (`FutureProvider.family<List<Combo>, ComboRequest>`).

- [ ] **Step 1: Write the failing test for MarketBuilder**

Create `test/services/market_builder_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:proscores/models/market.dart';
import 'package:proscores/models/prediction.dart';
import 'package:proscores/models/risk_level.dart';
import 'package:proscores/services/market_builder.dart';

void main() {
  test('build1x2 blends odds + prediction and tags risk', () {
    // implied from 2.0/4.0/4.0 -> 0.5/0.25/0.25 (already normalized)
    const pred = Prediction(homeProb: 0.5, drawProb: 0.25, awayProb: 0.25);
    final market = MarketBuilder.build1x2(
      bookmakerOdds: [2.0, 4.0, 4.0],
      prediction: pred,
    );
    expect(market.type, MarketType.resultat1x2);
    expect(market.selections, hasLength(3));
    // home: blend(0.5, 0.5) = 0.5 -> modéré
    expect(market.selections.first.adjustedProbability, closeTo(0.5, 1e-9));
    expect(market.selections.first.risk, RiskLevel.modere);
    expect(market.selections.first.odd, 2.0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/market_builder_test.dart`
Expected: FAIL — `MarketBuilder` undefined.

- [ ] **Step 3: Implement MarketBuilder**

Create `lib/services/market_builder.dart`:
```dart
import '../models/market.dart';
import '../models/prediction.dart';
import '../models/selection.dart';
import 'probability_service.dart';
import 'risk_classifier.dart';

class MarketBuilder {
  /// Builds the 1X2 market by blending normalized bookmaker odds with the
  /// model prediction. [bookmakerOdds] is ordered [home, draw, away].
  static Market build1x2({
    required List<double> bookmakerOdds,
    required Prediction prediction,
  }) {
    final implied = ProbabilityService.normalizeImplied(bookmakerOdds);
    final modelProbs = [
      prediction.homeProb,
      prediction.drawProb,
      prediction.awayProb,
    ];
    final labels = ['1', 'N', '2'];
    final selections = <Selection>[];
    for (var i = 0; i < 3; i++) {
      final p = ProbabilityService.blend(implied[i], modelProbs[i]);
      selections.add(Selection(
        label: labels[i],
        odd: bookmakerOdds[i],
        adjustedProbability: p,
        risk: RiskClassifier.classify(p),
      ));
    }
    return Market(type: MarketType.resultat1x2, selections: selections);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/market_builder_test.dart`
Expected: PASS (1 test).

- [ ] **Step 5: Write the repository + data providers**

Create `lib/providers/repository_providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../data/football_repository.dart';
import '../data/odds_repository.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final footballRepositoryProvider = Provider<FootballRepository>(
    (ref) => HttpFootballRepository(ref.watch(httpClientProvider)));

final oddsRepositoryProvider = Provider<OddsRepository>(
    (ref) => HttpOddsRepository(ref.watch(httpClientProvider)));
```

Create `lib/providers/matches_provider.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_fixture.dart';
import 'repository_providers.dart';

final upcomingMatchesProvider =
    FutureProvider<List<MatchFixture>>((ref) async {
  final repo = ref.watch(footballRepositoryProvider);
  return repo.upcomingWorldCupFixtures();
});
```

Create `lib/providers/match_detail_provider.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/market.dart';
import '../models/match_fixture.dart';
import '../services/market_builder.dart';
import 'matches_provider.dart';
import 'repository_providers.dart';

/// Loads a fixture and populates its 1X2 market by combining odds + prediction.
final matchDetailProvider =
    FutureProvider.family<MatchFixture, int>((ref, fixtureId) async {
  final fixtures = await ref.watch(upcomingMatchesProvider.future);
  final fixture = fixtures.firstWhere((f) => f.id == fixtureId);

  final football = ref.watch(footballRepositoryProvider);
  final odds = ref.watch(oddsRepositoryProvider);

  final prediction = await football.predictionFor(fixtureId);
  final marketOdds =
      await odds.marketOddsFor(fixture.home.name, fixture.away.name);

  final markets = <Market>[];
  final h2h = marketOdds['1x2'];
  if (h2h != null && h2h.length == 3) {
    markets.add(
        MarketBuilder.build1x2(bookmakerOdds: h2h, prediction: prediction));
  }
  return fixture.copyWith(markets: markets);
});
```

Create `lib/providers/combo_provider.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/combo.dart';
import '../models/risk_level.dart';
import '../services/combo_generator.dart';
import 'matches_provider.dart';
import 'match_detail_provider.dart';

class ComboRequest {
  final double stake;
  final double target;
  final RiskLevel risk;
  const ComboRequest(
      {required this.stake, required this.target, required this.risk});

  @override
  bool operator ==(Object other) =>
      other is ComboRequest &&
      other.stake == stake &&
      other.target == target &&
      other.risk == risk;

  @override
  int get hashCode => Object.hash(stake, target, risk);
}

final comboProvider =
    FutureProvider.family<List<Combo>, ComboRequest>((ref, req) async {
  final fixtures = await ref.watch(upcomingMatchesProvider.future);
  // Build a candidate pool from each fixture's 1X2 selections.
  final pool = <CandidateBet>[];
  for (final f in fixtures) {
    final detail = await ref.watch(matchDetailProvider(f.id).future);
    for (final market in detail.markets) {
      for (final sel in market.selections) {
        pool.add(CandidateBet(
            matchId: f.id, matchLabel: f.label, selection: sel));
      }
    }
  }
  return ComboGenerator.generate(
    stake: req.stake,
    target: req.target,
    risk: req.risk,
    pool: pool,
  );
});
```

- [ ] **Step 6: Verify analysis + tests still pass**

Run: `flutter analyze` then `flutter test`
Expected: analyze clean; all prior tests + market_builder pass.

- [ ] **Step 7: Commit**

```bash
git add lib/providers lib/services/market_builder.dart test/services/market_builder_test.dart
git commit -m "feat: add market builder and Riverpod providers"
```

---

### Task 8: Shared widgets

**Files:**
- Create: `lib/widgets/probability_bar.dart`
- Create: `lib/widgets/responsible_gaming_note.dart`
- Create: `lib/widgets/error_retry.dart`

**Interfaces:**
- Consumes: `AppColors`, `tabularNumberStyle` (Task 1).
- Produces:
  - `ProbabilityBar({required double probability, required String oddLabel})`
  - `ResponsibleGamingNote()`
  - `ErrorRetry({required String message, required VoidCallback onRetry})`

- [ ] **Step 1: Write ProbabilityBar**

Create `lib/widgets/probability_bar.dart`:
```dart
import 'package:flutter/material.dart';
import '../config/theme.dart';

class ProbabilityBar extends StatelessWidget {
  const ProbabilityBar(
      {super.key, required this.probability, required this.oddLabel});
  final double probability;
  final String oddLabel;

  @override
  Widget build(BuildContext context) {
    final pct = (probability * 100).round();
    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.dark,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              FractionallySizedBox(
                widthFactor: probability.clamp(0.0, 1.0),
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Text('$pct%',
                      style: tabularNumberStyle(const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white))),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 44,
          child: Text(oddLabel,
              textAlign: TextAlign.right,
              style: tabularNumberStyle(const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.light))),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Write ResponsibleGamingNote and ErrorRetry**

Create `lib/widgets/responsible_gaming_note.dart`:
```dart
import 'package:flutter/material.dart';
import '../config/theme.dart';

class ResponsibleGamingNote extends StatelessWidget {
  const ResponsibleGamingNote({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          '🔞 Jeu responsable — pariez avec modération. Les pronostics ne '
          'garantissent aucun gain.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      );
}
```

Create `lib/widgets/error_retry.dart`:
```dart
import 'package:flutter/material.dart';
import '../config/theme.dart';

class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      );
}
```

- [ ] **Step 3: Verify analysis**

Run: `flutter analyze`
Expected: clean.

- [ ] **Step 4: Commit**

```bash
git add lib/widgets
git commit -m "feat: add shared widgets (probability bar, notes, error)"
```

---

### Task 9: Home screen (compact match list)

**Files:**
- Create: `lib/screens/home_screen.dart`
- Modify: `lib/main.dart` (set `home: const HomeScreen()`)

**Interfaces:**
- Consumes: `upcomingMatchesProvider` (Task 7), `ErrorRetry` (Task 8), `AppColors` (Task 1), `MatchDetailScreen` (Task 10 — forward ref, import resolves once Task 10 exists), `CreatePronoScreen` (Task 11).
- Produces: `HomeScreen` (ConsumerWidget).

> Note: this task imports `match_detail_screen.dart` and `create_prono_screen.dart`. Create empty stub screens first (Step 1) so it compiles; Tasks 10–11 flesh them out.

- [ ] **Step 1: Create stub screens so imports resolve**

Create `lib/screens/match_detail_screen.dart`:
```dart
import 'package:flutter/material.dart';
class MatchDetailScreen extends StatelessWidget {
  const MatchDetailScreen({super.key, required this.fixtureId});
  final int fixtureId;
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Détail')));
}
```

Create `lib/screens/create_prono_screen.dart`:
```dart
import 'package:flutter/material.dart';
class CreatePronoScreen extends StatelessWidget {
  const CreatePronoScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Crée ton prono')));
}
```

- [ ] **Step 2: Write HomeScreen**

Create `lib/screens/home_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/match_fixture.dart';
import '../providers/matches_provider.dart';
import '../widgets/error_retry.dart';
import 'create_prono_screen.dart';
import 'match_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(upcomingMatchesProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        title: RichText(
          text: const TextSpan(children: [
            TextSpan(
                text: 'Prono',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AppColors.light)),
            TextSpan(
                text: '.',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AppColors.teal)),
          ]),
        ),
      ),
      body: matches.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
            message: 'Impossible de charger les matchs.\n$e',
            onRetry: () => ref.invalidate(upcomingMatchesProvider)),
        data: (list) => _MatchList(list),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                minimumSize: const Size.fromHeight(52)),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const CreatePronoScreen())),
            child: const Text('Crée ton prono !',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}

class _MatchList extends StatelessWidget {
  const _MatchList(this.matches);
  final List<MatchFixture> matches;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const Center(
          child: Text('Aucun match à venir.',
              style: TextStyle(color: AppColors.muted)));
    }
    // group by calendar day
    final byDay = <String, List<MatchFixture>>{};
    for (final m in matches) {
      final key = DateFormat('EEEE d MMM', 'fr_FR').format(m.kickoff.toLocal());
      byDay.putIfAbsent(key, () => []).add(m);
    }
    final days = byDay.keys.toList();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      itemCount: days.length,
      itemBuilder: (_, i) {
        final day = days[i];
        final games = byDay[day]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
              child: Text(day.toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 1)),
            ),
            ...games.map((m) => _MatchRow(m)),
          ],
        );
      },
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow(this.match);
  final MatchFixture match;
  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(match.kickoff.toLocal());
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MatchDetailScreen(fixtureId: match.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppColors.card, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            SizedBox(
                width: 44,
                child: Text(time,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13))),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(match.home.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(match.away.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Wire HomeScreen into main.dart**

In `lib/main.dart`, replace the `home:` line and add imports:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/theme.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  runApp(const ProviderScope(child: ProScoresApp()));
}

class ProScoresApp extends StatelessWidget {
  const ProScoresApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'ProScores',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const HomeScreen(),
      );
}
```

- [ ] **Step 4: Verify it builds and analyzes**

Run: `flutter analyze`
Expected: clean.

- [ ] **Step 5: Commit**

```bash
git add lib/screens lib/main.dart
git commit -m "feat: home screen with compact match list"
```

---

### Task 10: Match detail screen

**Files:**
- Modify: `lib/screens/match_detail_screen.dart` (replace stub)

**Interfaces:**
- Consumes: `matchDetailProvider` (Task 7), `ProbabilityBar`, `ResponsibleGamingNote`, `ErrorRetry` (Task 8), models (Task 2), `AppColors` (Task 1).
- Produces: `MatchDetailScreen({required int fixtureId})` (ConsumerWidget).

- [ ] **Step 1: Replace the stub with the full screen**

Replace `lib/screens/match_detail_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/market.dart';
import '../models/risk_level.dart';
import '../providers/match_detail_provider.dart';
import '../widgets/error_retry.dart';
import '../widgets/probability_bar.dart';
import '../widgets/responsible_gaming_note.dart';

class MatchDetailScreen extends ConsumerWidget {
  const MatchDetailScreen({super.key, required this.fixtureId});
  final int fixtureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(matchDetailProvider(fixtureId));
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.dark),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
            message: 'Impossible de charger le match.\n$e',
            onRetry: () => ref.invalidate(matchDetailProvider(fixtureId))),
        data: (match) => ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Text(match.competition,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(DateFormat("EEEE d MMM · HH:mm", 'fr_FR')
                .format(match.kickoff.toLocal()),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(match.home.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                const Text('VS',
                    style: TextStyle(color: AppColors.muted)),
                Text(match.away.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 20),
            if (match.markets.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Cotes indisponibles pour ce match.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted)),
              ),
            ...match.markets.map((m) => _MarketCard(m)),
            const ResponsibleGamingNote(),
          ],
        ),
      ),
    );
  }
}

class _MarketCard extends StatelessWidget {
  const _MarketCard(this.market);
  final Market market;

  @override
  Widget build(BuildContext context) {
    final topRisk = market.selections.first.risk;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(market.type.label,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              if (topRisk != null) _RiskTag(topRisk),
            ],
          ),
          const SizedBox(height: 10),
          ...market.selections.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                        width: 60,
                        child: Text(s.label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12))),
                    Expanded(
                        child: ProbabilityBar(
                            probability: s.adjustedProbability,
                            oddLabel: s.odd.toStringAsFixed(2))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _RiskTag extends StatelessWidget {
  const _RiskTag(this.risk);
  final RiskLevel risk;
  @override
  Widget build(BuildContext context) {
    final color = switch (risk) {
      RiskLevel.peuRisque => const Color(0xFF5FE3B6),
      RiskLevel.modere => const Color(0xFFE3D65F),
      RiskLevel.risque => const Color(0xFFE39A5F),
      RiskLevel.tresRisque => const Color(0xFFE35F5F),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10)),
      child: Text(risk.label,
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.w600)),
    );
  }
}
```

- [ ] **Step 2: Verify analysis**

Run: `flutter analyze`
Expected: clean.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/match_detail_screen.dart
git commit -m "feat: match detail screen with markets and probabilities"
```

---

### Task 11: Create-prono screen (form + results)

**Files:**
- Modify: `lib/screens/create_prono_screen.dart` (replace stub)

**Interfaces:**
- Consumes: `comboProvider`, `ComboRequest` (Task 7), `RiskLevel` (Task 2), `ResponsibleGamingNote`, `ErrorRetry` (Task 8), `AppColors` (Task 1).
- Produces: `CreatePronoScreen` (ConsumerStatefulWidget) holding form state (stake, target, risk) and showing results on submit.

- [ ] **Step 1: Replace the stub with the full screen**

Replace `lib/screens/create_prono_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/combo.dart';
import '../models/risk_level.dart';
import '../providers/combo_provider.dart';
import '../widgets/error_retry.dart';
import '../widgets/responsible_gaming_note.dart';

class CreatePronoScreen extends ConsumerStatefulWidget {
  const CreatePronoScreen({super.key});
  @override
  ConsumerState<CreatePronoScreen> createState() => _CreatePronoScreenState();
}

class _CreatePronoScreenState extends ConsumerState<CreatePronoScreen> {
  final _stake = TextEditingController(text: '10');
  final _target = TextEditingController(text: '25');
  RiskLevel _risk = RiskLevel.modere;
  ComboRequest? _request;

  @override
  void dispose() {
    _stake.dispose();
    _target.dispose();
    super.dispose();
  }

  double get _stakeVal => double.tryParse(_stake.text) ?? 0;
  double get _targetVal => double.tryParse(_target.text) ?? 0;
  double get _multiplier => _stakeVal > 0 ? _targetVal / _stakeVal : 0;

  void _submit() {
    setState(() {
      _request = ComboRequest(
          stake: _stakeVal, target: _targetVal, risk: _risk);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: AppColors.dark, title: const Text('Crée ton prono')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _NumberField(label: 'Ta mise de départ (€)', controller: _stake,
              onChanged: (_) => setState(() {})),
          const SizedBox(height: 16),
          _NumberField(label: 'Ton objectif de gain (€)', controller: _target,
              onChanged: (_) => setState(() {})),
          if (_multiplier > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Multiplicateur visé × ${_multiplier.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: AppColors.teal, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 16),
          const Text('Niveau de risque',
              style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          _RiskSelector(value: _risk, onChanged: (r) => setState(() => _risk = r)),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                minimumSize: const Size.fromHeight(52)),
            onPressed: _stakeVal > 0 && _targetVal > 0 ? _submit : null,
            child: const Text('Générer mes combinés',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          const ResponsibleGamingNote(),
          if (_request != null) _Results(request: _request!),
        ],
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.request});
  final ComboRequest request;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final combos = ref.watch(comboProvider(request));
    return combos.when(
      loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator())),
      error: (e, _) => ErrorRetry(
          message: 'Erreur lors de la génération.\n$e',
          onRetry: () => ref.invalidate(comboProvider(request))),
      data: (list) {
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
                'Aucun combiné ne correspond à ces paramètres. '
                'Essaie un objectif différent ou un autre niveau de risque.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted)),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < list.length; i++)
              _ComboCard(combo: list[i], best: i == 0),
          ],
        );
      },
    );
  }
}

class _ComboCard extends StatelessWidget {
  const _ComboCard({required this.combo, required this.best});
  final Combo combo;
  final bool best;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: best ? AppColors.teal : const Color(0xFF313837)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Combiné · ${combo.legs.length} jambes',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('${(combo.probability * 100).round()}% de réussite',
                  style: const TextStyle(
                      color: Color(0xFF5FE3B6),
                      fontWeight: FontWeight.w700,
                      fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          ...combo.legs.map((l) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text('${l.matchLabel} · ${l.selection.label}',
                            style: const TextStyle(fontSize: 12))),
                    Text(l.selection.odd.toStringAsFixed(2),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ),
              )),
          const Divider(color: Color(0xFF343B3A)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cote totale ×${combo.totalOdds.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppColors.teal, fontWeight: FontWeight.w800)),
              Text('Gain potentiel ${combo.potentialWin.toStringAsFixed(2)}€',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField(
      {required this.label, required this.controller, required this.onChanged});
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ],
      );
}

class _RiskSelector extends StatelessWidget {
  const _RiskSelector({required this.value, required this.onChanged});
  final RiskLevel value;
  final ValueChanged<RiskLevel> onChanged;
  @override
  Widget build(BuildContext context) {
    const options = [RiskLevel.peuRisque, RiskLevel.modere, RiskLevel.risque];
    return Row(
      children: [
        for (final r in options)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => onChanged(r),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: value == r ? AppColors.teal : AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(r.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify analysis + full test suite**

Run: `flutter analyze` then `flutter test`
Expected: analyze clean; all tests pass.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/create_prono_screen.dart
git commit -m "feat: create-prono screen with combo results"
```

---

### Task 12: Manual smoke test with real keys + responsible-gaming pass

**Files:**
- Modify: `lib/config/api_keys.dart` (user pastes real keys — not committed)

- [ ] **Step 1: Paste real API keys**

Edit `lib/config/api_keys.dart` with the user's real The Odds API and API-Football keys. Confirm `kWorldCupLeagueId` / `kSeason` in `constants.dart` match the current World Cup (look it up in API-Football's `/leagues` if fixtures come back empty).

- [ ] **Step 2: Run the app**

Run: `flutter run` (or via the project's run skill / preview tooling on a device or emulator).
Verify: Home shows upcoming fixtures; tapping one opens detail with 1X2 probabilities + odds + risk tags; "Crée ton prono !" generates combos for stake 10 → target 25, risk Modéré.

- [ ] **Step 3: Confirm responsible-gaming note appears**

Check the note is visible on both the match detail screen and the create-prono screen.

- [ ] **Step 4: Commit any constant fixes**

```bash
git add lib/config/constants.dart
git commit -m "chore: confirm World Cup league id/season"
```
(Skip if no change. `api_keys.dart` stays uncommitted by design.)

---

## Notes for the implementer

- The 1X2 market is the only one wired end-to-end in this MVP (it's the one The Odds API `h2h` returns directly and API-Football predicts). BTTS / Over-Under / Double-chance markets are designed in the models and detail UI; wiring their odds (additional `markets=` params on The Odds API and/or API-Football endpoints) is a natural follow-up and does not change the architecture.
- Keep all pure logic (`services/`) free of Flutter and `http` imports so it stays unit-testable.
- If `flutter analyze` flags `withValues`, the SDK is older than 3.27 — replace `color.withValues(alpha: x)` with `color.withOpacity(x)`.
