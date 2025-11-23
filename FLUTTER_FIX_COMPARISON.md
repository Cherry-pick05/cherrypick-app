# Flutter vs Python 비교 및 수정

## 🔍 주요 차이점

### 1. 이미지 전처리

**Python (작동함)** ✅:
```python
# 단순 리사이즈
image_resized = cv2.resize(image, (640, 640))
# RGB 변환
image_rgb = cv2.cvtColor(image_resized, cv2.COLOR_BGR2RGB)
# 정규화
image_normalized = image_rgb.astype(np.float32) / 255.0
```

**Flutter (수정 전)** ❌:
```dart
// Letterbox 리사이즈 + 회색 배경 패딩
// 문제: Python과 다른 전처리 방식
```

**Flutter (수정 후)** ✅:
```dart
// 단순 리사이즈 (Python과 동일)
final resizedImage = img.copyResize(image, width: 640, height: 640);
// RGB 정규화 (동일)
```

### 2. 출력 파싱

**Python (작동함)** ✅:
```python
# 직접 인덱싱
x_center = float(output_data[0, 0, det_idx])
y_center = float(output_data[0, 1, det_idx])
```

**Flutter** ✅:
- 인덱싱 방식 확인 및 수정됨

---

## ✅ 적용된 수정사항

1. **Letterbox 제거**: Python과 동일하게 단순 리사이즈 사용
2. **디버깅 로그 추가**: 전처리 과정 추적 가능
3. **출력 파싱 확인**: 인덱싱이 올바른지 검증

---

## 🧪 테스트 방법

### Flutter 앱에서 확인

1. 앱 실행
2. 디버그 콘솔 확인:
   ```
   📸 이미지 전처리:
     원본: ...
     리사이즈: ...
   🔍 YOLO World v2 출력 형태: ...
   🔍 출력 변환 완료: ...
   ```

### 예상 결과

- Python과 동일한 전처리 → 동일한 추론 결과
- 탐지가 정상적으로 작동해야 함

---

## 🐛 추가 디버깅

만약 여전히 안 된다면:

1. **출력 값 비교**:
   - Python에서 동일 이미지로 추론
   - Flutter에서 동일 이미지로 추론
   - 출력 값을 비교

2. **카메라 프레임 차이**:
   - YUV vs RGB 변환 확인
   - 카메라 이미지 전처리 확인

