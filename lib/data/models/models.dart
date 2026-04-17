import 'package:cdc_app/core/constants/app_constants.dart';

class AppUser {
  final String   id;
  final String   fullName;
  final String   email;
  final UserRole role;
  final String   department;
  final bool     isActive;
  final bool     mustChangePassword;

  const AppUser({
    required this.id, required this.fullName, required this.email,
    required this.role, required this.department,
    this.isActive = true, this.mustChangePassword = false,
  });

  String get initials {
    final p = fullName.trim().split(' ').where((x) => x.isNotEmpty).toList();
    if (p.isEmpty) return '?';
    if (p.length == 1) return p[0][0].toUpperCase();
    return '${p[0][0]}${p[1][0]}'.toUpperCase();
  }

  AppUser copyWith({UserRole? role, bool? isActive, bool? mustChangePassword}) => AppUser(
    id: id, fullName: fullName, email: email,
    role: role ?? this.role, department: department,
    isActive: isActive ?? this.isActive,
    mustChangePassword: mustChangePassword ?? this.mustChangePassword,
  );

  static AppUser fromMap(Map<String, dynamic> m) => AppUser(
    id: m['id']?.toString() ?? '',
    fullName: m['name'] ?? '',
    email: m['email'] ?? '',
    role: UserRole.fromString(m['role'] ?? 'magistrat'),
    department: m['department'] ?? '',
    isActive: m['is_active'] ?? true,
    mustChangePassword: m['must_change_password'] ?? false,
  );
}

class Mission {
  final String       id;
  final String       titre;
  final String       region;
  final String       ville;
  final String       organisme;
  final DateTime     dateDebut;
  final DateTime     dateFin;
  final List<String> equipe;
  final String       description;
  final String       createdBy;
  final DateTime     createdAt;

  const Mission({
    required this.id, required this.titre, required this.region,
    required this.ville, required this.organisme,
    required this.dateDebut, required this.dateFin,
    required this.equipe, required this.description,
    required this.createdBy, required this.createdAt,
  });

  bool isActiveOn(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    final s   = DateTime(dateDebut.year, dateDebut.month, dateDebut.day);
    final e   = DateTime(dateFin.year, dateFin.month, dateFin.day);
    return !day.isBefore(s) && !day.isAfter(e);
  }

  static Mission fromMap(Map<String, dynamic> m) => Mission(
    id: m['id']?.toString() ?? '',
    titre: m['titre'] ?? '',
    region: m['region'] ?? '',
    ville: m['ville'] ?? '',
    organisme: m['organisme'] ?? '',
    dateDebut: DateTime.tryParse(m['date_debut'] ?? '') ?? DateTime.now(),
    dateFin:   DateTime.tryParse(m['date_fin'] ?? '') ?? DateTime.now(),
    equipe: m['equipe'] != null ? List<String>.from(m['equipe']) : [],
    description: m['description'] ?? '',
    createdBy: m['created_by'] ?? '',
    createdAt: DateTime.tryParse(m['created_at'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'titre': titre, 'region': region, 'ville': ville,
    'organisme': organisme,
    'date_debut': dateDebut.toIso8601String(),
    'date_fin': dateFin.toIso8601String(),
    'equipe': equipe, 'description': description, 'created_by': createdBy,
  };
}

class AppEvent {
  final String       id;
  final String       titre;
  final String       lieu;
  final DateTime     date;
  final String?      heureDebut;
  final String?      heureFin;
  final EventType    type;
  final String       description;
  final List<String> participants;

  const AppEvent({
    required this.id, required this.titre, required this.lieu,
    required this.date, this.heureDebut, this.heureFin,
    required this.type, this.description = '', this.participants = const [],
  });

  String get typeLabel {
    switch (type) {
      case EventType.conference: return 'Conférence';
      case EventType.reunion:    return 'Réunion';
      case EventType.audit:      return 'Audit';
      case EventType.autre:      return 'Événement';
    }
  }

  static AppEvent fromMap(Map<String, dynamic> m) => AppEvent(
    id: m['id']?.toString() ?? '',
    titre: m['titre'] ?? '',
    lieu: m['lieu'] ?? '',
    date: DateTime.tryParse(m['date'] ?? '') ?? DateTime.now(),
    heureDebut: m['heure_debut'],
    heureFin:   m['heure_fin'],
    type: EventType.values.firstWhere(
      (t) => t.name == (m['type'] ?? 'autre'), orElse: () => EventType.autre),
    description: m['description'] ?? '',
    participants: m['participants'] != null ? List<String>.from(m['participants']) : [],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'titre': titre, 'lieu': lieu,
    'date': date.toIso8601String(),
    'heure_debut': heureDebut, 'heure_fin': heureFin,
    'type': type.name, 'description': description, 'participants': participants,
  };
}
