import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'providers/habit_provider.dart';
import 'screens/home_screen.dart';
import 'models/habit.dart';
import 'package:flutter/foundation.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

const Map<String, int> _weekdayMap = {
  '월': DateTime.monday,
  '화': DateTime.tuesday,
  '수': DateTime.wednesday,
  '목': DateTime.thursday,
  '금': DateTime.friday,
  '토': DateTime.saturday,
  '일': DateTime.sunday,
};

Future<void> initializeNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

  const iosInit = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    onDidReceiveLocalNotification: onDidReceiveLocalNotification,
  );

  final settings = InitializationSettings(android: androidInit, iOS: iosInit);

  await flutterLocalNotificationsPlugin.initialize(
    settings,
    onDidReceiveNotificationResponse: onNotificationResponse,
  );
}

@pragma('vm:entry-point')
void onNotificationResponse(NotificationResponse response) {
  debugPrint('알림 클릭됨: ${response.payload}');
}

@pragma('vm:entry-point')
void onDidReceiveLocalNotification(
    int id, String? title, String? body, String? payload) {
  debugPrint('iOS 포그라운드 알림: $title');
}

Future<void> scheduleWeeklyNotification(
    String id,
    String title,
    TimeOfDay alarmTime,
    List<String> days,
    ) async {
  if (kIsWeb) {
    debugPrint('[웹 테스트] 알림 예약됨: $title - 요일: $days, 시간: ${alarmTime.hour}:${alarmTime.minute}');
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

Future<void> scheduleAllHabitNotifications(List<Habit> habits) async {
  for (final habit in habits) {
    if (habit.alarmTime != null && habit.days.isNotEmpty) {
      await scheduleWeeklyNotification(
        habit.id,
        habit.title,
        habit.alarmTime!,
        habit.days,
      );
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await initializeNotifications();

  runApp(
    ChangeNotifierProvider(
      create: (_) {
        final provider = HabitProvider();
        provider.loadHabits().then((_) async {
          await scheduleAllHabitNotifications(provider.habits);
        });
        return provider;
      },
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Habit One',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}