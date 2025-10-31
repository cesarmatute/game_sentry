class KidModel {
  final String id;
  final String parentId;
  final String username;
  final DateTime? dob;
  final String? avatarUrl;
  final bool hasPin;
  final int maximumDailyLimit;
  final int maximumSessionLimit;
  final int minimumBreak;
  final String playtimeStart;
  final String playtimeEnd;
  final String lunchBreakStart;
  final String lunchBreakEnd;
  final List<String>? sessions;
  final bool enforceBrush;
  final bool enforceLunchBreak;
  final DateTime? lastMandatoryBreak;
  final int? dailyPlayed;
  final DateTime? lastDatePlayed;
  final int? sessionPlayed;
  final DateTime? lastBreakTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  KidModel({
    required this.id,
    required this.parentId,
    required this.username,
    this.dob,
    this.avatarUrl,
    required this.hasPin,
    required this.maximumDailyLimit,
    required this.maximumSessionLimit,
    required this.minimumBreak,
    required this.playtimeStart,
    required this.playtimeEnd,
    required this.lunchBreakStart,
    required this.lunchBreakEnd,
    this.sessions,
    required this.enforceBrush,
    required this.enforceLunchBreak,
    this.lastMandatoryBreak,
    this.dailyPlayed,
    this.lastDatePlayed,
    this.sessionPlayed,
    this.lastBreakTime,
    this.createdAt,
    this.updatedAt,
  });

  factory KidModel.fromMap(Map<String, dynamic> map) {
    return KidModel(
      id: map[r'$id'],
      parentId: map['parent_id'] as String,
      username: map['username'] as String,
      dob: map['dob'] != null ? DateTime.parse(map['dob'] as String) : null,
      avatarUrl: map['avatar_url'] as String?,
      hasPin: map['has_pin'] as bool? ?? false,
      maximumDailyLimit: map['maximum_daily_limit'] as int? ?? 210,
      maximumSessionLimit: map['maximum_session_limit'] as int? ?? 120,
      minimumBreak: map['minimum_break'] as int? ?? 60,
      playtimeStart: map['playtime_start'] as String? ?? '12:00',
      playtimeEnd: map['playtime_end'] as String? ?? '22:00',
      lunchBreakStart: map['lunch_break_start'] as String? ?? '12:30',
      lunchBreakEnd: map['lunch_break_end'] as String? ?? '14:00',
      sessions: (map['sessions'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      enforceBrush: map['enforce_brush'] as bool? ?? false,
      enforceLunchBreak: map['enforce_lunch_break'] as bool? ?? true,
      lastMandatoryBreak: map['last_mandatory_break'] != null ? DateTime.parse(map['last_mandatory_break'] as String) : null,
      dailyPlayed: map['daily_played'] as int?,
      lastDatePlayed: map['last_date_played'] != null ? DateTime.parse(map['last_date_played'] as String) : null,
      sessionPlayed: map['session_played'] as int?,
      lastBreakTime: map['last_break_time'] != null ? DateTime.parse(map['last_break_time'] as String) : null,
      createdAt: map[r'$createdAt'] != null ? DateTime.parse(map[r'$createdAt'] as String) : null,
      updatedAt: map[r'$updatedAt'] != null ? DateTime.parse(map[r'$updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'parent_id': parentId,
        'username': username,
        'dob': dob?.toIso8601String(),
        'avatar_url': avatarUrl,
        'has_pin': hasPin,
        'maximum_daily_limit': maximumDailyLimit,
        'maximum_session_limit': maximumSessionLimit,
        'minimum_break': minimumBreak,
        'playtime_start': playtimeStart,
        'playtime_end': playtimeEnd,
        'lunch_break_start': lunchBreakStart,
        'lunch_break_end': lunchBreakEnd,
        'sessions': sessions,
        'enforce_brush': enforceBrush,
        'enforce_lunch_break': enforceLunchBreak,
        'last_mandatory_break': lastMandatoryBreak?.toIso8601String(),
        'daily_played': dailyPlayed,
        'last_date_played': lastDatePlayed?.toIso8601String(),
        'session_played': sessionPlayed,
        'last_break_time': lastBreakTime?.toIso8601String(),
      };
}