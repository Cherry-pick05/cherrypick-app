# YOLO World OVD TFLite 모델 설정 가이드

## 1. YOLO World OVD와 MediaPipe OVD의 차이점

### MediaPipe OVD
- **입력**: 이미지만
- **출력**: [batch, num_detections, 6] 형태 (x1, y1, x2, y2, score, class_index)
- **바운딩 박스**: 좌상단-우하단 좌표 (x1, y1, x2, y2)

### YOLO World OVD
- **입력**: 이미지 + (선택적) 텍스트 프롬프트 임베딩
- **출력 형태**: 여러 가지 가능
  - 형태 1: [1, num_detections, 4 + num_classes] - (x, y, w, h, scores...)
  - 형태 2: [1, num_detections, 5 + num_classes] - (x, y, w, h, objectness, scores...)
  - 형태 3: 분리된 출력 - 박스 [1, num_detections, 4], 점수 [1, num_detections, num_classes]
- **바운딩 박스**: 중심점 기반 (x_center, y_center, width, height) 또는 좌상단-우하단
- **좌표 시스템**: 정규화된 좌표 (0.0 ~ 1.0) 또는 픽셀 좌표

## 2. Colab에서 할 작업

### 2.1. YOLO World 모델을 TFLite로 변환

```python
# Colab 노트북 예시
!pip install ultralytics onnx onnx-tf tensorflow

from ultralytics import YOLO
import tensorflow as tf

# 1. YOLO World 모델 로드
model = YOLO('yolov8s-worldv2.pt')  # 또는 사용할 모델

# 2. ONNX로 변환
model.export(format='onnx')

# 3. ONNX를 TFLite로 변환
import onnx
from onnx_tf.backend import prepare

onnx_model = onnx.load('yolov8s-worldv2.onnx')
tf_rep = prepare(onnx_model)
tf_rep.export_graph('yolo_world_tf')

# 4. TFLite로 변환
converter = tf.lite.TFLiteConverter.from_saved_model('yolo_world_tf')
tflite_model = converter.convert()

# 5. TFLite 파일 저장
with open('yolo_world_ovd.tflite', 'wb') as f:
    f.write(tflite_model)

# 파일 다운로드
from google.colab import files
files.download('yolo_world_ovd.tflite')
```

### 2.2. 모델 입출력 형태 확인

```python
import tensorflow as tf

# TFLite 모델 로드
interpreter = tf.lite.Interpreter(model_path='yolo_world_ovd.tflite')
interpreter.allocate_tensors()

# 입력/출력 정보 확인
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("=== 입력 정보 ===")
for i, detail in enumerate(input_details):
    print(f"Input {i}:")
    print(f"  이름: {detail['name']}")
    print(f"  형태: {detail['shape']}")
    print(f"  타입: {detail['dtype']}")

print("\n=== 출력 정보 ===")
for i, detail in enumerate(output_details):
    print(f"Output {i}:")
    print(f"  이름: {detail['name']}")
    print(f"  형태: {detail['shape']}")
    print(f"  타입: {detail['dtype']}")
```

### 2.3. 모델 테스트

```python
import numpy as np
from PIL import Image

# 테스트 이미지 로드
image = Image.open('test_image.jpg')
image = image.resize((640, 640))
image_array = np.array(image, dtype=np.float32) / 255.0
image_array = np.expand_dims(image_array, axis=0)

# 추론 실행
interpreter.set_tensor(input_details[0]['index'], image_array)
interpreter.invoke()

# 결과 확인
output_data = interpreter.get_tensor(output_details[0]['index'])
print(f"출력 형태: {output_data.shape}")
print(f"출력 샘플: {output_data[0, :3, :]}")
```

## 3. Flutter 코드 수정 필요 사항

모델 입출력 형태에 따라 다음 부분을 수정해야 합니다:

1. **입력 전처리**: 이미지 크기 및 정규화 방식
2. **출력 파싱**: 바운딩 박스 형식 및 점수 추출 방식
3. **좌표 변환**: 중심점 기반 vs 좌상단-우하단
4. **클래스 점수**: 어떻게 추출하는지

## 4. 확인 사항

TFLite 파일을 받으면 다음을 확인하세요:
- 모델 입력 크기 (640x640, 320x320 등)
- 바운딩 박스 형식 (중심점 vs 좌상단-우하단)
- 좌표 범위 (0~1 정규화 vs 픽셀 좌표)
- 출력 텐서 개수 및 형태

