# YOLO World OVD TFLite 모델 사용 가이드

## 📋 요약

**YOLO World OVD 모델**을 Flutter 앱에서 사용하기 위한 완전한 가이드입니다.

### 주요 차이점 (MediaPipe vs YOLO World)

| 항목 | MediaPipe OVD | YOLO World OVD |
|------|--------------|----------------|
| **입력** | 이미지만 | 이미지 + (선택적) 텍스트 프롬프트 |
| **바운딩 박스** | 좌상단-우하단 (x1, y1, x2, y2) | 중심점 기반 (x, y, w, h) |
| **출력 형태** | [batch, detections, 6] | [batch, detections, 4+classes] |
| **좌표 범위** | 픽셀 좌표 | 정규화 좌표 (0~1) |

---

## 🚀 빠른 시작

### 1. Colab에서 TFLite 파일 생성

`YOLO_WORLD_COLAB_GUIDE.md` 파일을 참고하여 Colab에서 다음 작업 수행:

1. YOLO World 모델 다운로드
2. TFLite로 변환
3. 입출력 형태 확인
4. 파일 다운로드

### 2. Flutter 프로젝트에 파일 추가

1. TFLite 파일을 `assets` 폴더에 복사
   ```
   assets/
   └── yolo_world_ovd.tflite
   ```

2. `pubspec.yaml` 확인 (이미 설정됨)
   ```yaml
   assets:
     - assets/yolo_world_ovd.tflite
   ```

### 3. 코드 자동 적용됨

이미 `camera_detector_view.dart`가 YOLO World를 사용하도록 수정되었습니다!

---

## 📝 상세 가이드

### Colab 작업 단계별 가이드

#### 1단계: 환경 설정
```python
!pip install ultralytics tensorflow onnx onnx-tf
```

#### 2단계: 모델 다운로드 및 변환
```python
from ultralytics import YOLO

# YOLO World 모델 로드
model = YOLO('yolov8s-worldv2.pt')

# TFLite로 직접 변환 (가장 간단)
model.export(format='tflite', imgsz=640)
```

#### 3단계: 입출력 확인
```python
import tensorflow as tf

interpreter = tf.lite.Interpreter(model_path='yolov8s-worldv2.tflite')
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("입력:", input_details[0]['shape'])
print("출력:", [out['shape'] for out in output_details])
```

#### 4단계: 파일 다운로드
```python
from google.colab import files
files.download('yolov8s-worldv2.tflite')
```

---

### Flutter 코드 구조

#### 주요 파일

1. **`lib/screens/object_detection/yolo_world_tflite_detector.dart`**
   - YOLO World TFLite 모델을 처리하는 클래스
   - 이미지 전처리, 추론, 결과 파싱 담당

2. **`lib/screens/object_detection/camera_detector_view.dart`**
   - 카메라 프리뷰 및 탐지 결과 표시
   - YOLO World Detector를 사용

#### 모델 파일명 변경

모델 파일명을 바꾸려면 다음 위치 수정:

1. **`pubspec.yaml`** (line 63-64)
   ```yaml
   assets:
     - assets/your_model_name.tflite
   ```

2. **`camera_detector_view.dart`** (line 127)
   ```dart
   await _yoloDetector!.initialize(
     modelPath: 'assets/your_model_name.tflite',
   );
   ```

---

### 모델 입출력 형태에 따른 조정

TFLite 파일을 받은 후 모델의 실제 입출력 형태에 맞게 다음 부분을 조정해야 할 수 있습니다:

#### 1. 출력 형태 확인

Colab에서 확인한 출력 형태를 기반으로:

```dart
// yolo_world_tflite_detector.dart의 _parseYoloOutput 메서드 수정
```

#### 2. 바운딩 박스 형식

- **중심점 형식**: `(x_center, y_center, width, height)` → 코드에서 자동 변환
- **좌상단-우하단**: `(x1, y1, x2, y2)` → 코드에서 자동 감지

#### 3. 좌표 범위

- **정규화 좌표 (0~1)**: 코드에서 자동 처리
- **픽셀 좌표**: `_normalizedCoordinates = false` 설정

---

### 라벨 커스터마이징

YOLO World OVD는 Open Vocabulary이므로 원하는 객체 라벨을 설정할 수 있습니다:

```dart
_yoloDetector = YoloWorldTfliteDetector();
await _yoloDetector!.initialize(
  modelPath: 'assets/yolo_world_ovd.tflite',
  labels: [
    'bottle',
    'power bank',
    'hair dryer',
    'laptop',
    'phone',
    // 원하는 라벨 추가
  ],
);
```

또는 런타임에 변경:

```dart
_yoloDetector!.setLabels(['bottle', 'laptop', 'phone']);
```

---

### 성능 최적화

1. **Threshold 조정**
   ```dart
   await _yoloDetector!.detect(
     imageBytes,
     threshold: 0.25,  // 낮을수록 더 많이 탐지
     maxDetections: 5,  // 최대 탐지 개수 제한
   );
   ```

2. **프레임 처리 빈도**
   ```dart
   // 500ms마다 탐지 (camera_detector_view.dart)
   // 필요시 조정 가능
   ```

3. **모델 크기**
   - `yolov8s-worldv2.pt` (작음, 빠름) ✅ 권장
   - `yolov8m-worldv2.pt` (중간)
   - `yolov8l-worldv2.pt` (큼, 느림)

---

## 🔧 문제 해결

### 모델이 로드되지 않을 때

1. 파일 경로 확인
2. `pubspec.yaml`에 assets 추가 확인
3. `flutter clean` 후 `flutter pub get` 실행
4. 모델 파일 크기 확인 (너무 크면 문제 가능)

### 탐지가 안 될 때

1. Threshold 값 조정 (낮춰보기)
2. 모델 출력 형태 확인 및 파싱 로직 조정
3. 디버그 로그 확인:
   ```dart
   debugPrint('입력 형태: $_inputShape');
   debugPrint('출력 형태: $_outputShapes');
   ```

### 성능이 느릴 때

1. 입력 이미지 크기 줄이기 (640 → 320)
2. 프레임 처리 빈도 줄이기
3. 더 작은 모델 사용
4. INT8 양자화 모델 사용

---

## 📚 추가 리소스

- **Colab 가이드**: `YOLO_WORLD_COLAB_GUIDE.md`
- **YOLO World 문서**: https://docs.ultralytics.com/models/yolo-world/
- **TFLite 변환 가이드**: https://www.tensorflow.org/lite/convert

---

## ✅ 체크리스트

변환 전:
- [ ] Colab에서 모델 다운로드
- [ ] TFLite 변환 성공
- [ ] 입출력 형태 확인 및 기록
- [ ] 테스트 이미지로 검증

Flutter 설정:
- [ ] TFLite 파일을 `assets` 폴더에 복사
- [ ] `pubspec.yaml`에 파일 경로 추가
- [ ] `flutter pub get` 실행
- [ ] 앱 실행 및 테스트

코드 조정:
- [ ] 모델 파일명 맞춤
- [ ] 출력 형태에 맞게 파싱 로직 조정 (필요시)
- [ ] 라벨 리스트 커스터마이징 (선택)

