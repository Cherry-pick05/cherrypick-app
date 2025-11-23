# Flutter TFLite 디버깅 가이드

## 🔍 문제 진단 체크리스트

TFLite는 작동하는데 Flutter에서 안 되는 경우, 다음을 확인하세요:

### 1. 이미지 전처리 차이

**Python (작동함)**:
```python
# 단순 리사이즈
image_resized = cv2.resize(image, (640, 640))
# BGR to RGB
image_rgb = cv2.cvtColor(image_resized, cv2.COLOR_BGR2RGB)
# 정규화 (0~1)
image_normalized = image_rgb.astype(np.float32) / 255.0
```

**Flutter (문제 있음)**:
```dart
// Letterbox 리사이즈 (회색 배경 패딩)
// 회색 배경 (128, 128, 128) 사용
```

### 2. 출력 파싱 차이

**Python**:
- 직접 인덱싱: `output_data[0, 0, det_idx]`
- 명확한 형태 이해

**Flutter**:
- 리스트 재구성 필요
- 인덱싱이 다를 수 있음

---

## 🐛 디버깅 코드 추가

Flutter 코드에 다음 디버깅을 추가하여 Python과 비교:

### 이미지 전처리 비교

```dart
// _preprocessImage 함수에 추가
debugPrint('📸 이미지 전처리:');
debugPrint('  원본 크기: ${image.width}x${image.height}');
debugPrint('  리사이즈 크기: ${resizedImage.width}x${resizedImage.height}');
debugPrint('  입력 텐서 형태: [${_inputShape![0]}, ${_inputShape![1]}, ${_inputShape![2]}, ${_inputShape![3]}]');

// 첫 번째 픽셀 값 확인
final firstPixel = resizedImage.getPixel(0, 0);
debugPrint('  첫 픽셀 RGB: (${firstPixel.r}, ${firstPixel.g}, ${firstPixel.b})');
debugPrint('  정규화된 값: (${firstPixel.r / 255.0}, ${firstPixel.g / 255.0}, ${firstPixel.b / 255.0})');

// 입력 텐서의 첫 몇 값 확인
debugPrint('  입력 텐서 첫 값: ${processedImage[0][0][0]}');
```

### 출력 비교

```dart
// _parseYoloOutput 함수 시작 부분에 추가
debugPrint('🔍 출력 파싱 시작:');
debugPrint('  출력 형태: $_outputShapes');
debugPrint('  첫 출력 값 샘플: ${outputs[0].take(10).toList()}');
debugPrint('  출력 최소값: ${outputs[0].reduce((a, b) => a < b ? a : b)}');
debugPrint('  출력 최대값: ${outputs[0].reduce((a, b) => a > b ? a : b)}');
```

---

## 🔧 수정 방법

### 방법 1: Letterbox 제거 (Python과 동일하게)

```dart
/// 이미지 전처리 (Python과 동일하게 - letterbox 없이)
List<List<List<List<double>>>> _preprocessImageSimple(img.Image image) {
  // 단순 리사이즈 (letterbox 없음)
  final resizedImage = img.copyResize(
    image,
    width: _inputSize!,
    height: _inputSize!,
  );
  
  // RGB 텐서 생성 및 정규화 (0.0 ~ 1.0 범위)
  final input = List.generate(
    _inputShape![0], // batch
    (b) => List.generate(
      _inputShape![1], // height
      (h) => List.generate(
        _inputShape![2], // width
        (w) => List.generate(
          _inputShape![3], // channels (3 = RGB)
          (c) {
            final pixel = resizedImage.getPixel(w, h);
            final value = c == 0 ? pixel.r / 255.0
                : c == 1 ? pixel.g / 255.0
                    : pixel.b / 255.0;
            return value;
          },
        ),
      ),
    ),
  );
  
  return input;
}
```

### 방법 2: 출력 파싱 수정 (Python과 동일하게)

```dart
// 현재 코드가 올바른지 확인
// output_data[0, feature_idx, det_idx] 형태로 접근하는지 확인
```

---

## 📊 비교 테스트 스크립트

Python에서 Flutter와 동일한 전처리 테스트:

```python
import cv2
import numpy as np

# Flutter letterbox 방식 테스트
def preprocess_letterbox(image, target_size):
    """Flutter와 동일한 letterbox 전처리"""
    h, w = image.shape[:2]
    scale = min(target_size / w, target_size / h)
    
    new_w = int(w * scale)
    new_h = int(h * scale)
    
    resized = cv2.resize(image, (new_w, new_h))
    
    # 회색 배경 생성 (128, 128, 128)
    padded = np.full((target_size, target_size, 3), 128, dtype=np.uint8)
    
    # 중앙 배치
    offset_x = (target_size - new_w) // 2
    offset_y = (target_size - new_h) // 2
    padded[offset_y:offset_y+new_h, offset_x:offset_x+new_w] = resized
    
    # RGB로 변환 및 정규화
    rgb = cv2.cvtColor(padded, cv2.COLOR_BGR2RGB)
    normalized = rgb.astype(np.float32) / 255.0
    
    return np.expand_dims(normalized, axis=0)

# 테스트
test_image = cv2.imread('test.jpg')
processed1 = preprocess_letterbox(test_image, 640)
print(f"Letterbox 전처리: {processed1.shape}, 첫 픽셀: {processed1[0, 0, 0, :]}")

# 단순 리사이즈 (Python 원본)
processed2 = cv2.resize(test_image, (640, 640))
processed2 = cv2.cvtColor(processed2, cv2.COLOR_BGR2RGB)
processed2 = processed2.astype(np.float32) / 255.0
processed2 = np.expand_dims(processed2, axis=0)
print(f"단순 리사이즈: {processed2.shape}, 첫 픽셀: {processed2[0, 0, 0, :]}")

# 차이 확인
diff = np.abs(processed1 - processed2)
print(f"차이 평균: {diff.mean()}")
print(f"차이 최대: {diff.max()}")
```

