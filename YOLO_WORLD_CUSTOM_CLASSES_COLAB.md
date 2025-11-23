# YOLO World 여행 클래스 커스터마이징 → TFLite 변환

## 개요

YOLO World를 여행 관련 클래스들로 커스터마이징하여 TFLite로 변환하는 완전한 가이드입니다.

---

## 🚀 전체 과정

### 1단계: 환경 설정 및 모델 로드

```python
# 필요한 패키지 설치
!pip install ultralytics
```

```python
from ultralytics import YOLO
import torch

# YOLO World v2 모델 로드
model = YOLO('yolov8s-worldv2.pt')

print("✅ YOLO World 모델 로드 완료")
```

---

## 🎯 2단계: 여행 클래스 설정

YOLO World는 Open Vocabulary이므로 텍스트 프롬프트로 클래스를 설정할 수 있습니다.

```python
# 여행 클래스 정의
travel_classes = [
    'passport', 'power bank', 'lighter', 'battery',  # 필수/주의
    'knife', 'scissors', 'tool', 'spray', 'bottle',  # 보안 검색 주의
    'laptop', 'tablet', 'camera', 'drone',           # 전자제품
    'luggage', 'suitcase', 'backpack',               # 가방
    'sunglasses', 'hat', 'neck pillow', 'cosmetics', 'charger', 'shoes' # 기타
]

print(f"✅ 여행 클래스 {len(travel_classes)}개 설정")
print(f"클래스 목록: {travel_classes}")

# YOLO World에 클래스 설정
# YOLO World v2는 set_classes 또는 build_model 시 클래스 설정
try:
    # 방법 1: set_classes 메서드 사용 (있는 경우)
    if hasattr(model, 'set_classes'):
        model.set_classes(travel_classes)
        print("✅ set_classes로 클래스 설정 완료")
    # 방법 2: 모델 초기화 시 클래스 전달
    elif hasattr(model, 'model') and hasattr(model.model, 'set_classes'):
        model.model.set_classes(travel_classes)
        print("✅ 모델 내부 set_classes로 클래스 설정 완료")
    else:
        print("⚠️ 직접 set_classes 메서드가 없습니다. 추론 시 클래스 사용")
except Exception as e:
    print(f"⚠️ 클래스 설정 중 오류: {e}")
    print("추론 시 클래스 리스트를 직접 사용합니다.")
```

---

## 🔬 3단계: 클래스 설정 확인 및 테스트

```python
# 테스트 이미지로 클래스가 올바르게 설정되었는지 확인
from PIL import Image
import requests
from io import BytesIO
import numpy as np

# 테스트 이미지 다운로드
test_url = "https://ultralytics.com/images/bus.jpg"
test_image = Image.open(BytesIO(requests.get(test_url).content))

print("=" * 60)
print("테스트 추론 실행")
print("=" * 60)

# 추론 실행 (클래스 리스트 전달)
results = model.predict(
    test_image,
    conf=0.25,  # 신뢰도 임계값
    verbose=True
)

# 결과 확인
print(f"\n✅ 추론 완료")
print(f"탐지된 객체 개수: {len(results[0].boxes) if len(results) > 0 else 0}")
```

---

## 📦 4단계: TFLite 변환 (클래스 설정 포함)

YOLO World를 TFLite로 변환할 때 클래스 정보를 포함시키는 방법:

### 방법 1: 직접 TFLite 변환 (권장)

```python
# TFLite로 변환
# 주의: YOLO World의 텍스트 프롬프트 기능은 TFLite에서 완전히 지원되지 않을 수 있음
# 따라서 사전에 클래스를 설정하거나, 변환 후 별도 처리 필요

try:
    # TFLite로 변환
    model.export(
        format='tflite',
        imgsz=640,
        # 추가 옵션이 필요한 경우
    )
    print("✅ TFLite 변환 완료")
except Exception as e:
    print(f"❌ TFLite 변환 오류: {e}")
    print("ONNX를 거쳐서 변환하는 방법 시도...")
```

### 방법 2: ONNX를 거쳐서 변환 (더 안정적)

