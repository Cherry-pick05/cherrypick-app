"""
TFLite 모델 웹캠 테스트 스크립트
VS Code에서 실행하여 TFLite 파일이 올바르게 작동하는지 확인
"""

import tensorflow as tf
import numpy as np
import cv2
from PIL import Image
import os

# 설정
TFLITE_FILE = 'assets/yolov8s-worldv2_float32.tflite'  # TFLite 파일 경로
INPUT_SIZE = 640  # 모델 입력 크기
CONFIDENCE_THRESHOLD = 0.25  # 신뢰도 임계값

# COCO 클래스 이름 (80개)
COCO_CLASSES = [
    'person', 'bicycle', 'car', 'motorcycle', 'airplane', 'bus', 'train',
    'truck', 'boat', 'traffic light', 'fire hydrant', 'stop sign',
    'parking meter', 'bench', 'bird', 'cat', 'dog', 'horse', 'sheep',
    'cow', 'elephant', 'bear', 'zebra', 'giraffe', 'backpack', 'umbrella',
    'handbag', 'tie', 'suitcase', 'frisbee', 'skis', 'snowboard',
    'sports ball', 'kite', 'baseball bat', 'baseball glove', 'skateboard',
    'surfboard', 'tennis racket', 'bottle', 'wine glass', 'cup', 'fork',
    'knife', 'spoon', 'bowl', 'banana', 'apple', 'sandwich', 'orange',
    'broccoli', 'carrot', 'hot dog', 'pizza', 'donut', 'cake', 'chair',
    'couch', 'potted plant', 'bed', 'dining table', 'toilet', 'tv',
    'laptop', 'mouse', 'remote', 'keyboard', 'cell phone', 'microwave',
    'oven', 'toaster', 'sink', 'refrigerator', 'book', 'clock', 'vase',
    'scissors', 'teddy bear', 'hair drier', 'toothbrush'
]

def load_tflite_model(model_path):
    """TFLite 모델 로드"""
    if not os.path.exists(model_path):
        raise FileNotFoundError(f"모델 파일을 찾을 수 없습니다: {model_path}")
    
    print(f"📦 모델 로드 중: {model_path}")
    interpreter = tf.lite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print(f"✅ 모델 로드 완료")
    print(f"   입력 형태: {input_details[0]['shape']}")
    print(f"   입력 타입: {input_details[0]['dtype']}")
    print(f"   출력 형태: {output_details[0]['shape']}")
    print(f"   출력 타입: {output_details[0]['dtype']}")
    
    return interpreter, input_details, output_details

def preprocess_image(image, target_size):
    """이미지 전처리 (YOLO 형식)"""
    # 리사이즈
    image_resized = cv2.resize(image, (target_size, target_size))
    
    # BGR to RGB
    image_rgb = cv2.cvtColor(image_resized, cv2.COLOR_BGR2RGB)
    
    # 정규화 (0~1)
    image_normalized = image_rgb.astype(np.float32) / 255.0
    
    # 배치 차원 추가 [1, H, W, 3]
    image_batch = np.expand_dims(image_normalized, axis=0)
    
    return image_batch, image_resized

def parse_yolo_output(output_data, threshold, input_size):
    """YOLO World v2 출력 파싱"""
    # 출력 형태: [1, 84, 8400]
    # 84 = 4 (bbox) + 80 (COCO classes)
    # 8400 = detection anchor points
    
    batch, features, num_detections = output_data.shape
    
    detections = []
    
    for det_idx in range(num_detections):
        # 바운딩 박스 (정규화 좌표 0~1)
        x_center = float(output_data[0, 0, det_idx])
        y_center = float(output_data[0, 1, det_idx])
        width = float(output_data[0, 2, det_idx])
        height = float(output_data[0, 3, det_idx])
        
        # 클래스 점수 (4~83)
        class_scores = []
        for class_idx in range(80):
            score = float(output_data[0, 4 + class_idx, det_idx])
            class_scores.append(score)
        
        # 최고 점수 찾기
        max_score = max(class_scores)
        max_class_idx = class_scores.index(max_score)
        
        # 임계값 이상인 경우만 저장
        if max_score >= threshold:
            # 좌표 변환 (정규화 → 픽셀)
            x1 = int((x_center - width / 2) * input_size)
            y1 = int((y_center - height / 2) * input_size)
            x2 = int((x_center + width / 2) * input_size)
            y2 = int((y_center + height / 2) * input_size)
            
            # 좌표 범위 제한
            x1 = max(0, min(x1, input_size - 1))
            y1 = max(0, min(y1, input_size - 1))
            x2 = max(0, min(x2, input_size - 1))
            y2 = max(0, min(y2, input_size - 1))
            
            detections.append({
                'class': COCO_CLASSES[max_class_idx] if max_class_idx < len(COCO_CLASSES) else 'unknown',
                'score': max_score,
                'bbox': [x1, y1, x2, y2],
                'class_idx': max_class_idx
            })
    
    # 신뢰도 순으로 정렬
    detections.sort(key=lambda x: x['score'], reverse=True)
    
    return detections

