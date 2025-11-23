# YOLO World OVD → TFLite 변환 가이드 (Colab)

## 📋 개요

YOLO World OVD 모델을 Flutter에서 사용할 수 있는 TFLite 형식으로 변환하는 완전한 가이드입니다.

## 🔧 1단계: Colab 환경 설정

```python
# 필요한 패키지 설치
!pip install ultralytics onnx onnx-tf tensorflow opencv-python pillow
!pip install onnxruntime  # 선택적, ONNX 실행용
```

## 🔄 2단계: YOLO World 모델 다운로드

```python
from ultralytics import YOLO

# YOLO World 모델 다운로드 및 로드
# 옵션:
# - 'yolov8s-worldv2.pt' (작은 모델, 빠름)
# - 'yolov8m-worldv2.pt' (중간 모델)
# - 'yolov8l-worldv2.pt' (큰 모델, 정확함)
# - 'yolov8x-worldv2.pt' (매우 큰 모델, 가장 정확)

model = YOLO('yolov8s-worldv2.pt')  # 권장: 작은 모델부터 시작

# 또는 직접 다운로드
# !wget https://github.com/ultralytics/assets/releases/download/v8.2.0/yolov8s-worldv2.pt
```

## 🔨 3단계: 모델을 TFLite로 변환

### 방법 1: Ultralytics 내장 변환 (가장 간단)

```python
# TFLite로 직접 변환
model.export(
    format='tflite',
    imgsz=640,  # 입력 이미지 크기 (640x640)
    int8=False,  # INT8 양자화 (모델 크기 감소, 성능 약간 저하)
)

# 변환된 파일 확인
import os
tflite_files = [f for f in os.listdir('.') if f.endswith('.tflite')]
print("생성된 TFLite 파일:", tflite_files)

# 파일명 확인 (보통 yolov8s-worldv2.tflite)
```

### 방법 2: ONNX를 거쳐서 변환 (더 많은 제어)

```python
# 1. ONNX로 변환
model.export(
    format='onnx',
    imgsz=640,
    simplify=True,  # 모델 단순화
)

# 2. ONNX 모델 확인
import onnx
onnx_model = onnx.load('yolov8s-worldv2.onnx')
onnx.checker.check_model(onnx_model)

# 3. ONNX를 TensorFlow SavedModel로 변환
import subprocess
subprocess.run([
    'python', '-m', 'onnx_tf.converter',
    '-i', 'yolov8s-worldv2.onnx',
    '-o', 'yolo_world_tf'
], check=True)

# 4. TensorFlow SavedModel을 TFLite로 변환
import tensorflow as tf

converter = tf.lite.TFLiteConverter.from_saved_model('yolo_world_tf')
converter.optimizations = [tf.lite.Optimize.DEFAULT]  # 최적화 옵션

# INT8 양자화 (선택적, 모델 크기 감소)
# converter.representative_dataset = representative_dataset_gen
# converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
# converter.inference_input_type = tf.uint8
# converter.inference_output_type = tf.uint8

tflite_model = converter.convert()

# 5. TFLite 파일 저장
with open('yolo_world_ovd.tflite', 'wb') as f:
    f.write(tflite_model)

print(f"TFLite 모델 크기: {len(tflite_model) / 1024 / 1024:.2f} MB")
```

## 🔍 4단계: 모델 입출력 형태 확인

```python
import tensorflow as tf
import numpy as np

# TFLite 모델 로드
interpreter = tf.lite.Interpreter(model_path='yolo_world_ovd.tflite')
interpreter.allocate_tensors()

# 입력/출력 정보 확인
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("=" * 50)
print("모델 정보 확인")
print("=" * 50)

print("\n📥 입력 정보:")
for i, detail in enumerate(input_details):
    print(f"  입력 {i}:")
    print(f"    이름: {detail.get('name', 'N/A')}")
    print(f"    형태: {detail['shape']}")
    print(f"    타입: {detail['dtype']}")
    print(f"    스케일: {detail.get('quantization_parameters', {}).get('scales', 'N/A')}")
    print(f"    제로포인트: {detail.get('quantization_parameters', {}).get('zero_points', 'N/A')}")

print("\n📤 출력 정보:")
for i, detail in enumerate(output_details):
    print(f"  출력 {i}:")
    print(f"    이름: {detail.get('name', 'N/A')}")
    print(f"    형태: {detail['shape']}")
    print(f"    타입: {detail['dtype']}")
    print(f"    스케일: {detail.get('quantization_parameters', {}).get('scales', 'N/A')}")
    print(f"    제로포인트: {detail.get('quantization_parameters', {}).get('zero_points', 'N/A')}")

# 출력 형태 분석
print("\n🔬 출력 형태 분석:")
first_output_shape = output_details[0]['shape']
print(f"  첫 번째 출력 형태: {first_output_shape}")

if len(first_output_shape) == 3:
    batch, num_detections, features = first_output_shape
    print(f"  배치 크기: {batch}")
    print(f"  탐지 개수: {num_detections}")
    print(f"  특성 수: {features}")
    
    if features == 6:
        print("  → 형태: [batch, detections, 6] (x1, y1, x2, y2, score, class)")
    elif features > 6:
        print(f"  → 형태: [batch, detections, {features}] (바운딩 박스 + 점수)")
        print(f"  → 예상: 바운딩 박스 4개 (x, y, w, h 또는 x1, y1, x2, y2) + {features - 4}개 점수")
    else:
        print(f"  → 형태: [batch, detections, {features}] (형태 분석 필요)")
```

