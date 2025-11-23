# 🧪 TFLite 모델 빠른 테스트 (Colab)

## 단계별 테스트 코드

다음 코드를 순서대로 실행하여 모델이 올바르게 작동하는지 확인하세요.

```python
# ============================================
# 단계 1: 모델 로드 및 기본 정보 확인
# ============================================
import tensorflow as tf
import numpy as np

tflite_file = 'yolov8s-worldv2_saved_model/yolov8s-worldv2_float32.tflite'

print("=" * 60)
print("1. 모델 로드")
print("=" * 60)

interpreter = tf.lite.Interpreter(model_path=tflite_file)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print(f"✅ 모델 로드 성공")
print(f"📥 입력: {input_details[0]['shape']} ({input_details[0]['dtype']})")
print(f"📤 출력: {output_details[0]['shape']} ({output_details[0]['dtype']})")

# 출력 형태 확인
output_shape = output_details[0]['shape']
if len(output_shape) == 3 and output_shape[1] == 84:
    print(f"✅ YOLO World v2 출력 형태 확인: [batch={output_shape[0]}, features={output_shape[1]}, detections={output_shape[2]}]")
else:
    print(f"⚠️ 예상과 다른 출력 형태: {output_shape}")

# ============================================
# 단계 2: 더미 입력으로 테스트
# ============================================
print("\n" + "=" * 60)
print("2. 더미 입력 테스트")
print("=" * 60)

# 랜덤 이미지 생성
dummy_input = np.random.rand(1, 640, 640, 3).astype(np.float32)
print(f"더미 입력 형태: {dummy_input.shape}")

interpreter.set_tensor(input_details[0]['index'], dummy_input)
interpreter.invoke()

output_data = interpreter.get_tensor(output_details[0]['index'])

print(f"✅ 추론 완료")
print(f"📊 출력 형태: {output_data.shape}")
print(f"📊 출력 값 범위: [{output_data.min():.3f}, {output_data.max():.3f}]")
print(f"📊 출력 평균: {output_data.mean():.6f}")
print(f"📊 출력 표준편차: {output_data.std():.6f}")

# 0이 아닌 값 개수 확인
non_zero = np.count_nonzero(output_data)
total = output_data.size
print(f"📊 0이 아닌 값: {non_zero} / {total} ({non_zero/total*100:.2f}%)")

if non_zero == 0:
    print("❌ 경고: 모든 출력 값이 0입니다! 모델이 올바르게 작동하지 않을 수 있습니다.")
elif non_zero < total * 0.01:
    print("⚠️ 경고: 출력 값의 대부분이 0입니다. 모델을 확인해보세요.")

# ============================================
# 단계 3: 실제 이미지로 테스트
# ============================================
print("\n" + "=" * 60)
print("3. 실제 이미지 테스트")
print("=" * 60)

from PIL import Image
import requests
from io import BytesIO

# 테스트 이미지 다운로드
url = "https://ultralytics.com/images/bus.jpg"
response = requests.get(url)
test_image = Image.open(BytesIO(response.content))

# 이미지 전처리
test_image_resized = test_image.resize((640, 640), Image.LANCZOS)
image_array = np.array(test_image_resized, dtype=np.float32) / 255.0
image_array = np.expand_dims(image_array, axis=0)

print(f"이미지 전처리 완료: {image_array.shape}")

# 추론
interpreter.set_tensor(input_details[0]['index'], image_array)
interpreter.invoke()

output_data = interpreter.get_tensor(output_details[0]['index'])

print(f"✅ 추론 완료")
print(f"📊 출력 값 범위: [{output_data.min():.3f}, {output_data.max():.3f}]")

# ============================================
# 단계 4: 결과 파싱 테스트
# ============================================
print("\n" + "=" * 60)
print("4. 결과 파싱 테스트")
print("=" * 60)

# YOLO World v2: [1, 84, 8400]
batch, features, num_detections = output_data.shape

print(f"배치: {batch}, 특성: {features}, 탐지: {num_detections}")

# 첫 번째 탐지의 바운딩 박스 확인
det_idx = 0
x_center = float(output_data[0, 0, det_idx])
y_center = float(output_data[0, 1, det_idx])
width = float(output_data[0, 2, det_idx])
height = float(output_data[0, 3, det_idx])

print(f"\n첫 번째 탐지 (인덱스 {det_idx}):")
print(f"  중심점: ({x_center:.4f}, {y_center:.4f})")
print(f"  크기: ({width:.4f}, {height:.4f})")

# 좌표 유효성 확인
if 0 <= x_center <= 1 and 0 <= y_center <= 1 and 0 < width <= 1 and 0 < height <= 1:
    print("  ✅ 좌표가 유효한 범위(0~1)에 있습니다")
else:
    print("  ❌ 경고: 좌표가 유효한 범위를 벗어났습니다")

# 클래스 점수 확인
class_scores = []
for class_idx in range(80):
    score = float(output_data[0, 4 + class_idx, det_idx])
    class_scores.append(score)

max_score = max(class_scores)
max_class_idx = class_scores.index(max_score)

print(f"\n클래스 점수:")
print(f"  최고 점수: {max_score:.4f} (클래스 인덱스: {max_class_idx})")
print(f"  평균 점수: {np.mean(class_scores):.6f}")

# COCO 클래스 이름
coco_classes = [
    'person', 'bicycle', 'car', 'motorcycle', 'airplane', 'bus', 'train', 'truck',
    'boat', 'traffic light', 'fire hydrant', 'stop sign', 'parking meter', 'bench',
    'bird', 'cat', 'dog', 'horse', 'sheep', 'cow', 'elephant', 'bear', 'zebra',
    'giraffe', 'backpack', 'umbrella', 'handbag', 'tie', 'suitcase', 'frisbee',
    'skis', 'snowboard', 'sports ball', 'kite', 'baseball bat', 'baseball glove',
    'skateboard', 'surfboard', 'tennis racket', 'bottle', 'wine glass', 'cup',
    'fork', 'knife', 'spoon', 'bowl', 'banana', 'apple', 'sandwich', 'orange',
    'broccoli', 'carrot', 'hot dog', 'pizza', 'donut', 'cake', 'chair', 'couch',
    'potted plant', 'bed', 'dining table', 'toilet', 'tv', 'laptop', 'mouse',
    'remote', 'keyboard', 'cell phone', 'microwave', 'oven', 'toaster', 'sink',
    'refrigerator', 'book', 'clock', 'vase', 'scissors', 'teddy bear', 'hair drier',
    'toothbrush'
]

if max_class_idx < len(coco_classes):
    print(f"  최고 점수 클래스: {coco_classes[max_class_idx]}")

# ============================================
# 단계 5: 임계값별 탐지 개수 확인
# ============================================
print("\n" + "=" * 60)
print("5. 임계값별 탐지 개수")
print("=" * 60)

thresholds = [0.1, 0.25, 0.5, 0.75]
detection_counts = []

for threshold in thresholds:
    count = 0
    for det_idx in range(num_detections):
        # 각 탐지의 최고 클래스 점수 찾기
        max_score = 0.0
        for class_idx in range(80):
            score = float(output_data[0, 4 + class_idx, det_idx])
            if score > max_score:
                max_score = score
        
        if max_score >= threshold:
            count += 1
    
    detection_counts.append(count)
    print(f"임계값 {threshold:.2f}: {count}개 탐지")

# ============================================
# 결론
# ============================================
print("\n" + "=" * 60)
print("결론")
print("=" * 60)

if non_zero > 0 and max(class_scores) > 0:
    print("✅ 모델이 정상적으로 작동하는 것으로 보입니다!")
    print(f"   - 출력 값이 모두 0이 아님")
    print(f"   - 클래스 점수가 존재함")
    if detection_counts[1] > 0:  # threshold=0.25
        print(f"   - 임계값 0.25에서 {detection_counts[1]}개 탐지")
    else:
        print(f"   ⚠️ 임계값 0.25에서 탐지 없음 (임계값을 낮춰보세요)")
else:
    print("❌ 모델에 문제가 있을 수 있습니다!")
    print("   - 출력 값이 모두 0이거나")
    print("   - 클래스 점수가 없습니다")
```

