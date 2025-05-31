import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart'; // kIsWeb 확인용
import '../main.dart';
import '../models/habit.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:async'; // Timer

/// HabitProvider 클래스: 습관 데이터 관리 및 알림 스케줄링 담당
class HabitProvider with ChangeNotifier {
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  final List<Habit> _habits = []; // 습관 목록

  /// 습관 목록을 읽기 전용으로 제공
  List<Habit> get habits => List.unmodifiable(_habits);

  /// 🔥 요일 문자열 -> 숫자 매핑
  final Map<String, int> _weekdayMap = {
    '월': DateTime.monday,
    '화': DateTime.tuesday,
    '수': DateTime.wednesday,
    '목': DateTime.thursday,
    '금': DateTime.friday,
    '토': DateTime.saturday,
    '일': DateTime.sunday,
  };

  /// 새로운 습관 추가
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
      scheduleWeeklyNotification(newHabit.id, newHabit.title, alarmTime, days);
    }

    saveHabits();
    notifyListeners();
  }

  void toggleCompletion(String id, DateTime targetDate) {
    final index = _habits.indexWhere((habit) => habit.id == id);
    if (index != -1) {
      final today = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      final todayWeekdayStr = weekdays[today.weekday - 1];
      final dateStr = formatter.format(today); // ✅ 오늘 날짜 문자열 (2025-05-31)

      final habit = _habits[index];

      // 오늘 요일에 포함되어 있지 않으면 리턴
      if (!habit.days.contains(todayWeekdayStr)) {
        return;
      }

      final updatedDailyCompletion = Map<String, bool>.from(habit.dailyCompletion);

      bool isCompleted;
      DateTime? lastCompletedDate;
      if (habit.lastCompletedDate == null || habit.lastCompletedDate!.isBefore(today)) {
        isCompleted = true;
        lastCompletedDate = today;
        updatedDailyCompletion[dateStr] = true; // ✅ 날짜 키로 저장
      } else if (habit.lastCompletedDate == today && habit.dailyCompletion[dateStr] == true) {
        isCompleted = false;
        lastCompletedDate = null;
        updatedDailyCompletion[dateStr] = false; // ✅ 날짜 키로 저장
      } else {
        isCompleted = habit.isCompletedToday;
        lastCompletedDate = habit.lastCompletedDate;
      }

      final updatedHabit = habit.copyWith(
        isCompletedToday: isCompleted,
        lastCompletedDate: lastCompletedDate,
        dailyCompletion: updatedDailyCompletion,
      );

      _habits[index] = updatedHabit;

      saveHabits();
      notifyListeners();
    }
  }

  void updateHabit(Habit updatedHabit) {
    final index = _habits.indexWhere((habit) => habit.id == updatedHabit.id);
    if (index != -1) {
      final habitToSave = updatedHabit.copyWith(isCompletedToday: false);
      _habits[index] = habitToSave;

      if (!kIsWeb) {
        flutterLocalNotificationsPlugin.cancel(updatedHabit.id.hashCode);
      }
      if (updatedHabit.alarmTime != null) {
        scheduleWeeklyNotification(
          updatedHabit.id,
          updatedHabit.title,
          updatedHabit.alarmTime!,
          updatedHabit.days,
        );
      }

      saveHabits();
      notifyListeners();
    }
  }

  void removeHabit(String id) {
    _habits.removeWhere((habit) => habit.id == id);
    if (!kIsWeb) {
      flutterLocalNotificationsPlugin.cancel(id.hashCode);
    }
    saveHabits();
    notifyListeners();
  }

  Future<void> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final habitList = prefs.getStringList('habits') ?? [];
    _habits.clear();
    _habits.addAll(habitList.map((habitJson) => Habit.fromJson(json.decode(habitJson))));
    notifyListeners();
  }

  Future<void> saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final habitList = _habits.map((habit) => json.encode(habit.toJson())).toList();
    await prefs.setStringList('habits', habitList);
  }

  Future<void> scheduleWeeklyNotification(
      String id,
      String title,
      TimeOfDay alarmTime,
      List<String> days,
      ) async {
    if (kIsWeb) {
      debugPrint('[웹 테스트] 알림 예약됨: $title - 요일: $days, 시간: ${alarmTime.hour}:${alarmTime.minute}');
      final now = DateTime.now();
      for (String day in days) {
        int weekday = _weekdayMap[day]!;
        int daysUntilNext = (weekday - now.weekday + 7) % 7;

        DateTime scheduledDateTime = now.add(Duration(days: daysUntilNext)).copyWith(
          hour: alarmTime.hour,
          minute: alarmTime.minute,
          second: 0,
          millisecond: 0,
        );

        if (daysUntilNext == 0 && scheduledDateTime.isBefore(now)) {
          scheduledDateTime = scheduledDateTime.add(Duration(days: 7));
        }

        final delay = scheduledDateTime.difference(now);
        Timer(delay, () {
          debugPrint('[웹 테스트] 알림이 울릴 시간입니다! 습관: $title (${day}요일)');
        });
      }
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'habit_channel_id',
      'Habit Notifications',
      channelDescription: 'Notification channel for habit reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    const platformDetails = NotificationDetails(android: androidDetails);

    for (String day in days) {
      int? weekday = _weekdayMap[day];
      if (weekday == null) continue;

      final now = DateTime.now();
      int daysUntilNext = (weekday - now.weekday + 7) % 7;

      if (daysUntilNext == 0) {
        final scheduledToday = DateTime(
          now.year,
          now.month,
          now.day,
          alarmTime.hour,
          alarmTime.minute,
        );
        if (scheduledToday.isBefore(now)) {
          daysUntilNext = 7;
        }
      }

      final nextDate = now.add(Duration(days: daysUntilNext));
      final scheduledDateTime = DateTime(
        nextDate.year,
        nextDate.month,
        nextDate.day,
        alarmTime.hour,
        alarmTime.minute,
      );

      final tz.TZDateTime tzScheduled =
      tz.TZDateTime.from(scheduledDateTime, tz.local);

      final notificationId = (id + day).hashCode;

      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        '오늘의 습관!',
        '$title 실천할 시간이에요!',
        tzScheduled,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  /// 오늘 달성률 계산
  double calculateTodayCompletionRate(List<Habit> habits) {
    final today = formatter.format(DateTime.now());
    final todayWeekday = DateTime.now().weekday;
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final todayStr = weekdays[todayWeekday - 1];

    final todayHabits = habits.where((habit) => habit.days.contains(todayStr)).toList();
    if (todayHabits.isEmpty) return 0;

    final completedCount =
        todayHabits.where((habit) => habit.dailyCompletion[today] == true).length;

    return completedCount / todayHabits.length * 100;
  }

  /// 최근 7일 달성률 리스트 반환
  List<double> calculateLast7DaysCompletionRate(List<Habit> habits) {
    final List<double> rates = [];
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = formatter.format(date);
      final weekdayStr = weekdays[date.weekday - 1];

      final dayHabits =
      habits.where((habit) => habit.days.contains(weekdayStr)).toList();
      if (dayHabits.isEmpty) {
        rates.add(0);
        continue;
      }

      final completedCount =
          dayHabits.where((habit) => habit.dailyCompletion[dateStr] == true).length;
      final rate = completedCount / dayHabits.length * 100;
      rates.add(rate);
    }
    return rates;
  }
}