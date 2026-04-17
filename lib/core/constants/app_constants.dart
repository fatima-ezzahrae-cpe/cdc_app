enum UserRole {
  president, admin, magistrat, directeur;
  String get label {
    switch (this) {
      case UserRole.president:  return 'Premier Président';
      case UserRole.admin:      return 'Administrateur';
      case UserRole.magistrat:  return 'Magistrat';
      case UserRole.directeur:  return 'Directeur';
    }
  }
  static UserRole fromString(String s) {
    switch (s.toLowerCase()) {
      case 'president':  return UserRole.president;
      case 'admin':      return UserRole.admin;
      case 'directeur':  return UserRole.directeur;
      default:           return UserRole.magistrat;
    }
  }
}

enum EventType { conference, reunion, audit, autre }
