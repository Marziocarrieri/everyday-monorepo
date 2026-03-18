enum AreaType {
  pantry,
  fridge,
  freezer,
  spirits,       // Home Bar
  household,     // Prodotti cucina/pulizia
  personalCare,  // Prodotti bagno/persona
}

extension AreaTypeX on AreaType {
  String get dbValue {
    switch (this) {
      case AreaType.pantry: return 'PANTRY';
      case AreaType.fridge: return 'FRIDGE';
      case AreaType.freezer: return 'FREEZER';
      case AreaType.spirits: return 'SPIRITS';
      case AreaType.household: return 'HOUSEHOLD';
      case AreaType.personalCare: return 'PERSONAL_CARE';
    }
  }

  String get label {
    switch (this) {
      case AreaType.pantry: return 'Pantry';
      case AreaType.fridge: return 'Fridge';
      case AreaType.freezer: return 'Freezer';
      case AreaType.spirits: return 'Home Bar';
      case AreaType.household: return 'Household';
      case AreaType.personalCare: return 'Personal Care';
    }
  }

  static AreaType fromDb(String value) {
    switch (value.toUpperCase()) {
      case 'PANTRY': return AreaType.pantry;
      case 'FRIDGE': return AreaType.fridge;
      case 'FREEZER': return AreaType.freezer;
      case 'SPIRITS': return AreaType.spirits;
      case 'HOUSEHOLD': return AreaType.household;
      case 'PERSONAL_CARE': return AreaType.personalCare;
      default: throw Exception('Unknown area_type value: $value');
    }
  }
}