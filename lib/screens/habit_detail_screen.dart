import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import 'add_habit_screen.dart';

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  _HabitDetailScreenState createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  late Habit habit;

  // 색상 팔레트
  final Color bgColor = const Color(0xFFF8FAFC);
  final Color lightBlue = const Color(0xFFD9EAFD);
  final Color midGrayBlue = const Color(0xFFBCCCDC);
  final Color darkGrayBlue = const Color(0xFF9AA6B2);

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
        title: const Text('습관 상세'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: lightBlue,
        iconTheme: IconThemeData(color: darkGrayBlue),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: '수정',
            onPressed: () async {
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
            icon: const Icon(Icons.delete),
            tooltip: '삭제',
            color: Colors.red[400],
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('삭제 확인'),
                  content: Text('${habit.title}을(를) 삭제하시겠습니까?'),
                  actions: [
                    TextButton(
                      child: const Text('취소'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    TextButton(
                      child: const Text(
                        '삭제',
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () {
                        habitProvider.removeHabit(habit.id);
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: bgColor,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    icon: Icons.repeat,
                    label: '반복 요일',
                    value: habit.days.join(", "),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.alarm,
                    label: '알림 시간',
                    value: habit.alarmTime != null
                        ? habit.alarmTime!.format(context)
                        : '설정 안됨',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.note,
                    label: '메모',
                    value: (habit.memo ?? '').isNotEmpty ? habit.memo! : '없음',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: darkGrayBlue),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87, // 더 진한 색상으로!
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87, // midGrayBlue -> 더 진한 색상
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}