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
