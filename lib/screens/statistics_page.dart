import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart'; // 날짜 포맷용

import '../models/habit.dart';
import '../providers/habit_provider.dart';

class StatisticsPage extends StatelessWidget {
  final List<Habit> habits;

  const StatisticsPage({Key? key, required this.habits}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context);
    final habits = habitProvider.habits;

    final todayRate = habitProvider.calculateTodayCompletionRate(habits);
    final last7DaysRates = habitProvider.calculateLast7DaysCompletionRate(habits);

    const double cardHeight = 280; // 습관별 달성률 카드 기준 높이
    const double maxBarHeight = 120;  // 100 → 120 또는 더 크게

    // 오늘 날짜를 기준으로 지난 7일 날짜 리스트 생성 (역순)
    final today = DateTime.now();
    List<String> last7DaysLabels = List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      return DateFormat.Md().format(date); // 월/일 포맷 예: 5/30
    });

    return Scaffold(
      appBar: AppBar(title: const Text('습관 통계')),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 오늘 달성률 카드 (원형 그래프)
                SizedBox(
                  height: cardHeight,
                  width: double.infinity,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.today, size: 40, color: Colors.green),
                          const SizedBox(height: 16),
                          const Text('오늘의 달성률',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          CircularPercentIndicator(
                            radius: 60.0,
                            lineWidth: 10.0,
                            percent: (todayRate / 100).clamp(0.0, 1.0),
                            center: Text(
                              '${todayRate.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                            progressColor: Colors.green,
                            backgroundColor: Colors.green.shade100,
                            circularStrokeCap: CircularStrokeCap.round,
                            animation: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 지난 7일 달성률 카드
                SizedBox(
                  height: cardHeight,
                  width: double.infinity,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('지난 7일 달성률',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: maxBarHeight + 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              shrinkWrap: true,
                              itemCount: last7DaysRates.length,
                              itemBuilder: (context, index) {
                                final rate = last7DaysRates[index];
                                final barHeight = (rate / 100) * maxBarHeight;

                                return Container(
                                  width: 40,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text('${rate.toStringAsFixed(0)}%',
                                          style: const TextStyle(fontSize: 12)),
                                      const SizedBox(height: 4),
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0, end: barHeight),
                                        duration: const Duration(milliseconds: 500),
                                        builder: (context, animatedHeight, child) {
                                          return Container(
                                            height: animatedHeight,
                                            width: 20,
                                            decoration: BoxDecoration(
                                              color: Colors.blueAccent,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        last7DaysLabels[index],
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 습관별 달성 내역 카드
                SizedBox(
                  height: cardHeight,
                  width: double.infinity,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('습관별 달성 내역',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: habits.length,
                              itemBuilder: (context, index) {
                                final habit = habits[index];
                                final completedCount =
                                    habit.dailyCompletion.entries.where((e) => e.value).length;

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.check_circle_outline, color: Colors.blue),
                                  title: Text(habit.title,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text('최근 달성: $completedCount회'),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}