## 🧪 5단계: 모델 테스트

```python
import numpy as np
from PIL import Image
import requests
from io import BytesIO

# 테스트 이미지 로드 (예시)
url = "https://ultralytics.com/images/bus.jpg"
response = requests.get(url)
test_image = Image.open(BytesIO(response.content))

# 또는 로컬 이미지 사용
# test_image = Image.open('test_image.jpg')

print(f"원본 이미지 크기: {test_image.size}")

# 이미지 전처리 (YOLO 입력 형식에 맞게)
input_size = 640
test_image_resized = test_image.resize((input_size, input_size))
image_array = np.array(test_image_resized, dtype=np.float32) / 255.0
image_array = np.expand_dims(image_array, axis=0)  # 배치 차원 추가

print(f"전처리된 이미지 형태: {image_array.shape}")

# 추론 실행
interpreter.set_tensor(input_details[0]['index'], image_array)
interpreter.invoke()

# 결과 확인
output_data = interpreter.get_tensor(output_details[0]['index'])
print(f"\n📊 추론 결과:")
print(f"  출력 형태: {output_data.shape}")
print(f"  출력 데이터 타입: {output_data.dtype}")

# 첫 몇 개 탐지 결과 확인
if len(output_data.shape) == 3:
    num_to_show = min(5, output_data.shape[1])
    print(f"\n  첫 {num_to_show}개 탐지 결과:")
    for i in range(num_to_show):
        detection = output_data[0, i, :]
        print(f"    탐지 {i+1}: {detection[:10]}...")  # 처음 10개 값만 표시
```

## 📝 6단계: 출력 형태 분석 및 문서화

```python
# 출력 형태를 분석하여 Flutter 코드에 필요한 정보 추출
output_shape = output_details[0]['shape']

analysis = {
    'input_size': input_details[0]['shape'][1],  # 일반적으로 640
    'output_shape': output_shape,
    'num_outputs': len(output_details),
    'bbox_format': 'unknown',  # 'center' 또는 'corner'
    'coordinates_normalized': True,  # True 또는 False
}

# 출력 형태에 따라 분석
if len(output_shape) == 3:
    batch, num_det, features = output_shape
    
    # 바운딩 박스 형식 추정
    if features == 6:
        analysis['bbox_format'] = 'corner'  # (x1, y1, x2, y2, score, class)
    elif features == 5:
        analysis['bbox_format'] = 'center'  # (x, y, w, h, score)
    elif features > 6:
        # (x, y, w, h, objectness, scores...) 또는 (x1, y1, x2, y2, scores...)
        analysis['bbox_format'] = 'needs_investigation'

print("\n📋 Flutter 코드에 필요한 정보:")
print(json.dumps(analysis, indent=2))
```

## 💾 7단계: 파일 다운로드

```python
from google.colab import files

# TFLite 파일 다운로드
files.download('yolo_world_ovd.tflite')

# 또는 여러 파일을 ZIP으로 묶어서 다운로드
import zipfile

with zipfile.ZipFile('yolo_world_files.zip', 'w') as zipf:
    zipf.write('yolo_world_ovd.tflite')
    # 필요한 경우 다른 파일도 추가

files.download('yolo_world_files.zip')
```

## 📋 8단계: 모델 정보 기록

```python
# 모델 정보를 텍스트 파일로 저장
model_info = f"""
YOLO World OVD TFLite 모델 정보
================================

생성 날짜: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
원본 모델: yolov8s-worldv2.pt
입력 크기: {input_details[0]['shape']}
출력 형태: {[out['shape'] for out in output_details]}
출력 개수: {len(output_details)}

입력 정보:
{json.dumps([{k: str(v) for k, v in detail.items()} for detail in input_details], indent=2)}

출력 정보:
{json.dumps([{k: str(v) for k, v in detail.items()} for detail in output_details], indent=2)}

테스트 결과:
- 출력 형태 분석: {analysis}
"""

with open('model_info.txt', 'w') as f:
    f.write(model_info)

files.download('model_info.txt')
```

## 🚨 주의사항

1. **모델 크기**: YOLO World 모델은 크기가 큽니다. 모바일에서는 INT8 양자화를 고려하세요.

2. **출력 형태**: YOLO World 모델의 출력 형태는 변환 방법에 따라 다를 수 있습니다. 반드시 확인하세요.

3. **성능**: TFLite로 변환 시 성능이 원본 모델보다 약간 낮을 수 있습니다.

4. **테스트**: 변환 후 반드시 테스트 이미지로 검증하세요.

## 🔧 Flutter에서 사용하기

1. `assets` 폴더에 TFLite 파일 복사
2. `pubspec.yaml`에 파일 경로 추가
3. 모델 정보에 맞게 `yolo_world_tflite_detector.dart` 조정

## 📚 참고 링크

- YOLO World: https://github.com/ultralytics/ultralytics
- TFLite 변환: https://www.tensorflow.org/lite/convert
- Ultralytics 문서: https://docs.ultralytics.com/

