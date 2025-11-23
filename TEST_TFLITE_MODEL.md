# TFLite 모델 검증 가이드

## 🧪 Colab에서 모델 테스트

다음 코드를 Colab에 실행하여 모델이 올바르게 작동하는지 확인하세요.

```python
import tensorflow as tf
import numpy as np
from PIL import Image
import requests
from io import BytesIO
import matplotlib.pyplot as plt
import matplotlib.patches as patches

# ============================================
# 1. 모델 로드 및 확인
# ============================================
tflite_file = 'yolov8s-worldv2_saved_model/yolov8s-worldv2_float32.tflite'
# 또는 복사한 파일: 'yolo_world_ovd.tflite'

print("=" * 60)
print("1. 모델 로드")
print("=" * 60)

interpreter = tf.lite.Interpreter(model_path=tflite_file)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print(f"✅ 모델 로드 성공")
print(f"📥 입력 형태: {input_details[0]['shape']}")
print(f"📥 입력 타입: {input_details[0]['dtype']}")
print(f"📤 출력 형태: {output_details[0]['shape']}")
print(f"📤 출력 타입: {output_details[0]['dtype']}")

# ============================================
# 2. 테스트 이미지 준비
# ============================================
print("\n" + "=" * 60)
print("2. 테스트 이미지 준비")
print("=" * 60)

# 테스트 이미지 다운로드 (버스 이미지 - COCO 데이터셋)
url = "https://ultralytics.com/images/bus.jpg"
response = requests.get(url)
test_image = Image.open(BytesIO(response.content))
original_size = test_image.size

print(f"원본 이미지 크기: {original_size}")

# 이미지 표시
plt.figure(figsize=(10, 8))
plt.imshow(test_image)
plt.title("원본 테스트 이미지")
plt.axis('off')
plt.show()

# ============================================
# 3. 이미지 전처리
# ============================================
print("\n" + "=" * 60)
print("3. 이미지 전처리")
print("=" * 60)

input_size = 640

# 리사이즈 (letterbox 방식으로)
test_image_resized = test_image.resize((input_size, input_size), Image.LANCZOS)

# RGB 배열로 변환 및 정규화 (0~1)
image_array = np.array(test_image_resized, dtype=np.float32) / 255.0

# 배치 차원 추가
image_array = np.expand_dims(image_array, axis=0)  # [1, 640, 640, 3]

print(f"전처리된 이미지 형태: {image_array.shape}")
print(f"이미지 값 범위: [{image_array.min():.3f}, {image_array.max():.3f}]")

# ============================================
# 4. 모델 추론 실행
# ============================================
print("\n" + "=" * 60)
print("4. 모델 추론 실행")
print("=" * 60)

interpreter.set_tensor(input_details[0]['index'], image_array)
interpreter.invoke()

# 결과 가져오기
output_data = interpreter.get_tensor(output_details[0]['index'])

print(f"✅ 추론 완료")
print(f"📊 출력 형태: {output_data.shape}")
print(f"📊 출력 값 범위: [{output_data.min():.3f}, {output_data.max():.3f}]")
print(f"📊 출력 평균: {output_data.mean():.3f}")
print(f"📊 출력 표준편차: {output_data.std():.3f}")

# 출력 샘플 확인
print(f"\n출력 샘플 (첫 번째 탐지, 처음 10개 값):")
print(output_data[0, :10, 0])

# ============================================
# 5. 결과 파싱 및 시각화
# ============================================
print("\n" + "=" * 60)
print("5. 결과 파싱 (YOLO World v2 형식)")
print("=" * 60)

# YOLO World v2 출력 형태: [1, 84, 8400]
# 84 = 4 (bbox: x, y, w, h) + 80 (COCO 클래스 점수)
# 8400 = 탐지 앵커 포인트 개수

batch, features, num_detections = output_data.shape
print(f"배치: {batch}, 특성: {features}, 탐지: {num_detections}")

# COCO 클래스 이름 (80개)
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

# 각 탐지 결과 파싱
detections = []
threshold = 0.25  # 신뢰도 임계값

for det_idx in range(num_detections):
    # 출력 데이터에서 해당 탐지의 특성 추출
    # output_data[0, feature_idx, det_idx] 형태
    x_center = float(output_data[0, 0, det_idx])
    y_center = float(output_data[0, 1, det_idx])
    width = float(output_data[0, 2, det_idx])
    height = float(output_data[0, 3, det_idx])
    
    # 클래스 점수 추출 (4~83)
    class_scores = []
    for class_idx in range(80):
        score = float(output_data[0, 4 + class_idx, det_idx])
        class_scores.append(score)
    
    # 최고 점수 찾기
    max_score = max(class_scores)
    max_class_idx = class_scores.index(max_score)
    
    # 임계값 이상인 경우만 저장
    if max_score >= threshold:
        # 좌표 변환 (정규화 좌표 → 픽셀 좌표)
        x1 = (x_center - width / 2) * input_size
        y1 = (y_center - height / 2) * input_size
        x2 = (x_center + width / 2) * input_size
        y2 = (y_center + height / 2) * input_size
        
        detections.append({
            'class': coco_classes[max_class_idx],
            'score': max_score,
            'bbox': [x1, y1, x2, y2],
            'class_idx': max_class_idx
        })

# 신뢰도 순으로 정렬
detections.sort(key=lambda x: x['score'], reverse=True)
detections = detections[:10]  # 상위 10개만

print(f"\n✅ 탐지된 객체 개수: {len(detections)}개 (임계값: {threshold})")

for i, det in enumerate(detections[:5]):  # 상위 5개만 출력
    print(f"\n탐지 {i+1}:")
    print(f"  클래스: {det['class']}")
    print(f"  신뢰도: {det['score']:.4f}")
    print(f"  바운딩 박스: ({det['bbox'][0]:.1f}, {det['bbox'][1]:.1f}, {det['bbox'][2]:.1f}, {det['bbox'][3]:.1f})")

# ============================================
# 6. 결과 시각화
# ============================================
print("\n" + "=" * 60)
print("6. 결과 시각화")
print("=" * 60)

fig, ax = plt.subplots(1, 1, figsize=(12, 8))
ax.imshow(test_image_resized)
ax.set_title(f"탐지 결과 (상위 {len(detections)}개)", fontsize=16)
ax.axis('off')

# 바운딩 박스 그리기
colors = plt.cm.get_cmap('tab20', len(detections))
for i, det in enumerate(detections):
    x1, y1, x2, y2 = det['bbox']
    width = x2 - x1
    height = y2 - y1
    
    # 박스 그리기
    rect = patches.Rectangle(
        (x1, y1), width, height,
        linewidth=2, edgecolor=colors(i), facecolor='none'
    )
    ax.add_patch(rect)
    
    # 라벨 추가
    label = f"{det['class']}: {det['score']:.2f}"
    ax.text(x1, y1 - 5, label, color=colors(i), fontsize=10, 
            bbox=dict(boxstyle='round,pad=0.3', facecolor='white', alpha=0.7))

plt.tight_layout()
plt.show()

print("✅ 시각화 완료!")
```

