import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import 'add_habit_screen.dart';
import 'habit_detail_screen.dart';
import 'statistics_page.dart';  // 통계페이지 import 추가


class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Provider 초기 데이터 로드
    Future.microtask(() {
      Provider.of<HabitProvider>(context, listen: false).loadHabits();
    });
  }

  void _showConfirmationDialog(BuildContext context, HabitProvider provider, String id) {
    final now = DateTime.now();
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final todayStr = weekdays[now.weekday - 1];

    // id로 Habit을 찾아오기
    final habit = provider.habits.firstWhere((h) => h.id == id);

    // 오늘 요일이 습관 반복 요일에 없으면 알림 다이얼로그만 띄우고 반환
    if (!habit.days.contains(todayStr)) {
      showDialog(
        context: context,
        builder: (alertContext) {
          return AlertDialog(
            title: const Text('알림'),
            content: const Text('오늘은 완료할 수 없는 습관입니다.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(alertContext).pop();
                  // 상태 갱신이 필요하면 setState 사용
                  setState(() {});
                },
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
      return;
    }

    // 오늘 요일이 포함되어 있으면 완료 토글 확인 다이얼로그
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('습관 완료 확인'),
          content: const Text('오늘 이 습관을 완료로 처리하시겠어요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('아니오'),
            ),
            TextButton(
              onPressed: () {
                provider.toggleCompletion(id, now);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('예'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('1일 1습관'),
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart),
            tooltip: '통계',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StatisticsPage(habits: habitProvider.habits),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: habitProvider.habits.length,
        itemBuilder: (context, index) {
          final habit = habitProvider.habits[index];
          return Dismissible(
            key: Key(habit.id.toString()),
            direction: DismissDirection.endToStart, // 오른쪽에서 왼쪽 스와이프로 삭제
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20),
              child: Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) {
              habitProvider.removeHabit(habit.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${habit.title} 삭제됨')),
              );
            },
            child: ListTile(
              title: Text(habit.title),
              subtitle: Text('반복 요일: ${habit.days.join(", ")}'),
              trailing: ElevatedButton(
                onPressed: habit.isCompletedToday
                    ? null // 오늘 완료되면 버튼 비활성화
                    : () {
                  _showConfirmationDialog(context, habitProvider, habit.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: habit.isCompletedToday ? Colors.grey : Colors.blue,
                ),
                child: Text(habit.isCompletedToday ? '완료됨' : '오늘 완료'),
              ),
              // ListTile onTap 수정
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HabitDetailScreen(habit: habit), // 상세 페이지로 이동
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddHabitScreen()),
          );
        },
      ),
    );
  }
}