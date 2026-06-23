enum RiskLevel { peuRisque, modere, risque, tresRisque }

extension RiskLevelLabel on RiskLevel {
  String get label => switch (this) {
        RiskLevel.peuRisque => 'Peu risqué',
        RiskLevel.modere => 'Modéré',
        RiskLevel.risque => 'Risqué',
        RiskLevel.tresRisque => 'Très risqué',
      };
}
