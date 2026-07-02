import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import '../config/country_names.dart';
import '../config/theme.dart';

/// Maps a national team name to an ISO 3166-1 alpha-2 country code. Accepts the
/// English (Odds API) name or the French display name. Returns null if unknown.
String? isoForTeam(String name) {
  final n = name.trim();
  return _teamIso[n] ?? _teamIso[enCountry(n)];
}

const Map<String, String> _teamIso = {
  // UEFA
  'France': 'fr', 'England': 'gb', 'Scotland': 'gb', 'Wales': 'gb',
  'Northern Ireland': 'gb', 'Spain': 'es', 'Portugal': 'pt', 'Germany': 'de',
  'Italy': 'it', 'Netherlands': 'nl', 'Belgium': 'be', 'Croatia': 'hr',
  'Switzerland': 'ch', 'Austria': 'at', 'Denmark': 'dk', 'Poland': 'pl',
  'Serbia': 'rs', 'Sweden': 'se', 'Norway': 'no', 'Ukraine': 'ua',
  'Czech Republic': 'cz', 'Czechia': 'cz', 'Turkey': 'tr', 'Türkiye': 'tr',
  'Bosnia & Herzegovina': 'ba', 'Bosnia and Herzegovina': 'ba',
  'Greece': 'gr', 'Hungary': 'hu', 'Romania': 'ro', 'Slovakia': 'sk',
  'Slovenia': 'si', 'Republic of Ireland': 'ie', 'Ireland': 'ie',
  // CONMEBOL
  'Brazil': 'br', 'Argentina': 'ar', 'Uruguay': 'uy', 'Colombia': 'co',
  'Chile': 'cl', 'Peru': 'pe', 'Ecuador': 'ec', 'Paraguay': 'py',
  'Bolivia': 'bo', 'Venezuela': 've',
  // CONCACAF
  'United States': 'us', 'USA': 'us', 'Mexico': 'mx', 'Canada': 'ca',
  'Costa Rica': 'cr', 'Panama': 'pa', 'Jamaica': 'jm', 'Honduras': 'hn',
  'Haiti': 'ht', 'El Salvador': 'sv',
  // CAF
  'Morocco': 'ma', 'Senegal': 'sn', 'Ghana': 'gh', 'Nigeria': 'ng',
  'Cameroon': 'cm', 'Egypt': 'eg', 'Algeria': 'dz', 'Tunisia': 'tn',
  'Ivory Coast': 'ci', "Cote d'Ivoire": 'ci', 'South Africa': 'za',
  'Mali': 'ml', 'DR Congo': 'cd', 'Democratic Republic of the Congo': 'cd',
  // AFC
  'Japan': 'jp', 'South Korea': 'kr', 'Korea Republic': 'kr',
  'Saudi Arabia': 'sa', 'Iran': 'ir', 'Australia': 'au', 'Qatar': 'qa',
  'Uzbekistan': 'uz', 'Iraq': 'iq', 'Jordan': 'jo', 'United Arab Emirates': 'ae',
  // OFC
  'New Zealand': 'nz',
};

class TeamFlag extends StatelessWidget {
  const TeamFlag(this.teamName, {super.key, this.height = 28});
  final String teamName;
  final double height;

  @override
  Widget build(BuildContext context) {
    final iso = isoForTeam(teamName);
    final width = height * 1.4;
    if (iso != null) {
      return CountryFlag.fromCountryCode(
        iso,
        theme: ImageTheme(
          width: width,
          height: height,
          shape: const Rectangle(),
        ),
      );
    }
    // Fallback: a teal chip with the first letters of the team name.
    final initials = teamName.length >= 3
        ? teamName.substring(0, 3).toUpperCase()
        : teamName.toUpperCase();
    return Container(
      height: height,
      width: width,
      alignment: Alignment.center,
      color: AppColors.teal.withValues(alpha: 0.2),
      child: Text(initials,
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.teal)),
    );
  }
}