## 🔍 추가 검증 코드

### 출력 값 분포 확인

```python
# 출력 값의 분포 확인
import matplotlib.pyplot as plt

output_flat = output_data.flatten()

plt.figure(figsize=(12, 4))

plt.subplot(1, 2, 1)
plt.hist(output_flat, bins=100, alpha=0.7)
plt.xlabel('출력 값')
plt.ylabel('빈도')
plt.title('출력 값 분포')
plt.grid(True, alpha=0.3)

plt.subplot(1, 2, 2)
# 큰 값들만 필터링
large_values = output_flat[output_flat > 0.1]
if len(large_values) > 0:
    plt.hist(large_values, bins=50, alpha=0.7, color='orange')
    plt.xlabel('출력 값 (> 0.1)')
    plt.ylabel('빈도')
    plt.title('큰 출력 값 분포')
    plt.grid(True, alpha=0.3)

plt.tight_layout()
plt.show()

print(f"전체 출력 값 중 0.1 이상: {(output_flat > 0.1).sum()}개 ({(output_flat > 0.1).mean()*100:.2f}%)")
print(f"전체 출력 값 중 0.5 이상: {(output_flat > 0.5).sum()}개 ({(output_flat > 0.5).mean()*100:.2f}%)")
```

### 바운딩 박스 좌표 확인

```python
# 바운딩 박스 좌표의 유효성 확인
valid_boxes = 0
invalid_boxes = 0

for det_idx in range(min(100, num_detections)):  # 처음 100개만 확인
    x_center = float(output_data[0, 0, det_idx])
    y_center = float(output_data[0, 1, det_idx])
    width = float(output_data[0, 2, det_idx])
    height = float(output_data[0, 3, det_idx])
    
    # 좌표가 유효한 범위인지 확인 (0~1)
    if 0 <= x_center <= 1 and 0 <= y_center <= 1 and 0 < width <= 1 and 0 < height <= 1:
        valid_boxes += 1
    else:
        invalid_boxes += 1
        if invalid_boxes <= 5:  # 처음 5개만 출력
            print(f"유효하지 않은 박스 {det_idx}: center=({x_center:.3f}, {y_center:.3f}), size=({width:.3f}, {height:.3f})")

print(f"\n유효한 박스: {valid_boxes}개")
print(f"유효하지 않은 박스: {invalid_boxes}개")
```

## ✅ 모델이 정상인지 확인 체크리스트

- [ ] 모델이 로드되고 추론이 실행됨
- [ ] 출력 형태가 `[1, 84, 8400]`임
- [ ] 출력 값에 0이 아닌 값이 있음 (모두 0이면 문제)
- [ ] 바운딩 박스 좌표가 0~1 범위 내에 있음
- [ ] 클래스 점수 중 일부가 임계값(0.25) 이상임
- [ ] 테스트 이미지에서 객체가 탐지됨 (버스 이미지에서 'bus' 탐지)

## 🐛 문제 진단

### 문제 1: 출력이 모두 0
- **원인**: 모델 변환 실패 또는 입력 전처리 문제
- **해결**: 모델을 다시 변환하거나 입력 정규화 확인

### 문제 2: 출력 형태가 다름
- **원인**: 다른 모델 형식 또는 변환 오류
- **해결**: Flutter 코드의 출력 파싱 로직 수정 필요

### 문제 3: 탐지 결과가 없음
- **원인**: 임계값이 너무 높거나 이미지에 객체가 없음
- **해결**: 임계값을 낮추거나 다른 테스트 이미지 사용

