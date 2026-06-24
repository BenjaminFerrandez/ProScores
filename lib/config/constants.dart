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

/// Maximum number of legs in a generated combo. Effectively "unlimited" for
/// this app: there are only ~28 World Cup matches and a combo uses at most one
/// leg per match, so this ceiling (well above the match count) lets low-odds
/// combos stack as deep as needed to reach big targets (e.g. 10€ -> 500€, ×50,
/// ~22 legs at 1.20 odds).
const int kMaxComboLegs = 40;

/// Risk is expressed as the band of *individual* odds a leg may have.
/// Faible (peu risqué): low odds, up to [kLowRiskMaxOdd].
/// Modéré: between [kLowRiskMaxOdd] and [kModerateMaxOdd].
/// Risqué: above [kModerateMaxOdd].
const double kLowRiskMaxOdd = 1.50;
const double kModerateMaxOdd = 2.50;

/// Number of combo proposals to return.
const int kComboCount = 3;

/// Reference season for team/player stats and recent results on API-Football.
/// The free plan only exposes seasons 2022–2024, so 2024 is the most recent
/// data available. Bump once the plan/edition covers newer seasons.
const int kStatsSeason = 2024;

/// How many past head-to-head meetings to display.
const int kH2hCount = 6;

/// How many recent results (per team) to display.
const int kRecentResultsCount = 5;

// --- Affiliation (virtual, student-project only) ---------------------------
// No real money: commissions are simulated euros, stored locally. In a real
// product these would be paid by the bookmaker's affiliate program.

/// Virtual commission credited to a referrer when someone signs up with their
/// affiliate code.
const double kReferralCommission = 5.0;

/// Virtual welcome bonus credited to a new user who signed up with a code.
const double kWelcomeBonus = 2.0;
