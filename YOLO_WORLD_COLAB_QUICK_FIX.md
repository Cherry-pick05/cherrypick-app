# 🔧 Colab 오류 빠른 수정 가이드

## 문제점
Colab에서 TFLite 파일 경로가 예상과 다릅니다. 실제 생성된 파일은:
- ✅ `yolov8s-worldv2_saved_model/yolov8s-worldv2_float32.tflite`
- ❌ `yolov8s-worldv2.tflite` (이 파일은 없음)

## 즉시 해결 코드

```python
# ============================================
# 1. 모델 변환 (이미 실행했다면 스킵)
# ============================================
from ultralytics import YOLO

model = YOLO('yolov8s-worldv2.pt')
model.export(format='tflite', imgsz=640)

# ============================================
# 2. 올바른 파일 경로 찾기 및 확인
# ============================================
import os
import tensorflow as tf

# 실제 생성된 파일 경로
actual_file = 'yolov8s-worldv2_saved_model/yolov8s-worldv2_float32.tflite'

# 파일 존재 확인
if os.path.exists(actual_file):
    print(f"✅ 파일 찾음: {actual_file}")
    file_size = os.path.getsize(actual_file) / (1024 * 1024)
    print(f"   파일 크기: {file_size:.2f} MB")
    
    # ============================================
    # 3. 입출력 확인 (올바른 경로 사용)
    # ============================================
    interpreter = tf.lite.Interpreter(model_path=actual_file)
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print("\n📥 입력 정보:")
    print(f"  형태: {input_details[0]['shape']}")
    print(f"  타입: {input_details[0]['dtype']}")
    
    print("\n📤 출력 정보:")
    print(f"  형태: {output_details[0]['shape']}")
    print(f"  타입: {output_details[0]['dtype']}")
    
    # YOLO World v2 출력 형태: [1, 84, 8400]
    output_shape = output_details[0]['shape']
    if len(output_shape) == 3:
        batch, features, detections = output_shape
        print(f"\n🔬 출력 형태 분석:")
        print(f"  배치: {batch}")
        print(f"  특성: {features} (4 bbox + 80 classes = 84)")
        print(f"  탐지 앵커: {detections}")
    
    # ============================================
    # 4. 원하는 이름으로 파일 복사
    # ============================================
    import shutil
    
    target_file = 'yolo_world_ovd.tflite'
    shutil.copy(actual_file, target_file)
    print(f"\n✅ 파일 복사 완료: {target_file}")
    
    # ============================================
    # 5. 파일 다운로드
    # ============================================
    from google.colab import files
    files.download(target_file)
    print(f"✅ 다운로드 완료!")
    
else:
    print("❌ 파일을 찾을 수 없습니다!")
    print("\n생성된 모든 .tflite 파일 찾기:")
    for root, dirs, files in os.walk('.'):
        for file in files:
            if file.endswith('.tflite'):
                print(f"  📁 {os.path.join(root, file)}")
```

## 한 줄로 실행하기

```python
import os, shutil
from ultralytics import YOLO

# 모델 변환
model = YOLO('yolov8s-worldv2.pt')
model.export(format='tflite', imgsz=640)

# 파일 복사
shutil.copy('yolov8s-worldv2_saved_model/yolov8s-worldv2_float32.tflite', 'yolo_world_ovd.tflite')

# 다운로드
from google.colab import files
files.download('yolo_world_ovd.tflite')

print("✅ 완료!")
```

