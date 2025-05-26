import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../main.dart';
import '../models/habit.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;


class HabitProvider with ChangeNotifier {
  final List<Habit> _habits = [];

  List<Habit> get habits => List.unmodifiable(_habits);

  void addHabit(String title, List<String> days, TimeOfDay? alarmTime, {String memo = ''}) {
    final newHabit = Habit(
      id: Uuid().v4(),
      title: title,
      days: days,
      alarmTime: alarmTime,
      memo: memo,
    );
    _habits.add(newHabit);
    if (alarmTime != null) {
      scheduleDailyNotification(newHabit.id, newHabit.title, alarmTime);
    }
    saveHabits();
    notifyListeners();
  }

  void toggleCompletion(String id) {
    final index = _habits.indexWhere((habit) => habit.id == id);
    if (index != -1) {
      _habits[index].isCompletedToday = !_habits[index].isCompletedToday;
      saveHabits();
      notifyListeners();
    }
  }

  void updateHabit(Habit updatedHabit) {
    final index = _habits.indexWhere((habit) => habit.id == updatedHabit.id);
    if (index != -1) {
      _habits[index] = updatedHabit;
      flutterLocalNotificationsPlugin.cancel(updatedHabit.id.hashCode);
      if (updatedHabit.alarmTime != null) {
        scheduleDailyNotification(updatedHabit.id, updatedHabit.title, updatedHabit.alarmTime!);
      }
      saveHabits();
      notifyListeners();
    }
  }

  void removeHabit(String id) {
    _habits.removeWhere((habit) => habit.id == id);
    flutterLocalNotificationsPlugin.cancel(id.hashCode);
    saveHabits();
    notifyListeners();
  }

  Future<void> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final habitList = prefs.getStringList('habits') ?? [];

    _habits.clear(); // 기존 리스트 비우기
    _habits.addAll(
      habitList.map((habitJson) => Habit.fromJson(json.decode(habitJson))),
    );

    notifyListeners();
  }

  Future<void> saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final habitList = _habits.map((habit) => json.encode(habit.toJson())).toList();

    await prefs.setStringList('habits', habitList);
  }

  Future<void> scheduleDailyNotification(
      String id,
      String title,
      TimeOfDay alarmTime,
      ) async {
    // 현재 시간 가져오기
    final now = DateTime.now();

    // 기본 시간 구성
    final scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      alarmTime.hour,
      alarmTime.minute,
    );

    // 이미 지난 시간이라면 내일로 설정
    final scheduled = scheduledDate.isBefore(now)
        ? scheduledDate.add(const Duration(days: 1))
        : scheduledDate;

    // zonedSchedule을 위해 tz.TZDateTime 변환
    final tz.TZDateTime tzScheduled =
    tz.TZDateTime.from(scheduled, tz.local); // <-- 핵심 수정

    const androidDetails = AndroidNotificationDetails(
      'habit_channel_id',
      'Habit Notifications',
      channelDescription: 'Notification channel for habit reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    const platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id.hashCode, // 고유 ID
      '오늘의 습관!', // 제목
      '$title 실천할 시간이에요!', // 본문
      tzScheduled, // <-- 수정된 타입
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // ✅ 최신 방식
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 매일 반복
    );
  }
}