def draw_detections(image, detections, scale_x=1.0, scale_y=1.0):
    """탐지 결과를 이미지에 그리기"""
    for det in detections:
        x1, y1, x2, y2 = det['bbox']
        
        # 원본 이미지 크기에 맞게 스케일 조정
        x1 = int(x1 * scale_x)
        y1 = int(y1 * scale_y)
        x2 = int(x2 * scale_x)
        y2 = int(y2 * scale_y)
        
        # 바운딩 박스 그리기
        cv2.rectangle(image, (x1, y1), (x2, y2), (0, 255, 0), 2)
        
        # 라벨 그리기
        label = f"{det['class']}: {det['score']:.2f}"
        label_size, _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.5, 2)
        
        # 라벨 배경
        cv2.rectangle(
            image,
            (x1, y1 - label_size[1] - 10),
            (x1 + label_size[0], y1),
            (0, 255, 0),
            -1
        )
        
        # 라벨 텍스트
        cv2.putText(
            image,
            label,
            (x1, y1 - 5),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.5,
            (0, 0, 0),
            2
        )
    
    return image

def main():
    """메인 함수"""
    print("=" * 70)
    print("🎥 TFLite 모델 웹캠 테스트")
    print("=" * 70)
    
    # 1. 모델 로드
    try:
        interpreter, input_details, output_details = load_tflite_model(TFLITE_FILE)
    except Exception as e:
        print(f"❌ 오류: {e}")
        return
    
    # 2. 웹캠 초기화
    print("\n📹 웹캠 초기화 중...")
    cap = cv2.VideoCapture(0)
    
    if not cap.isOpened():
        print("❌ 웹캠을 열 수 없습니다.")
        return
    
    print("✅ 웹캠 연결 완료")
    print("\n사용 방법:")
    print("  - 'q' 키: 종료")
    print("  - 's' 키: 스크린샷 저장")
    print("  - 'i' 키: 모델 정보 출력")
    
    frame_count = 0
    fps_start_time = cv2.getTickCount()
    
    try:
        while True:
            ret, frame = cap.read()
            if not ret:
                print("❌ 프레임을 읽을 수 없습니다.")
                break
            
            # FPS 계산
            frame_count += 1
            if frame_count % 30 == 0:
                fps_end_time = cv2.getTickCount()
                fps = 30.0 / ((fps_end_time - fps_start_time) / cv2.getTickFrequency())
                fps_start_time = fps_end_time
                print(f"FPS: {fps:.2f}")
            
            # 원본 프레임 크기 저장
            original_height, original_width = frame.shape[:2]
            
            # 이미지 전처리
            input_image, resized_image = preprocess_image(frame, INPUT_SIZE)
            
            # 추론 실행
            interpreter.set_tensor(input_details[0]['index'], input_image)
            interpreter.invoke()
            
            # 결과 가져오기
            output_data = interpreter.get_tensor(output_details[0]['index'])
            
            # 출력 파싱
            detections = parse_yolo_output(output_data, CONFIDENCE_THRESHOLD, INPUT_SIZE)
            
            # 결과를 원본 프레임에 그리기
            scale_x = original_width / INPUT_SIZE
            scale_y = original_height / INPUT_SIZE
            frame_with_detections = draw_detections(frame.copy(), detections, scale_x, scale_y)
            
            # 정보 표시
            info_text = f"Detections: {len(detections)} | Threshold: {CONFIDENCE_THRESHOLD}"
            cv2.putText(
                frame_with_detections,
                info_text,
                (10, 30),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.7,
                (255, 255, 255),
                2
            )
            
            # 상위 탐지 결과 표시
            if detections:
                top_detections = detections[:3]  # 상위 3개
                y_offset = 60
                for i, det in enumerate(top_detections):
                    text = f"{i+1}. {det['class']}: {det['score']:.2f}"
                    cv2.putText(
                        frame_with_detections,
                        text,
                        (10, y_offset + i * 25),
                        cv2.FONT_HERSHEY_SIMPLEX,
                        0.6,
                        (0, 255, 255),
                        2
                    )
            
            # 화면에 표시
            cv2.imshow('TFLite Webcam Test', frame_with_detections)
            
            # 키 입력 처리
            key = cv2.waitKey(1) & 0xFF
            if key == ord('q'):
                print("\n종료합니다...")
                break
            elif key == ord('s'):
                filename = f"screenshot_{frame_count}.jpg"
                cv2.imwrite(filename, frame_with_detections)
                print(f"📸 스크린샷 저장: {filename}")
            elif key == ord('i'):
                print("\n" + "=" * 70)
                print("모델 정보:")
                print(f"  입력 형태: {input_details[0]['shape']}")
                print(f"  출력 형태: {output_details[0]['shape']}")
                print(f"  현재 탐지 개수: {len(detections)}")
                if detections:
                    print("  상위 탐지:")
                    for i, det in enumerate(detections[:5]):
                        print(f"    {i+1}. {det['class']}: {det['score']:.4f}")
                print("=" * 70)
    
    except KeyboardInterrupt:
        print("\n\n사용자에 의해 중단되었습니다.")
    except Exception as e:
        print(f"\n❌ 오류 발생: {e}")
        import traceback
        traceback.print_exc()
    finally:
        cap.release()
        cv2.destroyAllWindows()
        print("✅ 리소스 정리 완료")

if __name__ == "__main__":
    main()