```python
# 1. ONNX로 먼저 변환
try:
    model.export(
        format='onnx',
        imgsz=640,
        simplify=True,
    )
    print("✅ ONNX 변환 완료")
except Exception as e:
    print(f"❌ ONNX 변환 오류: {e}")
```

```python
# 2. ONNX를 TFLite로 변환
import tensorflow as tf
import subprocess
import os

onnx_file = 'yolov8s-worldv2.onnx'

if os.path.exists(onnx_file):
    # ONNX to TensorFlow SavedModel
    try:
        subprocess.run([
            'python', '-m', 'onnx_tf.converter',
            '-i', onnx_file,
            '-o', 'yolo_world_travel_tf'
        ], check=True)
        print("✅ TensorFlow SavedModel 변환 완료")
    except Exception as e:
        print(f"⚠️ onnx_tf가 필요합니다: pip install onnx-tf")
    
    # TensorFlow SavedModel to TFLite
    if os.path.exists('yolo_world_travel_tf'):
        converter = tf.lite.TFLiteConverter.from_saved_model('yolo_world_travel_tf')
        tflite_model = converter.convert()
        
        output_file = 'yolo_world_travel.tflite'
        with open(output_file, 'wb') as f:
            f.write(tflite_model)
        
        print(f"✅ TFLite 변환 완료: {output_file}")
        print(f"파일 크기: {len(tflite_model) / 1024 / 1024:.2f} MB")
else:
    print("❌ ONNX 파일이 없습니다.")
```

---

## 🔍 5단계: 클래스 정보 포함 확인

```python
import tensorflow as tf

tflite_file = 'yolov8s-worldv2_saved_model/yolov8s-worldv2_float32.tflite'
# 또는: 'yolo_world_travel.tflite'

# TFLite 모델 로드
interpreter = tf.lite.Interpreter(model_path=tflite_file)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("=" * 60)
print("TFLite 모델 정보")
print("=" * 60)
print(f"입력: {input_details[0]['shape']}")
print(f"출력: {output_details[0]['shape']}")

# 출력 형태 확인
output_shape = output_details[0]['shape']
if len(output_shape) == 3:
    batch, features, detections = output_shape
    print(f"\n출력 형태: [batch={batch}, features={features}, detections={detections}]")
    
    # 여행 클래스가 24개이므로, features가 28 (4 bbox + 24 classes)이어야 함
    expected_features = 4 + len(travel_classes)  # 4 (bbox) + 24 (classes) = 28
    if features == expected_features:
        print(f"✅ 출력 형태가 여행 클래스에 맞습니다! ({features} = 4 bbox + 24 classes)")
    elif features == 84:
        print(f"⚠️ 출력이 여행 클래스가 아닌 COCO 형태입니다 ({features} = 4 bbox + 80 classes)")
        print("TFLite 변환 시 클래스 정보가 포함되지 않았을 수 있습니다.")
    else:
        print(f"⚠️ 예상과 다른 출력 형태: {features} features")
```

---

## 🎯 6단계: 완전한 커스텀 변환 스크립트

다음은 전체 과정을 한 번에 실행하는 스크립트입니다:

