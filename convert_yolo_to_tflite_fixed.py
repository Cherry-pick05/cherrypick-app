# -*- coding: utf-8 -*-
"""
YOLO World v2를 Flutter 호환 TFLite로 변환하는 스크립트
Flutter tflite_flutter 패키지와 호환되도록 최적화
"""

!pip install ultralytics tensorflow

from ultralytics import YOLO
import tensorflow as tf
import numpy as np
from pathlib import Path

print("=" * 70)
print("YOLO World v2 → TFLite 변환 (Flutter 호환)")
print("=" * 70)

# 1. YOLO World v2 모델 로드
print("\n1️⃣ YOLO World 모델 로드...")
model = YOLO('yolov8s-worldv2.pt')
print("✅ YOLO World 모델 로드 완료")

# 2. 여행 클래스 정의
travel_classes = [
    'passport', 'power bank', 'lighter', 'battery',  # 필수/주의
    'knife', 'scissors', 'tool', 'spray', 'bottle',  # 보안 검색 주의
    'laptop', 'tablet', 'camera', 'drone',           # 전자제품
    'luggage', 'suitcase', 'backpack',               # 가방
    'sunglasses', 'hat', 'neck pillow', 'cosmetics', 'charger', 'shoes' # 기타
]

print(f"\n2️⃣ 여행 클래스 {len(travel_classes)}개 설정")
print(f"클래스 목록: {travel_classes}")

# 3. 클래스 설정 (YOLO World v2)
try:
    if hasattr(model, 'set_classes'):
        model.set_classes(travel_classes)
        print("✅ set_classes로 클래스 설정 완료")
    elif hasattr(model, 'model') and hasattr(model.model, 'set_classes'):
        model.model.set_classes(travel_classes)
        print("✅ 모델 내부 set_classes로 클래스 설정 완료")
    else:
        print("⚠️ set_classes 메서드가 없습니다. export 시 클래스 정보 포함")
except Exception as e:
    print(f"⚠️ 클래스 설정 중 오류: {e}")

# 4. TFLite 변환 (Flutter 호환 옵션)
print("\n3️⃣ TFLite 변환 시작...")
print("   Flutter 호환 옵션 적용:")

try:
    # 방법 1: 직접 TFLite 변환 (추천)
    model.export(
        format='tflite',
        imgsz=640,              # 입력 크기: 640x640
        dynamic=False,          # 고정 크기 입력 (Flutter에서 더 안정적)
        int8=False,             # float32 사용 (정확도 유지)
        simplify=True,          # 모델 단순화
        opset=12,               # ONNX opset 버전 (TFLite 변환 시 사용)
        # keras=True,           # Keras 형식 (선택사항)
    )
    print("✅ TFLite 변환 완료 (직접 변환)")
    
except Exception as e:
    print(f"❌ 직접 TFLite 변환 실패: {e}")
    print("\n방법 2: ONNX → TFLite 2단계 변환 시도...")
    try:
        # 단계 1: ONNX로 변환
        model.export(
            format='onnx',
            imgsz=640,
            simplify=True,
            opset=12,
        )
        print("✅ ONNX 변환 완료")
        
        # 단계 2: ONNX → TFLite 변환
        import onnx
        from onnx_tf.backend import prepare
        
        onnx_model = onnx.load('yolov8s-worldv2.onnx')
        tf_rep = prepare(onnx_model)
        tf_rep.export_graph('yolov8s-worldv2_saved_model')
        
        # TensorFlow SavedModel → TFLite
        converter = tf.lite.TFLiteConverter.from_saved_model('yolov8s-worldv2_saved_model')
        converter.target_spec.supported_ops = [
            tf.lite.OpsSet.TFLITE_BUILTINS,  # TFLite 내장 연산자
            tf.lite.OpsSet.SELECT_TF_OPS     # TensorFlow 연산자 (필요시)
        ]
        converter.optimizations = []  # 최적화 비활성화 (호환성)
        
        tflite_model = converter.convert()
        
        with open('yolov8s-worldv2_fixed.tflite', 'wb') as f:
            f.write(tflite_model)
        
        print("✅ ONNX → TFLite 2단계 변환 완료")
        
    except Exception as e2:
        print(f"❌ ONNX → TFLite 변환도 실패: {e2}")
        print("\n방법 3: 기본 export 옵션으로 재시도...")
        model.export(format='tflite', imgsz=640)
        print("✅ 기본 옵션으로 TFLite 변환 완료")

# 5. 생성된 TFLite 파일 확인
print("\n4️⃣ 생성된 TFLite 파일 확인...")
import os

tflite_files = []
for root, dirs, files in os.walk('.'):
    for file in files:
        if file.endswith('.tflite'):
            full_path = os.path.join(root, file)
            size = os.path.getsize(full_path) / (1024 * 1024)
            tflite_files.append((full_path, size))
            print(f"  📁 {full_path} ({size:.2f} MB)")

