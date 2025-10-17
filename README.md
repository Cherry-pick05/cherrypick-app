flu# Cherry Pick - 여행 짐싸기 도우미 앱

AI 기반 여행 짐싸기 및 항공 규정 확인 앱입니다.

## 주요 기능

### 🍒 체리픽 (짐 관리)
- 가방별 아이템 관리
- 패킹 상태 추적
- 검색 기능
- 카테고리별 분류

### 📷 스캔
- 카메라로 물품 스캔
- AI 기반 항공 규정 확인
- 기내/위탁 수하물 허용 여부 표시
- 주의사항 안내

### ✈️ 항공 규정
- 국가/항공사별 수하물 규정
- 기내/위탁 수하물 제한사항
- 금지품목 안내
- 면세 한도 정보

### 🌍 여행 추천
- 여행지별 맞춤 추천
- 날씨 정보
- 인기 아이템
- 옷차림 가이드
- 쇼핑 가이드

## 기술 스택

- **Flutter** - 크로스 플랫폼 모바일 앱 개발
- **Dart** - 프로그래밍 언어
- **Provider** - 상태 관리
- **GoRouter** - 네비게이션
- **Camera** - 카메라 기능
- **Image Picker** - 이미지 선택

## 설치 및 실행

### 필수 요구사항
- Flutter SDK 3.0.0 이상
- Dart SDK 3.0.0 이상
- Android Studio 또는 VS Code
- Android/iOS 개발 환경

### 설치 방법

1. 저장소 클론
```bash
git clone <repository-url>
cd cherry_pick
```

2. 의존성 설치
```bash
flutter pub get
```

3. 앱 실행
```bash
flutter run
```

## 프로젝트 구조

```
lib/
├── main.dart                 # 앱 진입점
├── theme/
│   └── app_theme.dart       # 테마 설정
├── models/
│   ├── trip.dart            # 여행 모델
│   └── packing_item.dart    # 짐 아이템 모델
├── providers/
│   ├── trip_provider.dart   # 여행 상태 관리
│   └── packing_provider.dart # 짐 상태 관리
├── screens/
│   ├── luggage_screen.dart  # 짐 관리 화면
│   ├── scan_screen.dart     # 스캔 화면
│   ├── checklist_screen.dart # 항공 규정 화면
│   └── recommendations_screen.dart # 추천 화면
└── widgets/
    ├── app_header.dart      # 앱 헤더
    ├── bottom_navigation.dart # 하단 네비게이션
    ├── packing_manager.dart # 짐 관리 위젯
    ├── item_scanner.dart    # 아이템 스캐너
    ├── regulation_checker.dart # 규정 확인기
    └── travel_recommendations.dart # 여행 추천
```

## 주요 특징

### 반응형 디자인
- 다양한 화면 크기 지원
- Material Design 3 적용
- 다크/라이트 테마 지원

### 상태 관리
- Provider 패턴 사용
- 효율적인 상태 업데이트
- 데이터 지속성

### 사용자 경험
- 직관적인 네비게이션
- 부드러운 애니메이션
- 접근성 고려

## 라이선스

이 프로젝트는 MIT 라이선스 하에 있습니다.

## 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 연락처

프로젝트 관련 문의사항이 있으시면 이슈를 생성해 주세요.
