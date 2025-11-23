"""
TFLite 모델 상세 디버깅 스크립트
입력/출력 텐서 정보와 샘플 데이터를 출력하여 Flutter와 비교
"""

import tensorflow as tf
import numpy as np
import cv2
import os
import json

# 설정
TFLITE_FILE = 'assets/yolov8s-worldv2_float32.tflite'  # TFLite 파일 경로
INPUT_SIZE = 640  # 모델 입력 크기

def print_section(title):
    """섹션 헤더 출력"""
    print("\n" + "=" * 80)
    print(f"  {title}")
    print("=" * 80)

def print_tensor_details(details, name="텐서"):
    """텐서 상세 정보 출력"""
    print(f"\n[{name}]")
    print(f"  인덱스: {details['index']}")
    print(f"  이름: {details.get('name', 'N/A')}")
    print(f"  형태 (shape): {details['shape']}")
    print(f"  데이터 타입 (dtype): {details['dtype']}")
    print(f"  바이트 크기: {details['shape']} = {np.prod(details['shape']) * np.dtype(details['dtype']).itemsize} bytes")
    
    # 양자화 정보
    if 'quantization' in details and details['quantization']:
        quant_params = details['quantization']
        print(f"  양자화:")
        print(f"    스케일: {quant_params[0]}")
        print(f"    제로 포인트: {quant_params[1]}")
    else:
        print(f"  양자화: 없음 (float32)")
    
    # 스케일링 정보 (일부 모델)
    if 'quantization_parameters' in details:
        qp = details['quantization_parameters']
        print(f"  양자화 파라미터:")
        print(f"    스케일: {qp.get('scales', [])}")
        print(f"    제로 포인트: {qp.get('zero_points', [])}")

def analyze_input_data(input_data, input_details):
    """입력 데이터 분석"""
    print_section("입력 데이터 분석")
    
    print(f"\n입력 데이터 타입: {type(input_data)}")
    print(f"입력 데이터 형태: {input_data.shape}")
    print(f"입력 데이터 dtype: {input_data.dtype}")
    print(f"입력 데이터 크기: {input_data.size} elements")
    print(f"입력 데이터 메모리 사용량: {input_data.nbytes} bytes")
    
    print(f"\n입력 데이터 통계:")
    print(f"  최소값: {np.min(input_data):.6f}")
    print(f"  최대값: {np.max(input_data):.6f}")
    print(f"  평균값: {np.mean(input_data):.6f}")
    print(f"  표준편차: {np.std(input_data):.6f}")
    
    # 첫 번째 픽셀의 RGB 값
    print(f"\n첫 번째 픽셀 (0,0) RGB 값:")
    print(f"  R: {input_data[0, 0, 0, 0]:.6f}")
    print(f"  G: {input_data[0, 0, 0, 1]:.6f}")
    print(f"  B: {input_data[0, 0, 0, 2]:.6f}")
    
    # 중앙 픽셀의 RGB 값
    h, w = input_data.shape[1:3]
    print(f"\n중앙 픽셀 ({h//2},{w//2}) RGB 값:")
    print(f"  R: {input_data[0, h//2, w//2, 0]:.6f}")
    print(f"  G: {input_data[0, h//2, w//2, 1]:.6f}")
    print(f"  B: {input_data[0, h//2, w//2, 2]:.6f}")
    
    # 마지막 픽셀의 RGB 값
    print(f"\n마지막 픽셀 ({h-1},{w-1}) RGB 값:")
    print(f"  R: {input_data[0, h-1, w-1, 0]:.6f}")
    print(f"  G: {input_data[0, h-1, w-1, 1]:.6f}")
    print(f"  B: {input_data[0, h-1, w-1, 2]:.6f}")
    
    # Flutter와 비교하기 위한 평탄화된 형태 정보
    flattened = input_data.flatten()
    print(f"\n평탄화된 형태 (Flutter Float32List와 비교용):")
    print(f"  크기: {flattened.size} elements")
    print(f"  첫 10개 값: {flattened[:10]}")
    print(f"  마지막 10개 값: {flattened[-10:]}")
    
    # 메모리 레이아웃 확인 (C-contiguous vs Fortran-contiguous)
    print(f"\n메모리 레이아웃:")
    print(f"  C-contiguous (row-major): {input_data.flags['C_CONTIGUOUS']}")
    print(f"  Fortran-contiguous (column-major): {input_data.flags['F_CONTIGUOUS']}")
    print(f"  Writeable: {input_data.flags['WRITEABLE']}")

