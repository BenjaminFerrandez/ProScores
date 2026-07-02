/// Base URL of our backend proxy (server/). The app never talks to The Odds
/// API or API-Football directly — the server holds the keys and caches data.
///
/// - Desktop / web / iOS simulator: http://localhost:8090
/// - Android emulator: http://10.0.2.2:8090 (the emulator's alias for the host)
/// - Physical device: `http://<your-machine-LAN-IP>:8090`
/// (Port 8090 because 8080 is used by another local service on this machine.)
const String kServerBaseUrl = 'http://localhost:8090';

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

/// Number of combo proposals shown per "page" (and revealed by "Voir plus").
const int kComboCount = 3;

/// Max combos the generator produces up front, so "Voir plus" can reveal more
/// without any extra work. Shown 3 at a time.
const int kComboMaxResults = 30;

/// Minimum edge over the market consensus to flag a selection as a "value bet"
/// (0.03 == the offered price beats the consensus by 3%+).
const double kValueEdgeThreshold = 0.03;

/// Reference season for team/player stats and recent results on API-Football.
/// The free plan only exposes seasons 2022–2024, so 2024 is the most recent
/// data available. Bump once the plan/edition covers newer seasons.
const int kStatsSeason = 2024;

/// How many past head-to-head meetings to display.
const int kH2hCount = 6;

/// How many recent results (per team) to display.
const int kRecentResultsCount = 5;

