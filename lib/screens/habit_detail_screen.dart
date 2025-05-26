import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import 'add_habit_screen.dart';

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;

  HabitDetailScreen({required this.habit});

  @override
  _HabitDetailScreenState createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  late Habit habit;

  @override
  void initState() {
    super.initState();
    habit = widget.habit;
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('습관 상세'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              // 수정 화면으로 이동하고, 결과를 받아서 habit 업데이트
              final updatedHabit = await Navigator.push<Habit>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddHabitScreen(habit: habit),
                ),
              );

              if (updatedHabit != null) {
                setState(() {
                  habit = updatedHabit;
                });
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('삭제 확인'),
                  content: Text('${habit.title}을(를) 삭제하시겠습니까?'),
                  actions: [
                    TextButton(
                      child: Text('취소'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    TextButton(
                      child: Text('삭제'),
                      onPressed: () {
                        habitProvider.removeHabit(habit.id);
                        Navigator.of(ctx).pop(); // 다이얼로그 닫기
                        Navigator.of(context).pop(); // 상세페이지 닫기
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              habit.title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('반복 요일: ${habit.days.join(", ")}'),
            SizedBox(height: 10),
            Text('알림 시간: ${habit.alarmTime != null ? habit.alarmTime!.format(context) : '설정 안됨'}'),
            SizedBox(height: 10),
            Text('메모:'),
            SizedBox(height: 5),
            Text(
              (habit.memo ?? '').isNotEmpty ? habit.memo! : '없음',
            ),
          ],
        ),
      ),
    );
  }
}