import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Habit {
  final String id;
  String title;
  List<String> days; // 요일: ["Mon", "Tue", ...]
  String? memo;
  TimeOfDay? alarmTime;
  bool isCompletedToday;
  final DateTime createdAt;

  Habit({
    String? id,
    required this.title,
    required this.days,
    this.memo,
    this.alarmTime,
    this.isCompletedToday = false,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(), // UUID 생성
        createdAt = createdAt ?? DateTime.now();

  Habit copyWith({
    String? id,
    String? title,
    List<String>? days,
    TimeOfDay? alarmTime,
    String? memo,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      days: days ?? this.days,
      alarmTime: alarmTime ?? this.alarmTime,
      memo: memo ?? this.memo,
    );
  }

  // JSON 직렬화 (저장용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'days': days,
      'memo': memo,
      'alarmHour': alarmTime?.hour,
      'alarmMinute': alarmTime?.minute,
      'isCompletedToday': isCompletedToday,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // JSON 역직렬화
  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      title: json['title'],
      days: List<String>.from(json['days']),
      memo: json['memo'],
      alarmTime: (json['alarmHour'] != null && json['alarmMinute'] != null)
          ? TimeOfDay(hour: json['alarmHour'], minute: json['alarmMinute'])
          : null,
      isCompletedToday: json['isCompletedToday'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}