## 한 번에 실행하기

```python
# 모든 테스트를 한 번에 실행
!pip install -q pillow requests

import tensorflow as tf
import numpy as np
from PIL import Image
import requests
from io import BytesIO

# 모델 로드
tflite_file = 'yolov8s-worldv2_saved_model/yolov8s-worldv2_float32.tflite'
interpreter = tf.lite.Interpreter(model_path=tflite_file)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print(f"입력: {input_details[0]['shape']}")
print(f"출력: {output_details[0]['shape']}")

# 실제 이미지 테스트
url = "https://ultralytics.com/images/bus.jpg"
test_image = Image.open(BytesIO(requests.get(url).content)).resize((640, 640))
image_array = np.expand_dims(np.array(test_image, dtype=np.float32) / 255.0, axis=0)

interpreter.set_tensor(input_details[0]['index'], image_array)
interpreter.invoke()
output_data = interpreter.get_tensor(output_details[0]['index'])

# 결과 분석
print(f"출력 범위: [{output_data.min():.3f}, {output_data.max():.3f}]")
print(f"0이 아닌 값: {np.count_nonzero(output_data)} / {output_data.size}")

# 첫 100개 탐지 중 최고 점수
max_scores = []
for det_idx in range(min(100, output_data.shape[2])):
    max_score = max([float(output_data[0, 4+i, det_idx]) for i in range(80)])
    max_scores.append(max_score)

print(f"상위 100개 탐지 중 최고 점수: {max(max_scores):.4f}")
print(f"평균 점수: {np.mean(max_scores):.4f}")

if max(max_scores) > 0.25:
    print("✅ 모델이 정상 작동합니다!")
else:
    print("⚠️ 점수가 낮습니다. 임계값을 낮춰보세요.")
```

## 문제 해결

1. **모든 출력이 0**: 모델 변환 문제 → 모델을 다시 변환
2. **좌표가 유효 범위를 벗어남**: 출력 파싱 문제 → Flutter 코드 확인
3. **점수가 너무 낮음**: 이미지나 임계값 문제 → 다른 이미지나 낮은 임계값 시도