def analyze_output_data(output_data, output_details):
    """출력 데이터 분석"""
    print_section("출력 데이터 분석")
    
    print(f"\n출력 데이터 타입: {type(output_data)}")
    print(f"출력 데이터 형태: {output_data.shape}")
    print(f"출력 데이터 dtype: {output_data.dtype}")
    print(f"출력 데이터 크기: {output_data.size} elements")
    print(f"출력 데이터 메모리 사용량: {output_data.nbytes} bytes")
    
    print(f"\n출력 데이터 통계:")
    print(f"  최소값: {np.min(output_data):.6f}")
    print(f"  최대값: {np.max(output_data):.6f}")
    print(f"  평균값: {np.mean(output_data):.6f}")
    print(f"  표준편차: {np.std(output_data):.6f}")
    
    # 출력 형태가 [1, 84, 8400]인 경우
    if len(output_data.shape) == 3:
        batch, features, detections = output_data.shape
        print(f"\n출력 구조 분석:")
        print(f"  배치 크기: {batch}")
        print(f"  특징 차원: {features} (4 bbox + 80 classes)")
        print(f"  탐지 후보 개수: {detections}")
        
        # 첫 번째 탐지 후보의 바운딩 박스와 점수
        print(f"\n첫 번째 탐지 후보 (detection 0):")
        print(f"  x_center: {output_data[0, 0, 0]:.6f}")
        print(f"  y_center: {output_data[0, 1, 0]:.6f}")
        print(f"  width: {output_data[0, 2, 0]:.6f}")
        print(f"  height: {output_data[0, 3, 0]:.6f}")
        
        # 첫 번째 탐지 후보의 클래스 점수 (상위 5개)
        class_scores = output_data[0, 4:, 0]
        top_5_indices = np.argsort(class_scores)[::-1][:5]
        print(f"\n  상위 5개 클래스 점수:")
        for i, idx in enumerate(top_5_indices):
            print(f"    Class {idx}: {class_scores[idx]:.6f}")
    
    # 평탄화된 형태 정보
    flattened = output_data.flatten()
    print(f"\n평탄화된 형태 (Flutter와 비교용):")
    print(f"  크기: {flattened.size} elements")
    print(f"  첫 20개 값: {flattened[:20]}")
    
    # 메모리 레이아웃
    print(f"\n메모리 레이아웃:")
    print(f"  C-contiguous: {output_data.flags['C_CONTIGUOUS']}")
    print(f"  Fortran-contiguous: {output_data.flags['F_CONTIGUOUS']}")

def print_interpreter_info(interpreter):
    """Interpreter 정보 출력"""
    print_section("TFLite Interpreter 정보")
    
    try:
        # 입력/출력 텐서 개수
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        print(f"\n입력 텐서 개수: {len(input_details)}")
        print(f"출력 텐서 개수: {len(output_details)}")
        
        # 각 입력 텐서 상세 정보
        for i, input_detail in enumerate(input_details):
            print_tensor_details(input_detail, f"입력 텐서 {i}")
        
        # 각 출력 텐서 상세 정보
        for i, output_detail in enumerate(output_details):
            print_tensor_details(output_detail, f"출력 텐서 {i}")
            
    except Exception as e:
        print(f"⚠️ Interpreter 정보 가져오기 오류: {e}")

