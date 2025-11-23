# YOLO World OVD → TFLite 변환 가이드 (Colab) - 수정 버전

## ⚠️ 중요: 파일 경로 수정

Ultralytics가 TFLite를 직접 변환할 때 파일 경로가 예상과 다릅니다. 실제 생성된 파일은 `yolov8s-worldv2_saved_model/yolov8s-worldv2_float32.tflite`입니다.

---

## 🔧 1단계: 환경 설정

```python
# 필요한 패키지 설치
!pip install ultralytics tensorflow
```

---

## 🔄 2단계: YOLO World 모델 다운로드 및 TFLite 변환

```python
from ultralytics import YOLO

# YOLO World 모델 로드
model = YOLO('yolov8s-worldv2.pt')

# TFLite로 변환 (이 메서드가 자동으로 변환함)
model.export(format='tflite', imgsz=640)

# ✅ 중요: 실제 생성된 파일 확인
import os

# 생성된 파일들 확인
print("생성된 파일들:")
for root, dirs, files in os.walk('.'):
    for file in files:
        if file.endswith('.tflite'):
            full_path = os.path.join(root, file)
            file_size = os.path.getsize(full_path) / (1024 * 1024)  # MB
            print(f"  📁 {full_path} ({file_size:.2f} MB)")

# 실제 TFLite 파일 경로 (Ultralytics가 생성한 경로)
tflite_file = 'yolov8s-worldv2_saved_model/yolov8s-worldv2_float32.tflite'
print(f"\n✅ TFLite 파일 경로: {tflite_file}")

# 파일 존재 확인
if os.path.exists(tflite_file):
    print(f"✅ 파일 존재 확인: {os.path.getsize(tflite_file) / (1024*1024):.2f} MB")
else:
    print("❌ 파일을 찾을 수 없습니다!")
```

---

## 🔍 3단계: 입출력 형태 확인 (올바른 경로 사용)

```python
import tensorflow as tf
import numpy as np

# ✅ 올바른 파일 경로 사용
tflite_file = 'yolov8s-worldv2_saved_model/yolov8s-worldv2_float32.tflite'

# TFLite 모델 로드
interpreter = tf.lite.Interpreter(model_path=tflite_file)
interpreter.allocate_tensors()

# 입력/출력 정보 확인
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("=" * 60)
print("📥 입력 정보:")
for i, detail in enumerate(input_details):
    print(f"  입력 {i}:")
    print(f"    이름: {detail.get('name', 'N/A')}")
    print(f"    형태: {detail['shape']}")
    print(f"    타입: {detail['dtype']}")

print("\n📤 출력 정보:")
for i, detail in enumerate(output_details):
    print(f"  출력 {i}:")
    print(f"    이름: {detail.get('name', 'N/A')}")
    print(f"    형태: {detail['shape']}")
    print(f"    타입: {detail['dtype']}")

# 출력 형태 분석
print("\n🔬 출력 형태 분석:")
if output_details:
    first_output_shape = output_details[0]['shape']
    print(f"  첫 번째 출력 형태: {first_output_shape}")
    
    if len(first_output_shape) == 3:
        batch, features, num_detections = first_output_shape
        print(f"  배치 크기: {batch}")
        print(f"  특성 수 (features): {features}")
        print(f"  탐지 개수 (detections): {num_detections}")
        
        # YOLO World v2 출력 형태: [1, 84, 8400]
        # 84 = 4 (바운딩 박스) + 80 (COCO 클래스)
        # 8400 = 탐지 앵커 포인트 개수
        if features == 84:
            print("  → 형태: [batch, 84, detections]")
            print("    - 4개: 바운딩 박스 (x, y, w, h)")
            print("    - 80개: COCO 클래스 점수")
        elif features == num_detections:
            print(f"  → 형태: [batch, detections, {features}]")
        else:
            print(f"  → 형태: [batch, {features}, {num_detections}]")
```

---

## 📋 4단계: 파일을 원하는 이름으로 복사

```python
import shutil

# 원본 파일 경로
source_file = 'yolov8s-worldv2_saved_model/yolov8s-worldv2_float32.tflite'
# 복사할 파일명 (Flutter에서 사용할 이름)
target_file = 'yolo_world_ovd.tflite'

# 파일 복사
shutil.copy(source_file, target_file)

print(f"✅ 파일 복사 완료: {target_file}")
print(f"   파일 크기: {os.path.getsize(target_file) / (1024*1024):.2f} MB")
```