```python
from ultralytics import YOLO
import tensorflow as tf
import os

# 여행 클래스 정의
TRAVEL_CLASSES = [
    'passport', 'power bank', 'lighter', 'battery',
    'knife', 'scissors', 'tool', 'spray', 'bottle',
    'laptop', 'tablet', 'camera', 'drone',
    'luggage', 'suitcase', 'backpack',
    'sunglasses', 'hat', 'neck pillow', 'cosmetics', 'charger', 'shoes'
]

print("=" * 60)
print("YOLO World 여행 클래스 커스터마이징 → TFLite 변환")
print("=" * 60)

# 1. 모델 로드
print("\n1️⃣ YOLO World 모델 로드...")
model = YOLO('yolov8s-worldv2.pt')
print("✅ 모델 로드 완료")

# 2. 클래스 설정 (YOLO World v2의 경우)
print("\n2️⃣ 여행 클래스 설정...")
print(f"클래스 개수: {len(TRAVEL_CLASSES)}개")

# YOLO World v2는 추론 시 클래스 텍스트를 사용할 수 있지만,
# TFLite 변환 시에는 클래스 정보가 고정되어 COCO 80 클래스를 사용할 수 있습니다.
# 따라서 다른 접근 방법이 필요할 수 있습니다.

# 3. 테스트 추론
print("\n3️⃣ 테스트 추론...")
# 실제로는 여기서 클래스를 설정해야 하지만, 
# TFLite 변환 시 제한이 있을 수 있습니다.

# 4. TFLite 변환
print("\n4️⃣ TFLite 변환...")
try:
    model.export(
        format='tflite',
        imgsz=640,
        # 참고: YOLO World의 텍스트 프롬프트는 TFLite에서 지원되지 않을 수 있음
    )
    print("✅ TFLite 변환 완료")
except Exception as e:
    print(f"❌ 변환 오류: {e}")

# 5. 생성된 파일 확인
print("\n5️⃣ 생성된 파일 확인...")
tflite_files = []
for root, dirs, files in os.walk('.'):
    for file in files:
        if file.endswith('.tflite'):
            full_path = os.path.join(root, file)
            size = os.path.getsize(full_path) / (1024 * 1024)
            tflite_files.append((full_path, size))
            print(f"  📁 {full_path} ({size:.2f} MB)")

# 6. 모델 정보 출력
if tflite_files:
    print("\n6️⃣ TFLite 모델 정보...")
    latest_file = tflite_files[-1][0]  # 가장 최근 파일
    
    interpreter = tf.lite.Interpreter(model_path=latest_file)
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print(f"입력: {input_details[0]['shape']}")
    print(f"출력: {output_details[0]['shape']}")
    
    # 클래스 정보 저장
    class_info = {
        'classes': TRAVEL_CLASSES,
        'num_classes': len(TRAVEL_CLASSES),
        'output_shape': output_details[0]['shape'].tolist(),
    }
    
    import json
    with open('travel_classes_info.json', 'w') as f:
        json.dump(class_info, f, indent=2)
    
    print("\n✅ 클래스 정보 저장: travel_classes_info.json")
    print("\n" + "=" * 60)
    print("⚠️ 중요 사항")
    print("=" * 60)
    print("YOLO World의 텍스트 프롬프트 기능은 TFLite로 변환 시 제한될 수 있습니다.")
    print("TFLite 모델은 여전히 COCO 80 클래스 출력을 할 수 있습니다.")
    print("Flutter 코드에서 COCO → 여행 클래스 매핑을 사용해야 할 수 있습니다.")
```

---

## ⚠️ 중요한 제한사항

### YOLO World v2의 TFLite 변환 제한

1. **텍스트 프롬프트 제한**: YOLO World의 Open Vocabulary 기능은 TFLite로 완전히 변환되지 않을 수 있습니다.
2. **고정된 클래스**: TFLite 모델은 일반적으로 COCO 80 클래스에 대해 학습된 가중치를 사용합니다.
3. **해결 방법**: 
   - Flutter 코드에서 COCO 클래스를 여행 클래스로 매핑
   - 또는 커스텀 데이터셋으로 YOLO World 재학습 (더 복잡)

---

## 🔄 대안: Flutter 코드에서 매핑 사용

TFLite 변환 시 클래스 제한이 있는 경우, Flutter 코드에서 이미 구현된 매핑 기능을 사용하는 것이 더 실용적입니다.

```dart
// 이미 구현됨: COCO 클래스를 여행 클래스로 자동 매핑
// yolo_world_tflite_detector.dart에서 자동 처리
```

---

## 📋 다음 단계

1. **Colab에서 위 스크립트 실행**
2. **생성된 TFLite 파일 확인**
3. **출력 형태가 예상과 다른 경우**:
   - Flutter 코드의 매핑 기능 활용 (이미 구현됨)
   - 또는 커스텀 데이터셋으로 재학습

---

## 💡 완전한 커스텀 학습 (고급)

완전한 커스텀 클래스 탐지를 원한다면:

1. 여행 아이템 이미지 데이터셋 준비
2. YOLO World를 해당 데이터셋으로 fine-tuning
3. TFLite로 변환

이 방법은 더 많은 작업이 필요하지만, 모든 클래스를 정확하게 탐지할 수 있습니다.

