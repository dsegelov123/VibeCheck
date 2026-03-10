import 'dart:convert';

/// A single piece of information remembered about the user.
class UserFact {
  final String text;
  final String sourceCompanionId; // The ID of the companion who learned it
  final DateTime timestamp;

  const UserFact({
    required this.text,
    required this.sourceCompanionId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'source': sourceCompanionId,
        'time': timestamp.toIso8601String(),
      };

  factory UserFact.fromJson(Map<String, dynamic> json) {
    return UserFact(
      text: json['text'] as String,
      sourceCompanionId: json['source'] as String,
      timestamp: DateTime.parse(json['time'] as String),
    );
  }

  UserFact copyWith({String? text}) => UserFact(
        text: text ?? this.text,
        sourceCompanionId: sourceCompanionId,
        timestamp: timestamp,
      );
}

/// Stores persistently-remembered facts about the user.
class UserProfile {
  final String? name;
  final List<UserFact> activeFacts;
  final List<UserFact> archivedFacts;
  final List<String> pendingCheckIns;

  const UserProfile({
    this.name,
    this.activeFacts = const [],
    this.archivedFacts = const [],
    this.pendingCheckIns = const [],
  });

  UserProfile copyWith({
    String? name,
    List<UserFact>? activeFacts,
    List<UserFact>? archivedFacts,
    List<String>? pendingCheckIns,
  }) {
    return UserProfile(
      name: name ?? this.name,
      activeFacts: activeFacts ?? this.activeFacts,
      archivedFacts: archivedFacts ?? this.archivedFacts,
      pendingCheckIns: pendingCheckIns ?? this.pendingCheckIns,
    );
  }

  /// Merges reconciled lists from GPT into this profile.
  /// GPT provides strings; we match/wrap them or preserve existing UserFact metadata.
  UserProfile merge(Map<String, dynamic> delta, String lastCompanionId) {
    final newName = (delta['name'] as String?)?.trim().isNotEmpty == true
        ? delta['name'] as String
        : name;

    UserFact _findOrWrap(String text, List<UserFact> existing) {
      final match = existing.firstWhere(
        (e) => e.text.toLowerCase() == text.toLowerCase(),
        orElse: () => UserFact(
          text: text,
          sourceCompanionId: lastCompanionId,
          timestamp: DateTime.now(),
        ),
      );
      return match;
    }

    List<UserFact> newActive = activeFacts;
    if (delta['active'] is List) {
      final List<UserFact> combined = [...activeFacts, ...archivedFacts];
      newActive = (delta['active'] as List)
          .map((f) => _findOrWrap(f.toString().trim(), combined))
          .toList();
    }

    List<UserFact> newArchived = archivedFacts;
    if (delta['archived'] is List) {
      final List<UserFact> combined = [...activeFacts, ...archivedFacts];
      newArchived = (delta['archived'] as List)
          .map((f) => _findOrWrap(f.toString().trim(), combined))
          .toList();
    }

    List<String> newCheckIns = [];
    if (delta['check_ins'] is List) {
      newCheckIns = (delta['check_ins'] as List).map((e) => e.toString()).toList();
    }

    // Safety caps
    if (newActive.length > 15) newActive = newActive.sublist(newActive.length - 15);
    if (newArchived.length > 60) newArchived = newArchived.sublist(newArchived.length - 60);

    return UserProfile(
      name: newName,
      activeFacts: newActive,
      archivedFacts: newArchived,
      pendingCheckIns: newCheckIns,
    );
  }

  bool get isEmpty => name == null && activeFacts.isEmpty && archivedFacts.isEmpty && pendingCheckIns.isEmpty;

  Map<String, dynamic> toJson() => {
        'name': name,
        'active': activeFacts.map((e) => e.toJson()).toList(),
        'archived': archivedFacts.map((e) => e.toJson()).toList(),
        'check_ins': pendingCheckIns,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String?,
      activeFacts: _parseFactList(json['active']),
      archivedFacts: _parseFactList(json['archived']),
      pendingCheckIns: _parseStringList(json['check_ins']),
    );
  }

  static List<UserFact> _parseFactList(dynamic list) {
    if (list is! List) return [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => UserFact.fromJson(e))
        .toList();
  }

  static List<String> _parseStringList(dynamic list) {
    if (list is! List) return [];
    return list.map((e) => e.toString()).toList();
  }

  factory UserProfile.empty() => const UserProfile();

  factory UserProfile.fromJsonString(String str) {
    return UserProfile.fromJson(jsonDecode(str) as Map<String, dynamic>);
  }

  String toJsonString() => jsonEncode(toJson());
}
