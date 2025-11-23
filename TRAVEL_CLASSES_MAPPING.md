# 여행 클래스 매핑 가이드

## 설정된 여행 클래스 목록

다음 24개의 여행 관련 클래스가 설정되었습니다:

```dart
travel_classes = [
  'passport', 'power bank', 'lighter', 'battery',      // 필수/주의
  'knife', 'scissors', 'tool', 'spray', 'bottle',      // 보안 검색 주의
  'laptop', 'tablet', 'camera', 'drone',               // 전자제품
  'luggage', 'suitcase', 'backpack',                   // 가방
  'sunglasses', 'hat', 'neck pillow', 'cosmetics', 'charger', 'shoes' // 기타
]
```

## COCO 클래스 → 여행 클래스 매핑

YOLO World TFLite 모델은 COCO 80 클래스에 대해 학습되어 있으므로, 탐지된 COCO 클래스를 여행 클래스로 매핑합니다:

### 직접 매핑 (100% 매칭)

| COCO 클래스 | 여행 클래스 | COCO 인덱스 |
|------------|-----------|------------|
| bottle | bottle | 39 |
| laptop | laptop | 63 |
| suitcase | suitcase | 28 |
| backpack | backpack | 24 |
| knife | knife | 43 |
| scissors | scissors | 76 |

### 유사 클래스 매핑

| COCO 클래스 | 여행 클래스 | 설명 |
|------------|-----------|------|
| handbag | luggage | 가방류 |
| cell phone | power bank | 전자제품 |
| tv | tablet | 전자제품 |
| umbrella | tool | 도구류 |

### 매핑되지 않는 클래스

다음 여행 클래스는 COCO에 없어서 직접 탐지되지 않습니다:
- `passport` - 서류/문서
- `lighter` - 라이터
- `battery` - 배터리
- `spray` - 스프레이
- `tablet` - 태블릿 (tv로 유사 매핑 가능)
- `camera` - 카메라
- `drone` - 드론
- `sunglasses` - 선글라스
- `hat` - 모자
- `neck pillow` - 목베개
- `cosmetics` - 화장품
- `charger` - 충전기
- `shoes` - 신발

## 해결 방법

### 옵션 1: 현재 방법 (매핑 사용)
- COCO 클래스를 탐지하고 여행 클래스로 변환
- 일부 클래스만 탐지 가능

### 옵션 2: 커스텀 모델 학습 (권장, 장기적)
1. YOLO World v2를 여행 클래스로 재학습
2. 또는 YOLO World의 Open Vocabulary 기능 활용 (TFLite 변환 전)

### 옵션 3: 하이브리드 접근
- COCO로 탐지 가능한 것은 매핑 사용
- 탐지 불가능한 것은 사용자가 직접 입력

## 코드에서 사용하는 방법

### 현재 설정

코드는 자동으로 여행 클래스를 사용하도록 설정되어 있습니다:

```dart
_yoloDetector = YoloWorldTfliteDetector();
await _yoloDetector!.initialize(
  modelPath: 'assets/yolo_world_ovd.tflite',
  // labels는 null이면 자동으로 여행 클래스 사용
);
```

### 수동으로 라벨 설정

필요시 다른 클래스 리스트를 사용할 수도 있습니다:

```dart
await _yoloDetector!.initialize(
  modelPath: 'assets/yolo_world_ovd.tflite',
  labels: ['bottle', 'laptop', 'backpack'], // 커스텀 라벨
);
```

## 개선 방안

### 단기 개선

1. **매핑 확장**: 더 많은 COCO 클래스를 여행 클래스로 매핑
   ```dart
   // 예: 'cup' -> 'bottle', 'handbag' -> 'luggage' 등
   ```

2. **유사도 기반 매핑**: 신뢰도가 낮은 매핑은 제외

### 장기 개선

1. **커스텀 모델 학습**: 
   - YOLO World를 여행 클래스 데이터셋으로 재학습
   - 또는 YOLO World의 Open Vocabulary 기능 활용

2. **멀티 모델 앙상블**:
   - 일반 객체 탐지 + 특정 아이템 탐지 모델 조합

## 테스트 방법

1. `bottle`, `laptop`, `backpack` 같은 직접 매핑 클래스로 테스트
2. 탐지 결과가 올바른 여행 클래스로 변환되는지 확인
3. 매핑되지 않는 클래스는 'unknown'으로 표시됨

## 참고사항

- YOLO World는 Open Vocabulary Detection이지만, TFLite로 변환된 모델은 COCO 80 클래스에 고정됨
- 완전한 커스텀 클래스 탐지를 위해서는 모델 재학습 또는 다른 접근 방법 필요

