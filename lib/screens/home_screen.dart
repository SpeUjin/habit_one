import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/habit_provider.dart';
import 'add_habit_screen.dart';
import 'habit_detail_screen.dart';
import 'statistics_page.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<HabitProvider>(context, listen: false).loadHabits();
    });
  }

  void _showConfirmationDialog(BuildContext context, HabitProvider provider, String id) {
    final now = DateTime.now();
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final todayStr = weekdays[now.weekday - 1];

    final habit = provider.habits.firstWhere((h) => h.id == id);

    if (!habit.days.contains(todayStr)) {
      showDialog(
        context: context,
        builder: (alertContext) {
          return AlertDialog(
            title: const Text('알림'),
            content: const Text('오늘은 완료할 수 없는 습관입니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(alertContext).pop(),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('습관 완료 확인'),
          content: const Text('오늘 이 습관을 완료로 처리하시겠어요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD9EAFD), // 밝은 하늘색
              ),
              onPressed: () {
                provider.toggleCompletion(id, now);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('확인'),
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
      backgroundColor: const Color(0xFFF8FAFC), // 매우 연한 하늘색 배경
      appBar: AppBar(
        title: const Text('Habit One'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFD9EAFD), // 밝은 하늘색
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: habitProvider.habits.isEmpty
            ? Center(
          child: Text(
            '습관을 추가해보세요!',
            style: TextStyle(fontSize: 16, color: const Color(0xFF9AA6B2)), // 짙은 그레이-블루 텍스트
          ),
        )
            : AnimationLimiter(
          child: ListView.separated(
            itemCount: habitProvider.habits.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final habit = habitProvider.habits[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 400),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: Dismissible(
                      key: Key(habit.id.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade400, // 삭제는 붉은색 유지
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        habitProvider.removeHabit(habit.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${habit.title} 삭제됨')),
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.white,
                        elevation: 3,
                        child: ListTile(
                          leading: Icon(
                            habit.isCompletedToday ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: habit.isCompletedToday ? const Color(0xFFD9EAFD) : const Color(0xFF9AA6B2), // 완료 아이콘: 밝은 하늘색, 미완료 아이콘: 짙은 그레이-블루
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          title: Text(
                            habit.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '반복 요일: ${habit.days.join(", ")}',
                              style: const TextStyle(color: Color(0xFF9AA6B2)), // 보조 텍스트 짙은 그레이-블루
                            ),
                          ),
                          trailing: ElevatedButton(
                            onPressed: habit.isCompletedToday
                                ? null
                                : () => _showConfirmationDialog(context, habitProvider, habit.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: habit.isCompletedToday
                                  ? Colors.grey
                                  : const Color(0xFFD9EAFD), // 버튼 색상 밝은 하늘색
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              habit.isCompletedToday ? '완료됨' : '오늘 완료',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HabitDetailScreen(habit: habit),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD9EAFD), // 플로팅 버튼 밝은 하늘색
        child: const Icon(Icons.add),
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