def test_inference():
    """추론 테스트 및 디버깅"""
    print_section("TFLite 모델 상세 디버깅")
    
    # 1. 모델 파일 확인
    if not os.path.exists(TFLITE_FILE):
        print(f"❌ 모델 파일을 찾을 수 없습니다: {TFLITE_FILE}")
        print(f"   현재 작업 디렉토리: {os.getcwd()}")
        return
    
    print(f"✅ 모델 파일 찾음: {TFLITE_FILE}")
    print(f"   파일 크기: {os.path.getsize(TFLITE_FILE) / (1024*1024):.2f} MB")
    
    # 2. 모델 로드
    try:
        print("\n📦 모델 로드 중...")
        interpreter = tf.lite.Interpreter(model_path=TFLITE_FILE)
        interpreter.allocate_tensors()
        print("✅ 모델 로드 완료")
    except Exception as e:
        print(f"❌ 모델 로드 오류: {e}")
        import traceback
        traceback.print_exc()
        return
    
    # 3. Interpreter 정보 출력
    print_interpreter_info(interpreter)
    
    # 4. 입력/출력 텐서 정보 가져오기
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    input_shape = input_details[0]['shape']
    input_dtype = input_details[0]['dtype']
    output_shape = output_details[0]['shape']
    output_dtype = output_details[0]['dtype']
    
    print_section("텐서 정보 요약")
    print(f"\n입력 텐서:")
    print(f"  Shape: {input_shape}")
    print(f"  Dtype: {input_dtype}")
    print(f"  예상 요소 개수: {np.prod(input_shape)}")
    
    print(f"\n출력 텐서:")
    print(f"  Shape: {output_shape}")
    print(f"  Dtype: {output_dtype}")
    print(f"  예상 요소 개수: {np.prod(output_shape)}")
    
    # 5. 테스트 이미지 생성 (더미 데이터)
    print_section("테스트 데이터 생성")
    
    # 더미 이미지 생성 (640x640 RGB)
    test_image = np.random.randint(0, 255, (640, 640, 3), dtype=np.uint8)
    print(f"테스트 이미지 생성: {test_image.shape}")
    
    # 이미지 전처리 (Python 스크립트와 동일)
    image_resized = cv2.resize(test_image, (INPUT_SIZE, INPUT_SIZE))
    image_rgb = cv2.cvtColor(image_resized, cv2.COLOR_BGR2RGB)
    image_normalized = image_rgb.astype(np.float32) / 255.0
    image_batch = np.expand_dims(image_normalized, axis=0)
    
    print(f"전처리 후 형태: {image_batch.shape}")
    print(f"전처리 후 dtype: {image_batch.dtype}")
    
    # 6. 입력 데이터 분석
    analyze_input_data(image_batch, input_details[0])
    
    # 7. 추론 실행
    print_section("추론 실행")
    
    try:
        print("\n🚀 추론 시작...")
        interpreter.set_tensor(input_details[0]['index'], image_batch)
        interpreter.invoke()
        print("✅ 추론 완료")
    except Exception as e:
        print(f"❌ 추론 오류: {e}")
        import traceback
        traceback.print_exc()
        return
    
    # 8. 출력 데이터 가져오기 및 분석
    output_data = interpreter.get_tensor(output_details[0]['index'])
    analyze_output_data(output_data, output_details[0])
    
    # 9. Flutter와 비교하기 위한 JSON 출력
    print_section("Flutter 비교용 JSON 출력")
    
    comparison_data = {
        "input": {
            "shape": input_shape.tolist(),
            "dtype": str(input_dtype),
            "size": int(np.prod(input_shape)),
            "sample_values": image_batch.flatten()[:100].tolist(),  # 첫 100개 값
            "statistics": {
                "min": float(np.min(image_batch)),
                "max": float(np.max(image_batch)),
                "mean": float(np.mean(image_batch)),
                "std": float(np.std(image_batch))
            }
        },
        "output": {
            "shape": output_shape.tolist(),
            "dtype": str(output_dtype),
            "size": int(np.prod(output_shape)),
            "sample_values": output_data.flatten()[:100].tolist(),  # 첫 100개 값
            "statistics": {
                "min": float(np.min(output_data)),
                "max": float(np.max(output_data)),
                "mean": float(np.mean(output_data)),
                "std": float(np.std(output_data))
            }
        }
    }
    
    print("\nJSON 형식 (Flutter 코드에서 확인용):")
    print(json.dumps(comparison_data, indent=2))
    
    # JSON 파일로 저장
    json_file = "tflite_debug_output.json"
    with open(json_file, 'w') as f:
        json.dump(comparison_data, f, indent=2)
    print(f"\n✅ 비교 데이터를 '{json_file}' 파일로 저장했습니다.")
    
    print_section("디버깅 완료")
    print("\n다음 단계:")
    print("1. 위 출력의 '입력 텐서' 정보를 Flutter 코드의 로그와 비교하세요.")
    print("2. '입력 데이터 분석' 섹션의 형태와 값을 Flutter의 Float32List와 비교하세요.")
    print("3. '출력 데이터 분석' 섹션의 형태를 Flutter의 출력 파싱 로직과 비교하세요.")
    print("4. JSON 파일의 샘플 값들을 Flutter에서 동일한 입력으로 추론한 결과와 비교하세요.")

def main():
    """메인 함수"""
    try:
        test_inference()
    except KeyboardInterrupt:
        print("\n\n사용자에 의해 중단되었습니다.")
    except Exception as e:
        print(f"\n❌ 오류 발생: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()

