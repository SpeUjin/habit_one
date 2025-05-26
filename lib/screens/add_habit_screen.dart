import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';

class AddHabitScreen extends StatefulWidget {

  final Habit? habit; // 수정 시 기존 습관 전달
  AddHabitScreen({this.habit});

  @override
  _AddHabitScreenState createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _title;
  late List<String> _selectedDays;
  TimeOfDay? _reminderTime;
  late String _memo;

  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // TextEditingController를 쓰는 방법도 있지만 여기선 initialValue만 설정할게요
  @override
  void initState() {
    super.initState();
    _title = widget.habit?.title ?? '';
    _selectedDays = widget.habit != null ? List.from(widget.habit!.days) : [];
    _reminderTime = widget.habit?.alarmTime;
    _memo = widget.habit?.memo ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit == null ? '습관 추가' : '습관 수정'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 제목 입력란
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(labelText: '습관 제목'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '습관 제목을 입력해주세요';
                  }
                  return null;
                },
                onSaved: (value) {
                  _title = value!.trim();
                },
              ),

              SizedBox(height: 20),

              // 반복 요일 선택
              Text('반복 요일 선택'),
              Wrap(
                spacing: 10,
                children: _weekDays.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(day),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(day);
                        } else {
                          _selectedDays.remove(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              SizedBox(height: 20),

              // 알림 시간 선택
              ListTile(
                title: Text('알림 시간'),
                subtitle: Text(_reminderTime == null
                    ? '설정 안됨'
                    : _reminderTime!.format(context)),
                trailing: Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _reminderTime ?? TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _reminderTime = picked;
                    });
                  }
                },
              ),

              SizedBox(height: 20),

              // 메모 입력란
              TextFormField(
                initialValue: _memo,
                decoration: InputDecoration(labelText: '메모 (선택)'),
                maxLines: 3,
                onSaved: (value) {
                  _memo = value?.trim() ?? '';
                },
              ),

              SizedBox(height: 30),

              ElevatedButton(
                onPressed: _saveHabit,
                child: Text(widget.habit == null ? '습관 저장' : '습관 수정'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveHabit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('반복 요일을 최소 하나 이상 선택해주세요')),
        );
        return;
      }

      final habitProvider = Provider.of<HabitProvider>(context, listen: false);

      if (widget.habit == null) {
        // 새 습관 추가
        habitProvider.addHabit(_title, _selectedDays, _reminderTime, memo: _memo);
        Navigator.pop(context); // 새 습관 추가 후 그냥 닫기
      } else {
        // 기존 습관 수정
        final updatedHabit = widget.habit!.copyWith(
          title: _title,
          days: _selectedDays,
          alarmTime: _reminderTime,
          memo: _memo,
        );
        habitProvider.updateHabit(updatedHabit);
        Navigator.pop(context, updatedHabit); // 수정된 Habit 반환
      }
    }
  }
}