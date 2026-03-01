enum AreaType {
  pantry,
  fridge,
  freezer,
}

extension AreaTypeX on AreaType {
  String get dbValue {
    switch (this) {
      case AreaType.pantry:
        return 'PANTRY';
      case AreaType.fridge:
        return 'FRIDGE';
      case AreaType.freezer:
        return 'FREEZER';
    }
  }

  String get label {
    switch (this) {
      case AreaType.pantry:
        return 'Pantry';
      case AreaType.fridge:
        return 'Fridge';
      case AreaType.freezer:
        return 'Freezer';
    }
  }

  static AreaType fromDb(String value) {
    switch (value.toUpperCase()) {
      case 'PANTRY':
        return AreaType.pantry;
      case 'FRIDGE':
        return AreaType.fridge;
      case 'FREEZER':
        return AreaType.freezer;
      default:
        throw Exception('Unknown area_type value: $value');
    }
  }
}
