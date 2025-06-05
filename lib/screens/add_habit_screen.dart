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

  final List<String> _weekDays = ['월', '화', '수', '목', '금', '토', '일'];

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
    final Color bgColor = Color(0xFFF8FAFC);
    final Color lightBlue = Color(0xFFD9EAFD);
    final Color midGrayBlue = Color(0xFFBCCCDC);
    final Color darkGrayBlue = Color(0xFF9AA6B2);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.habit == null ? '습관 추가' : '습관 수정',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        iconTheme: IconThemeData(color: darkGrayBlue),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 제목 입력란
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(
                  labelText: '습관 제목',
                  labelStyle: TextStyle(color: Colors.black87),
                  filled: true,
                  fillColor: lightBlue,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: darkGrayBlue),
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

              SizedBox(height: 24),

              Text(
                '반복 요일 선택',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),

              Wrap(
                spacing: 10,
                children: _weekDays.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(
                      day,
                      style: TextStyle(
                        color: isSelected ? bgColor : darkGrayBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: darkGrayBlue,
                    backgroundColor: lightBlue,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(day);
                        } else {
                          _selectedDays.remove(day);
                        }
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    showCheckmark: true,
                  );
                }).toList(),
              ),

              SizedBox(height: 24),

              ListTile(
                title: Text(
                  '알림 시간',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  _reminderTime == null
                      ? '설정 안됨'
                      : _reminderTime!.format(context),
                  style: TextStyle(color: darkGrayBlue.withOpacity(0.7)),
                ),
                trailing: Icon(Icons.access_time, color: midGrayBlue),
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

              SizedBox(height: 24),

              TextFormField(
                initialValue: _memo,
                decoration: InputDecoration(
                  labelText: '메모 (선택)',
                  labelStyle: TextStyle(color: darkGrayBlue),
                  filled: true,
                  fillColor: lightBlue,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  alignLabelWithHint: true,
                ),
                style: TextStyle(color: darkGrayBlue),
                maxLines: 4,
                onSaved: (value) {
                  _memo = value?.trim() ?? '';
                },
              ),

              SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGrayBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _saveHabit,
                  child:
                  Text(widget.habit == null ? '습관 저장' : '습관 수정'),
                ),
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
        habitProvider.addHabit(_title, _selectedDays, _reminderTime, memo: _memo);
        Navigator.pop(context);
      } else {
        final updatedHabit = widget.habit!.copyWith(
          title: _title,
          days: _selectedDays,
          alarmTime: _reminderTime,
          memo: _memo,
        );
        habitProvider.updateHabit(updatedHabit);
        Navigator.pop(context, updatedHabit);
      }
    }
  }
}