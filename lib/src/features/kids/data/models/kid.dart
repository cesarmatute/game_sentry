import 'package:appwrite/models.dart';
import 'package:equatable/equatable.dart';

class Kid extends Equatable {
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
  final bool enforceBrush;
  final bool enforceLunchBreak;
  final DateTime? lastMandatoryBreak;
  /// Time played today in seconds (replaces daily_status_daily_played)
  final int dailyPlayed;
  final DateTime? lastDatePlayed;
  /// Session time played in seconds (replaces daily_status_session_played_since_break)
  final int sessionPlayed;
  final DateTime? lastBreakTime;
  final Duration bankedTime;
  final Duration maxBankedTime;
  final bool hasHadLunchToday;
  final bool hasBrushedTeethAfterLunch;

  const Kid({
    required this.id,
    required this.parentId,
    required this.username,
    this.dob,
    this.avatarUrl,
    required this.hasPin,
    this.maximumDailyLimit = 210, // 210 minutes default
    this.maximumSessionLimit = 120, // 120 minutes default  
    this.minimumBreak = 60, // 60 minutes default
    this.playtimeStart = "12:00", // Default to 12:00
    this.playtimeEnd = "22:00", // Default to 22:00
    this.lunchBreakStart = "12:30", // Default to 12:30
    this.lunchBreakEnd = "14:00", // Default to 14:00
    this.enforceBrush = false,
    this.enforceLunchBreak = true,
    this.lastMandatoryBreak,
    this.dailyPlayed = 0,
    this.lastDatePlayed,
    this.sessionPlayed = 0,
    this.lastBreakTime,
    this.bankedTime = Duration.zero,
    this.maxBankedTime = const Duration(hours: 2), // Default 2 hours max bank time
    this.hasHadLunchToday = false,
    this.hasBrushedTeethAfterLunch = false,
  });

  factory Kid.fromDocument(Document document) {
    return Kid(
      id: document.$id,
      parentId: (document.data['parent_id'] is String) ? document.data['parent_id'] as String : '',
      username: document.data['username'] ?? '',
      dob: document.data['dob'] != null ? DateTime.parse(document.data['dob'] as String) : null,
      avatarUrl: document.data['avatar_url'] as String?,
      hasPin: document.data['has_pin'] as bool? ?? false,
      maximumDailyLimit: document.data['maximum_daily_limit'] as int? ?? 210,
      maximumSessionLimit: document.data['maximum_session_limit'] as int? ?? 120,
      minimumBreak: document.data['minimum_break'] as int? ?? 60,
      playtimeStart: document.data['playtime_start'] as String? ?? "12:00",
      playtimeEnd: document.data['playtime_end'] as String? ?? "22:00",
      lunchBreakStart: document.data['lunch_break_start'] as String? ?? "12:30",
      lunchBreakEnd: document.data['lunch_break_end'] as String? ?? "14:00",
      enforceBrush: document.data['enforce_brush'] as bool? ?? false,
      enforceLunchBreak: document.data['enforce_lunch_break'] as bool? ?? true,
      lastMandatoryBreak: document.data['last_mandatory_break'] != null ? DateTime.parse(document.data['last_mandatory_break'] as String) : null,
      dailyPlayed: document.data['daily_played'] as int? ?? 0,
      lastDatePlayed: document.data['last_date_played'] != null ? DateTime.parse(document.data['last_date_played'] as String) : null,
      sessionPlayed: document.data['session_played'] as int? ?? 0,
      lastBreakTime: document.data['last_break_time'] != null ? DateTime.parse(document.data['last_break_time'] as String) : null,
      bankedTime: Duration(minutes: document.data['banked_time'] as int? ?? 0),
      maxBankedTime: Duration(hours: document.data['max_banked_time'] as int? ?? 2),
      hasHadLunchToday: document.data['has_had_lunch_today'] as bool? ?? false,
      hasBrushedTeethAfterLunch: document.data['has_brushed_teeth_after_lunch'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
      'enforce_brush': enforceBrush,
      'enforce_lunch_break': enforceLunchBreak,
      'last_mandatory_break': lastMandatoryBreak?.toIso8601String(),
      'daily_played': dailyPlayed,
      'last_date_played': lastDatePlayed?.toIso8601String(),
      'session_played': sessionPlayed,
      'last_break_time': lastBreakTime?.toIso8601String(),
      'banked_time': bankedTime.inMinutes,
      'max_banked_time': maxBankedTime.inHours,
      'has_had_lunch_today': hasHadLunchToday,
      'has_brushed_teeth_after_lunch': hasBrushedTeethAfterLunch,
    };
  }

  @override
  List<Object?> get props => [
        id,
        parentId,
        username,
        dob,
        avatarUrl,
        hasPin,
        maximumDailyLimit,
        maximumSessionLimit,
        minimumBreak,
        playtimeStart,
        playtimeEnd,
        lunchBreakStart,
        lunchBreakEnd,
        enforceBrush,
        enforceLunchBreak,
        lastMandatoryBreak,
        dailyPlayed,
        lastDatePlayed,
        sessionPlayed,
        lastBreakTime,
        bankedTime,
        maxBankedTime,
        hasHadLunchToday,
        hasBrushedTeethAfterLunch,
      ];

  Kid copyWith({
    String? id,
    String? parentId,
    String? username,
    DateTime? dob,
    String? avatarUrl,
    bool? hasPin,
    int? maximumDailyLimit,
    int? maximumSessionLimit,
    int? minimumBreak,
    String? playtimeStart,
    String? playtimeEnd,
    String? lunchBreakStart,
    String? lunchBreakEnd,
    bool? enforceBrush,
    bool? enforceLunchBreak,
    DateTime? lastMandatoryBreak,
    int? dailyPlayed,
    DateTime? lastDatePlayed,
    int? sessionPlayed,
    DateTime? lastBreakTime,
    Duration? bankedTime,
    Duration? maxBankedTime,
    bool? hasHadLunchToday,
    bool? hasBrushedTeethAfterLunch,
  }) {
    return Kid(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      username: username ?? this.username,
      dob: dob ?? this.dob,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      hasPin: hasPin ?? this.hasPin,
      maximumDailyLimit: maximumDailyLimit ?? this.maximumDailyLimit,
      maximumSessionLimit: maximumSessionLimit ?? this.maximumSessionLimit,
      minimumBreak: minimumBreak ?? this.minimumBreak,
      playtimeStart: playtimeStart ?? this.playtimeStart,
      playtimeEnd: playtimeEnd ?? this.playtimeEnd,
      lunchBreakStart: lunchBreakStart ?? this.lunchBreakStart,
      lunchBreakEnd: lunchBreakEnd ?? this.lunchBreakEnd,
      enforceBrush: enforceBrush ?? this.enforceBrush,
      enforceLunchBreak: enforceLunchBreak ?? this.enforceLunchBreak,
      lastMandatoryBreak: lastMandatoryBreak ?? this.lastMandatoryBreak,
      dailyPlayed: dailyPlayed ?? this.dailyPlayed,
      lastDatePlayed: lastDatePlayed ?? this.lastDatePlayed,
      sessionPlayed: sessionPlayed ?? this.sessionPlayed,
      lastBreakTime: lastBreakTime ?? this.lastBreakTime,
      bankedTime: bankedTime ?? this.bankedTime,
      maxBankedTime: maxBankedTime ?? this.maxBankedTime,
      hasHadLunchToday: hasHadLunchToday ?? this.hasHadLunchToday,
      hasBrushedTeethAfterLunch: hasBrushedTeethAfterLunch ?? this.hasBrushedTeethAfterLunch,
    );
  }
}