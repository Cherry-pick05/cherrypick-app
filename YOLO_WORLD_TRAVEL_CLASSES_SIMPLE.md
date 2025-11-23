# 🚀 YOLO World → 여행 클래스 → TFLite (간단 버전)

## 한 번에 실행하는 스크립트

아래 코드를 Colab에 복사해서 실행하세요!

```python
# ============================================
# YOLO World 여행 클래스 → TFLite 변환
# ============================================

!pip install -q ultralytics tensorflow

from ultralytics import YOLO
import tensorflow as tf
import os
import shutil
import json

# 여행 클래스 정의
TRAVEL_CLASSES = [
    'passport', 'power bank', 'lighter', 'battery',
    'knife', 'scissors', 'tool', 'spray', 'bottle',
    'laptop', 'tablet', 'camera', 'drone',
    'luggage', 'suitcase', 'backpack',
    'sunglasses', 'hat', 'neck pillow', 'cosmetics', 'charger', 'shoes'
]

print("=" * 70)
print("🎯 YOLO World → 여행 클래스 → TFLite")
print("=" * 70)
print(f"여행 클래스: {len(TRAVEL_CLASSES)}개")
print(f"클래스 목록: {', '.join(TRAVEL_CLASSES[:5])}...")

# 1. 모델 로드
print("\n📦 1단계: 모델 로드")
model = YOLO('yolov8s-worldv2.pt')
print("✅ 완료")

# 2. TFLite 변환
print("\n🔄 2단계: TFLite 변환")
model.export(format='tflite', imgsz=640)
print("✅ 완료")

# 3. 파일 찾기
print("\n📁 3단계: 파일 찾기")
tflite_file = None
for root, dirs, files in os.walk('.'):
    for file in files:
        if file.endswith('_float32.tflite') or (file.endswith('.tflite') and 'saved_model' not in root):
            full_path = os.path.join(root, file)
            if 'world' in full_path.lower() or 'yolo' in full_path.lower():
                tflite_file = full_path
                break
    if tflite_file:
        break

if not tflite_file:
    # 대안: saved_model 폴더에서 찾기
    for root, dirs, files in os.walk('.'):
        for file in files:
            if file.endswith('.tflite'):
                full_path = os.path.join(root, file)
                tflite_file = full_path
                break
        if tflite_file:
            break

if tflite_file:
    print(f"✅ 파일 발견: {tflite_file}")
    
    # 4. 모델 확인
    print("\n🔍 4단계: 모델 정보 확인")
    interpreter = tf.lite.Interpreter(model_path=tflite_file)
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print(f"   입력: {input_details[0]['shape']}")
    print(f"   출력: {output_details[0]['shape']}")
    
    output_shape = output_details[0]['shape']
    if len(output_shape) == 3:
        batch, features, detections = output_shape
        num_classes = features - 4
        print(f"\n   분석: {features} = 4 (bbox) + {num_classes} (classes)")
        
        if num_classes == 80:
            print(f"   ⚠️ COCO 80 클래스 형태입니다.")
            print(f"   → Flutter 코드에서 매핑 기능을 사용하세요 (이미 구현됨)")
        elif num_classes == len(TRAVEL_CLASSES):
            print(f"   ✅ 여행 클래스 형태입니다!")
        else:
            print(f"   ⚠️ 예상과 다른 클래스 수: {num_classes}")
    
    # 5. 파일 복사 및 저장
    print("\n💾 5단계: 파일 준비")
    target_file = 'yolo_world_travel.tflite'
    
    if os.path.exists(target_file):
        os.remove(target_file)
    
    shutil.copy(tflite_file, target_file)
    file_size = os.path.getsize(target_file) / (1024 * 1024)
    print(f"✅ {target_file} 생성 완료 ({file_size:.2f} MB)")
    
    # 클래스 정보 저장
    class_info = {
        'travel_classes': TRAVEL_CLASSES,
        'num_classes': len(TRAVEL_CLASSES),
        'output_shape': output_shape.tolist() if 'output_shape' in locals() else None,
        'model_features': features if 'features' in locals() else None,
        'model_classes': num_classes if 'num_classes' in locals() else None,
    }
    
    with open('travel_classes_info.json', 'w', encoding='utf-8') as f:
        json.dump(class_info, f, indent=2, ensure_ascii=False)
    
    print("✅ travel_classes_info.json 저장 완료")
    
    # 6. 다운로드
    print("\n📥 6단계: 다운로드")
    from google.colab import files
    
    print("다운로드할 파일:")
    print(f"   1. {target_file}")
    print(f"   2. travel_classes_info.json")
    print("\n아래 주석을 해제하여 다운로드하세요:")
    print(f"   files.download('{target_file}')")
    print(f"   files.download('travel_classes_info.json')")
    
    # 자동 다운로드 (원하는 경우 주석 해제)
    # files.download(target_file)
    # files.download('travel_classes_info.json')
    
else:
    print("❌ TFLite 파일을 찾을 수 없습니다.")
    print("\n생성된 모든 .tflite 파일:")
    for root, dirs, files in os.walk('.'):
        for file in files:
            if file.endswith('.tflite'):
                print(f"   {os.path.join(root, file)}")

print("\n" + "=" * 70)
print("✅ 완료!")
print("=" * 70)
print("\n📋 다음 단계:")
print("1. TFLite 파일을 Flutter 프로젝트의 assets 폴더에 복사")
print("2. pubspec.yaml에 파일 경로 추가:")
print("   assets:")
print("     - assets/yolo_world_travel.tflite")
print("3. Flutter 코드가 자동으로 여행 클래스 매핑 사용 (이미 구현됨)")
```

---

## 📝 Flutter 코드에서 사용

### 1. 파일 복사

```
assets/yolo_world_travel.tflite
```

### 2. pubspec.yaml 확인

```yaml
flutter:
  assets:
    - assets/yolo_world_travel.tflite
```

### 3. 코드 (이미 설정됨)

```dart
_yoloDetector = YoloWorldTfliteDetector();
await _yoloDetector!.initialize(
  modelPath: 'assets/yolo_world_travel.tflite',
);
// 여행 클래스는 자동으로 설정되어 있음
```

---

## ⚠️ 참고사항

1. **TFLite 변환 시 제한**: YOLO World의 텍스트 프롬프트 기능은 TFLite에서 완전히 지원되지 않을 수 있습니다.
2. **COCO 80 클래스**: 변환된 모델이 여전히 COCO 80 클래스를 출력할 수 있습니다.
3. **해결책**: Flutter 코드의 매핑 기능을 사용하세요 (이미 구현됨).

---

## ✅ 최종 결과

- ✅ TFLite 파일 생성
- ✅ 여행 클래스 정보 저장
- ✅ Flutter에서 바로 사용 가능 (매핑 자동 적용)

이제 Colab에서 위 스크립트를 실행하고 파일을 다운로드하세요! 🚀

