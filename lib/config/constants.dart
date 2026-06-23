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

/// Maximum number of legs in a generated combo. High enough that low-odds
/// (low-risk) selections can still be stacked to reach a large target
/// multiplier (e.g. ~13 legs at 1.20 odds to reach ×10).
const int kMaxComboLegs = 20;

/// Risk is expressed as the band of *individual* odds a leg may have.
/// Faible (peu risqué): low odds, up to [kLowRiskMaxOdd].
/// Modéré: between [kLowRiskMaxOdd] and [kModerateMaxOdd].
/// Risqué: above [kModerateMaxOdd].
const double kLowRiskMaxOdd = 1.50;
const double kModerateMaxOdd = 2.50;

/// Number of combo proposals to return.
const int kComboCount = 3;
