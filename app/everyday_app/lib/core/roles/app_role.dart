enum AppRole {
  HOST,
  COHOST,
  PERSONNEL,
}

extension AppRoleValue on AppRole {
  String get value {
    switch (this) {
      case AppRole.HOST:
        return 'HOST';
      case AppRole.COHOST:
        return 'COHOST';
      case AppRole.PERSONNEL:
        return 'PERSONNEL';
    }
  }
}
