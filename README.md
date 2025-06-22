# 1일 1습관 앱 (HabitOne)

Flutter로 개발한 간단한 습관 형성 앱입니다.  
사용자가 매일 한 가지 좋은 습관을 정하고, 완료 여부를 체크하며 습관을 형성할 수 있도록 도와줍니다.

---

> [프로젝트 문서 - PDF ]([프로젝트문서.pdf](https://raw.githubusercontent.com/SpeUjin/habit_one/refs/heads/master/프로젝트문서.pdf))

---
## 프로젝트 문서 및 간트차트
[프로젝트 문서 - 노션](https://www.notion.so/20557b6a89d58073a6bbc9615ba51ded?source=copy_link)

[간트차트 - 노션](https://www.notion.so/Habit-One-20357b6a89d58034a1e1e9424e191abf?source=copy_link)

---

## ✨ 주요 기능

| 기능명             | 설명 |
|------------------|------|
| 습관 등록           | 사용자가 목표 습관을 등록하고 수정, 삭제할 수 있음 |
| 오늘의 체크         | 당일 해당 습관을 완료했는지 체크할 수 있음 |
| 진행률 표시         | 최근 7일간의 성공 여부를 그래프나 리스트로 표시 |
| 알림 기능           | 설정된 시간에 푸시 알림 전송 (Flutter Local Notification) |
| 데이터 저장         | 사용자의 습관 정보와 체크 여부를 로컬에 저장 (`shared_preferences`) |
| 통계 화면           | 전체 달성 일수, 달성률 등의 통계 제공 |

---

## 🧱 기술 스택

| 항목       | 기술 |
|------------|------|
| 개발 언어    | Dart |
| 프레임워크   | Flutter |
| 상태 관리    | Provider (또는 Riverpod 등 변경 가능) |
| 로컬 저장소  | shared_preferences |
| 알림 기능    | flutter_local_notifications |
| 날짜 처리    | intl |
| 그래프       | fl_chart |

---

## 📱 주요 화면

- **홈 화면**: 오늘의 날짜, 등록한 습관 목록, 체크 버튼
- **습관 추가 화면**: 새 습관 제목, 알림 시간 설정
- **통계 화면**: 최근 일주일 성공률, 전체 달성률 시각화
- **설정 화면 (선택)**: 테마 변경, 앱 정보

---

## 📂 폴더 구조

```plaintext
lib/
├── main.dart
├── app.dart              ← MaterialApp 분리
├── models/               ← 습관 모델 등
├── providers/            ← 상태 관리 (provider)
├── screens/              ← 각 화면 (Home, AddHabit 등)
├── widgets/              ← 공통 위젯
├── services/             ← 알림, 저장 관련 로직
```

---

## 📌 향후 개선 방향

- 다크모드 지원
- 여러 개의 습관 동시 관리 기능
- 칭찬 메시지 애니메이션 / 리워드 기능
- 홈 위젯 지원

---

## 👤 개발자 정보
| 항목 | 내용 |
| -- | -- |
| 이름 | 유우진 |
| 이메일 | believeyu@naver.com |
| GitHub | https://github.com/SpeUjin |

---

## 📝 라이선스

MIT License
Copyright (c) 2025

---
