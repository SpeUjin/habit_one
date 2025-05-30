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
      id: Uuid().v4(), // 고유 ID 생성
      title: title,
      days: days,
      alarmTime: alarmTime,
      memo: memo,
    );
    _habits.add(newHabit);

    // 알람 시간이 지정되었으면 예약
    if (alarmTime != null) {
      scheduleWeeklyNotification(newHabit.id, newHabit.title, alarmTime, days);
    }

    saveHabits(); // 저장
    notifyListeners(); // UI 갱신
  }

  void toggleCompletion(String id) {
    final index = _habits.indexWhere((habit) => habit.id == id);
    if (index != -1) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = formatter.format(now); // 통계 로직과 같은 포맷으로 저장!

      final habit = _habits[index];

      if (habit.lastCompletedDate == null || habit.lastCompletedDate!.isBefore(today)) {
        habit.isCompletedToday = true;
        habit.lastCompletedDate = today;

        // ✅ 통계 로직과 맞춰서 기록!
        habit.dailyCompletion[todayStr] = true;
      } else {
        // 완료 취소
        habit.isCompletedToday = false;
        habit.lastCompletedDate = null;

        // ✅ 통계 로직과 맞춰서 삭제 또는 false로 설정
        habit.dailyCompletion[todayStr] = false;
      }

      saveHabits();
      notifyListeners();
    }
  }

  /// 기존 습관 업데이트 (업데이트 시 완료 상태 초기화)
  void updateHabit(Habit updatedHabit) {
    final index = _habits.indexWhere((habit) => habit.id == updatedHabit.id);
    if (index != -1) {
      // 업데이트할 때 isCompletedToday를 무조건 false로 설정
      final habitToSave = updatedHabit.copyWith(isCompletedToday: false);
      _habits[index] = habitToSave;

      // 웹 환경이 아닌 경우, 기존 알림을 취소하고 새로 예약
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

  /// 습관 삭제
  void removeHabit(String id) {
    _habits.removeWhere((habit) => habit.id == id);

    // 모바일 환경이라면 알림도 취소
    if (!kIsWeb) {
      flutterLocalNotificationsPlugin.cancel(id.hashCode);
    }

    saveHabits();
    notifyListeners();
  }

  /// 로컬에서 습관 데이터 로드
  Future<void> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final habitList = prefs.getStringList('habits') ?? [];

    _habits.clear();
    _habits.addAll(
      habitList.map((habitJson) => Habit.fromJson(json.decode(habitJson))),
    );

    notifyListeners();
  }

  /// 로컬에 습관 데이터 저장
  Future<void> saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final habitList = _habits.map((habit) => json.encode(habit.toJson())).toList();
    await prefs.setStringList('habits', habitList);
  }

  /// 알림 스케줄링 (요일 반복)
  ///
  /// 📌 웹 환경에서는 실제로 알림을 예약할 수 없으므로 로그로 대체!
  Future<void> scheduleWeeklyNotification(
      String id,
      String title,
      TimeOfDay alarmTime,
      List<String> days,
      ) async {
    if (kIsWeb) {
      debugPrint('[웹 테스트] 알림 예약됨: $title - 요일: $days, 시간: ${alarmTime.hour}:${alarmTime.minute}');

      // 오늘/다음 알림까지의 시간 계산
      final now = DateTime.now();
      for (String day in days) {
        print('[디버깅] day 값: $day');
        int weekday = _weekdayMap[day]!;
        int daysUntilNext = (weekday - now.weekday + 7) % 7;

        DateTime scheduledDateTime = now.add(Duration(days: daysUntilNext)).copyWith(
          hour: alarmTime.hour,
          minute: alarmTime.minute,
          second: 0,
          millisecond: 0,
        );

        // 오늘인데 이미 지났으면 다음 주
        if (daysUntilNext == 0 && scheduledDateTime.isBefore(now)) {
          scheduledDateTime = scheduledDateTime.add(Duration(days: 7));
        }

        final delay = scheduledDateTime.difference(now);

        // 실제로 시간에 맞춰서 로그 출력
        Timer(delay, () {
          debugPrint('[웹 테스트] 알림이 울릴 시간입니다! 습관: $title (${day}요일)');
        });
      }
      return;
    }

    // 2️⃣ 각 요일 이름을 weekday 번호로 매핑
    final Map<String, int> weekdayMap = {
      '월': DateTime.monday,
      '화': DateTime.tuesday,
      '수': DateTime.wednesday,
      '목': DateTime.thursday,
      '금': DateTime.friday,
      '토': DateTime.saturday,
      '일': DateTime.sunday,
    };

    // 3️⃣ 알림 상세 설정 (Android)
    const androidDetails = AndroidNotificationDetails(
      'habit_channel_id',
      'Habit Notifications',
      channelDescription: 'Notification channel for habit reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    const platformDetails = NotificationDetails(android: androidDetails);

    // 4️⃣ 선택된 요일마다 알림 예약
    for (String day in days) {
      int? weekday = weekdayMap[day];
      if (weekday == null) continue; // 요일 매칭 안되면 스킵

      final now = DateTime.now();

      // 오늘/다음 알림까지의 날짜 차이 계산
      int daysUntilNext = (weekday - now.weekday + 7) % 7;

      // 만약 오늘 예약시간이 이미 지났으면 다음 주로 예약
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

      // 실제 예약할 시간 생성
      final scheduledDateTime = DateTime(
        nextDate.year,
        nextDate.month,
        nextDate.day,
        alarmTime.hour,
        alarmTime.minute,
      );

      // time zone-aware로 변환
      final tz.TZDateTime tzScheduled =
      tz.TZDateTime.from(scheduledDateTime, tz.local);

      // 알림 식별 ID는 "습관 ID + 요일"을 해시로
      final notificationId = (id + day).hashCode;

      // 알림 예약 (반복: 매주 같은 요일, 같은 시간)
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

    // 오늘 체크해야 할 습관 필터 (오늘 요일 포함)
    final todayWeekday = DateTime.now().weekday; // 1~7 (월~일)
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];

    // 오늘 요일 문자열로 변환
    final todayStr = weekdays[todayWeekday - 1];

    final todayHabits = habits.where((habit) => habit.days.contains(todayStr)).toList();

    if (todayHabits.isEmpty) return 0;

    // 완료한 습관 개수
    final completedCount = todayHabits.where((habit) => habit.dailyCompletion[today] == true).length;

    return completedCount / todayHabits.length * 100;
  }

  /// 최근 7일 달성률 리스트 반환
  List<double> calculateLast7DaysCompletionRate(List<Habit> habits) {
    List<double> rates = [];

    final today = DateTime.now();

    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];

    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final dayStr = formatter.format(day);
      final dayWeekdayStr = weekdays[day.weekday - 1];

      final dayHabits = habits.where((habit) => habit.days.contains(dayWeekdayStr)).toList();
      if (dayHabits.isEmpty) {
        rates.add(0);
        continue;
      }

      final completedCount = dayHabits.where((habit) => habit.dailyCompletion[dayStr] == true).length;
      final rate = completedCount / dayHabits.length * 100;

      rates.add(rate);
    }

    return rates;
  }

}