# 가장 최근 생성된 파일 선택
if tflite_files:
    tflite_file = max(tflite_files, key=lambda x: os.path.getmtime(x[0]))[0]
else:
    # 기본 경로 시도
    possible_paths = [
        'yolov8s-worldv2.tflite',
        'yolov8s-worldv2_saved_model/yolov8s-worldv2_float32.tflite',
        'yolov8s-worldv2_fixed.tflite'
    ]
    tflite_file = None
    for path in possible_paths:
        if os.path.exists(path):
            tflite_file = path
            break

if not tflite_file:
    print("❌ TFLite 파일을 찾을 수 없습니다!")
else:
    print(f"\n✅ 사용할 TFLite 파일: {tflite_file}")
    
    # 6. TFLite 모델 정보 확인
    print("\n5️⃣ TFLite 모델 정보 확인...")
    interpreter = tf.lite.Interpreter(model_path=tflite_file)
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print("\n" + "=" * 70)
    print("📊 TFLite 모델 상세 정보")
    print("=" * 70)
    
    print(f"\n입력 텐서:")
    print(f"  인덱스: {input_details[0]['index']}")
    print(f"  이름: {input_details[0].get('name', 'N/A')}")
    print(f"  형태: {input_details[0]['shape']}")
    print(f"  타입: {input_details[0]['dtype']}")
    
    print(f"\n출력 텐서:")
    print(f"  인덱스: {output_details[0]['index']}")
    print(f"  이름: {output_details[0].get('name', 'N/A')}")
    print(f"  형태: {output_details[0]['shape']}")
    print(f"  타입: {output_details[0]['dtype']}")
    
    # 출력 형태 분석
    output_shape = output_details[0]['shape']
    print(f"\n📈 출력 형태 분석:")
    if len(output_shape) == 3:
        batch, features, detections = output_shape
        print(f"  형태: [batch={batch}, features={features}, detections={detections}]")
        
        expected_features_travel = 4 + len(travel_classes)  # 4 (bbox) + 24 (classes) = 28
        expected_features_coco = 4 + 80  # 4 (bbox) + 80 (classes) = 84
        
        if features == expected_features_travel:
            print(f"  ✅ 여행 클래스 형태: {features} = 4 bbox + {len(travel_classes)} classes")
        elif features == expected_features_coco:
            print(f"  ⚠️ COCO 형태: {features} = 4 bbox + 80 classes")
            print(f"  (여행 클래스 정보가 포함되지 않았을 수 있음)")
        else:
            print(f"  ⚠️ 예상과 다른 형태: {features} features")
    else:
        print(f"  ⚠️ 3차원이 아닌 형태: {output_shape}")
    
    # 7. 테스트 추론 실행
    print("\n6️⃣ 테스트 추론 실행...")
    try:
        # 더미 입력 생성 (1, 640, 640, 3)
        test_input = np.random.rand(1, 640, 640, 3).astype(np.float32)
        
        interpreter.set_tensor(input_details[0]['index'], test_input)
        interpreter.invoke()
        output_data = interpreter.get_tensor(output_details[0]['index'])
        
        print(f"✅ 추론 성공!")
        print(f"  입력 형태: {test_input.shape}")
        print(f"  출력 형태: {output_data.shape}")
        print(f"  출력 값 범위: [{np.min(output_data):.4f}, {np.max(output_data):.4f}]")
        
    except Exception as e:
        print(f"❌ 테스트 추론 실패: {e}")
        import traceback
        traceback.print_exc()
    
    # 8. 최종 파일명 지정 및 복사
    print("\n7️⃣ 최종 파일 준비...")
    final_filename = 'yolo_world_travel_flutter.tflite'
    
    import shutil
    shutil.copy(tflite_file, final_filename)
    final_size = os.path.getsize(final_filename) / (1024 * 1024)
    
    print(f"✅ 최종 파일 생성: {final_filename} ({final_size:.2f} MB)")
    print(f"\n📋 Flutter에서 사용할 파일:")
    print(f"   파일명: {final_filename}")
    print(f"   경로: assets/{final_filename}")
    print(f"\n📋 Flutter 코드에서 사용:")
    print(f"   modelPath: 'assets/{final_filename}'")
    
    print("\n" + "=" * 70)
    print("✅ 변환 완료!")
    print("=" * 70)
    print("\n다음 단계:")
    print("1. 생성된 TFLite 파일을 Flutter 프로젝트의 assets 폴더에 복사")
    print("2. pubspec.yaml에 assets 경로 추가")
    print("3. Flutter 코드에서 modelPath를 'assets/yolo_world_travel_flutter.tflite'로 변경")

