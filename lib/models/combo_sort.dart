enum ComboSort {
  probabilityDesc, // most probable first (default)
  probabilityAsc, // least probable first
  payoutDesc, // biggest potential win first
}

extension ComboSortLabel on ComboSort {
  String get label => switch (this) {
        ComboSort.probabilityDesc => 'Plus probables d\'abord',
        ComboSort.probabilityAsc => 'Moins probables d\'abord',
        ComboSort.payoutDesc => 'Plus gros gains d\'abord',
      };
}