---

## 🧪 5단계: 모델 테스트 (선택적)

```python
import numpy as np
from PIL import Image
import requests
from io import BytesIO

# 테스트 이미지 로드
url = "https://ultralytics.com/images/bus.jpg"
response = requests.get(url)
test_image = Image.open(BytesIO(response.content))

# 이미지 전처리
input_size = 640
test_image_resized = test_image.resize((input_size, input_size))
image_array = np.array(test_image_resized, dtype=np.float32) / 255.0
image_array = np.expand_dims(image_array, axis=0)  # 배치 차원 추가

print(f"입력 이미지 형태: {image_array.shape}")

# 추론 실행
tflite_file = 'yolo_world_ovd.tflite'  # 또는 원본 경로
interpreter = tf.lite.Interpreter(model_path=tflite_file)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

interpreter.set_tensor(input_details[0]['index'], image_array)
interpreter.invoke()

# 결과 확인
output_data = interpreter.get_tensor(output_details[0]['index'])
print(f"\n📊 추론 결과:")
print(f"  출력 형태: {output_data.shape}")
print(f"  출력 데이터 타입: {output_data.dtype}")
print(f"  출력 샘플 (처음 5개 값): {output_data[0, :5, 0]}")
```

---

## 💾 6단계: 파일 다운로드

```python
from google.colab import files

# 최종 TFLite 파일 다운로드
files.download('yolo_world_ovd.tflite')

# 또는 원본 파일 다운로드
# files.download('yolov8s-worldv2_saved_model/yolov8s-worldv2_float32.tflite')
```

---

## ✅ 완전한 스크립트 (한 번에 실행)

```python
# ============================================
# YOLO World OVD → TFLite 변환 (완전한 스크립트)
# ============================================

# 1. 패키지 설치
!pip install ultralytics tensorflow

# 2. 모델 변환
from ultralytics import YOLO
import os
import shutil

model = YOLO('yolov8s-worldv2.pt')
model.export(format='tflite', imgsz=640)

# 3. 생성된 파일 찾기
tflite_source = 'yolov8s-worldv2_saved_model/yolov8s-worldv2_float32.tflite'
tflite_target = 'yolo_world_ovd.tflite'

if os.path.exists(tflite_source):
    # 4. 파일 복사
    shutil.copy(tflite_source, tflite_target)
    file_size = os.path.getsize(tflite_target) / (1024 * 1024)
    print(f"✅ TFLite 파일 생성 완료: {tflite_target} ({file_size:.2f} MB)")
    
    # 5. 입출력 확인
    import tensorflow as tf
    interpreter = tf.lite.Interpreter(model_path=tflite_target)
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print(f"\n📥 입력: {input_details[0]['shape']}")
    print(f"📤 출력: {output_details[0]['shape']}")
    
    # 6. 다운로드
    from google.colab import files
    files.download(tflite_target)
    print(f"\n✅ 파일 다운로드 완료!")
else:
    print("❌ TFLite 파일을 찾을 수 없습니다!")
```

---

## 🚨 문제 해결

### 문제: 파일을 찾을 수 없음

**해결책:**
```python
import os

# 현재 디렉토리의 모든 .tflite 파일 찾기
for root, dirs, files in os.walk('.'):
    for file in files:
        if file.endswith('.tflite'):
            print(os.path.join(root, file))
```

### 문제: 파일 경로 오류

**해결책:** 항상 실제 생성된 파일 경로를 사용하세요:
- ✅ 올바름: `yolov8s-worldv2_saved_model/yolov8s-worldv2_float32.tflite`
- ❌ 잘못됨: `yolov8s-worldv2.tflite`

---

## 📝 참고사항

1. **출력 형태**: YOLO World v2는 `[1, 84, 8400]` 형태의 출력을 사용합니다
   - 84 = 4 (바운딩 박스) + 80 (COCO 클래스)
   - 8400 = 탐지 앵커 포인트 개수

2. **파일 크기**: 약 48MB (float32)

3. **성능 최적화**: INT8 양자화를 원하면 추가 작업 필요

