import 'package:appwrite/models.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum SessionStatus { active, paused, completed, interrupted }

class GamingSession extends Equatable {
  final String id;
  final String kidId;
  final SessionStatus status;
  final DateTime? date;
  final TimeOfDay startTime;
  final int startSecond;
  final TimeOfDay? stopTime;
  final int? stopSecond;
  final Duration? duration;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GamingSession({
    required this.id,
    required this.kidId,
    required this.status,
    this.date,
    required this.startTime,
    required this.startSecond,
    this.stopTime,
    this.stopSecond,
    this.duration,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GamingSession.fromDocument(Document document) {
    // Convert boolean status field to our enum
    // In Appwrite: true = active, false = completed
    final isActive = document.data['status'] as bool? ?? false;
    
    debugPrint('Parsing document ${document.$id}: ${document.data}');

    String coerceToString(dynamic v) {
      if (v == null) return '';
      if (v is String) return v;
      if (v is Map<String, dynamic>) {
        // Relation or object with $id
        return (v['\$id'] as String?) ?? (v['id'] as String?) ?? v.toString();
      }
      if (v is List) {
        if (v.isEmpty) return '';
        final first = v.first;
        return coerceToString(first);
      }
      return v.toString();
    }

    String coerceToTimeString(dynamic v) {
      final s = coerceToString(v);
      return s.isNotEmpty ? s : '00:00:00';
    }

    DateTime? coerceToDate(dynamic v) {
      final s = coerceToString(v);
      if (s.isEmpty) return null;
      try {
        // Accept either full ISO or YYYY-MM-DD
        return DateTime.parse(s.length > 10 ? s : '${s}T00:00:00.000');
      } catch (_) {
        return null;
      }
    }

    int coerceToIntMinutes(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      final s = coerceToString(v);
      return int.tryParse(s) ?? 0;
    }
    
    return GamingSession(
      id: document.$id,
      kidId: coerceToString(document.data['kid_id']),
      status: isActive ? SessionStatus.active : SessionStatus.completed,
      date: coerceToDate(document.data['date']),
      startTime: _parseTimeOfDay(coerceToTimeString(document.data['start_time'])),
      startSecond: _parseSecond(coerceToTimeString(document.data['start_time'])),
      stopTime: (() {
        final s = coerceToTimeString(document.data['stop_time']);
        return s.isNotEmpty ? _parseTimeOfDay(s) : null;
      })(),
      stopSecond: (() {
        final s = coerceToTimeString(document.data['stop_time']);
        return s.isNotEmpty ? _parseSecond(s) : null;
      })(),
      duration: (() {
        final minutes = coerceToIntMinutes(document.data['duration']);
        return minutes > 0 ? Duration(minutes: minutes) : null;
      })(),
      createdAt: DateTime.parse(document.$createdAt),
      updatedAt: DateTime.parse(document.$updatedAt),
    );
  }

  static TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]), 
      minute: int.parse(parts[1]),
    );
  }

  static int _parseSecond(String timeString) {
    final parts = timeString.split(':');
    if (parts.length > 2) {
      return int.parse(parts[2]);
    }
    return 0;
  }

  static String _formatTimeOfDay(TimeOfDay time, int second) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'kid_id': kidId,
      'status': status == SessionStatus.active, // Convert to boolean: true = active, false = completed
      'date': date?.toIso8601String().split('T')[0], // Store only date part
      'start_time': _formatTimeOfDay(startTime, startSecond),
      'stop_time': stopTime != null ? _formatTimeOfDay(stopTime!, stopSecond ?? 0) : '',
      'duration': duration?.inMinutes ?? 0,
    };
  }

  GamingSession copyWith({
    String? id,
    String? kidId,
    SessionStatus? status,
    DateTime? date,
    TimeOfDay? startTime,
    int? startSecond,
    TimeOfDay? stopTime,
    int? stopSecond,
    Duration? duration,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GamingSession(
      id: id ?? this.id,
      kidId: kidId ?? this.kidId,
      status: status ?? this.status,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      startSecond: startSecond ?? this.startSecond,
      stopTime: stopTime ?? this.stopTime,
      stopSecond: stopSecond ?? this.stopSecond,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to get full start DateTime
  DateTime get fullStartDateTime {
    final sessionDate = date ?? DateTime.now();
    return DateTime(
      sessionDate.year,
      sessionDate.month,
      sessionDate.day,
      startTime.hour,
      startTime.minute,
      startSecond,
    );
  }

  // Helper method to get full stop DateTime (if available)
  DateTime? get fullStopDateTime {
    if (stopTime == null) return null;
    final sessionDate = date ?? DateTime.now();
    return DateTime(
      sessionDate.year,
      sessionDate.month,
      sessionDate.day,
      stopTime!.hour,
      stopTime!.minute,
      stopSecond ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        kidId,
        status,
        date,
        startTime,
        startSecond,
        stopTime,
        stopSecond,
        duration,
        createdAt,
        updatedAt,
      ];
}