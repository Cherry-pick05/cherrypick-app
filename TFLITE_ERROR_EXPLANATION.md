# TFLite 객체 탐지 오류 진단 가이드

## 🔴 현재 오류
```
E/tflite: tensorflow/lite/kernels/pad.cc:79 
SizeOfDimension(op_context->paddings, 0) != op_context->dims (4 != 2)
```

## 🔍 오류 원인 분석

### 1. 오류의 의미
- TFLite 모델 내부의 `PAD` 연산이 예상하는 입력 차원과 실제 입력 차원이 다릅니다
- 오류 메시지: `4 != 2` → PAD 연산은 2차원을 기대했지만 4차원을 받았습니다
- 이전 오류: `4 != 5` → 같은 원인으로 차원 불일치

### 2. 가능한 원인
1. **입력 텐서 형태 불일치**
   - Flutter에서 전달하는 입력 데이터의 형태가 모델이 기대하는 형태와 다를 수 있음
   - 예: `[1, 640, 640, 3]` (4차원) vs 모델이 내부적으로 기대하는 다른 형태

2. **입력 데이터 전달 방식 문제**
   - `tflite_flutter`의 `Interpreter.run()`이 입력을 어떻게 처리하는지
   - Python: `interpreter.set_tensor(index, numpy_array)`
   - Flutter: `interpreter.run([Float32List], outputs)`

3. **모델 메타데이터 문제**
   - TFLite 모델 변환 과정에서 입력 형태가 잘못 지정되었을 수 있음
   - 모델 내부 그래프 구조와 입력 텐서 정의가 불일치할 수 있음

### 3. Python vs Flutter 차이점

#### Python (정상 작동)
```python
# 1. NumPy 배열 생성 [1, 640, 640, 3]
input_image = np.expand_dims(image_normalized, axis=0)

# 2. 텐서 인덱스에 직접 설정
interpreter.set_tensor(input_details[0]['index'], input_image)

# 3. 추론 실행
interpreter.invoke()

# 4. 출력 가져오기
output = interpreter.get_tensor(output_details[0]['index'])
```

#### Flutter (현재 코드)
```dart
// 1. Float32List로 평탄화 [1 * 640 * 640 * 3 = 1,228,800]
Float32List inputTensor = Float32List(1 * 640 * 640 * 3);

// 2. run() 메서드에 전달
_interpreter!.run([inputTensor], outputs);
```

### 4. 문제점 추정
- `tflite_flutter`의 `Interpreter.run()`은 입력을 리스트의 리스트로 받습니다: `List<dynamic> inputs`
- 내부적으로 입력을 재구성하는 과정에서 차원 해석 오류가 발생할 수 있습니다
- Python의 `set_tensor()`는 명시적으로 텐서 인덱스와 형태를 지정하지만, Flutter는 추론에 의존합니다

## 📋 디버깅 방법

### 1단계: Python에서 상세 로그 확인
`test_tflite_debug.py` 스크립트를 실행하여 다음을 확인하세요:

```bash
python test_tflite_debug.py
```

확인할 정보:
- ✅ 입력 텐서 shape: `[1, 640, 640, 3]`
- ✅ 입력 텐서 dtype: `float32`
- ✅ 출력 텐서 shape: `[1, 84, 8400]` 또는 다른 형태
- ✅ 입력 데이터의 실제 값 (첫 10개 픽셀)
- ✅ 메모리 레이아웃 (C-contiguous 여부)

### 2단계: Flutter 로그와 비교
Flutter 앱 실행 시 다음 로그를 확인하세요:

```
📊 입력 텐서 타입: TensorType.float32
📊 입력 텐서 형태: [1, 640, 640, 3]
📸 RGB 바이트 직접 전처리: ...
📊 입력 텐서 생성 완료: ...
```

### 3단계: 비교 포인트
| 항목 | Python | Flutter | 일치 여부 |
|------|--------|---------|----------|
| 입력 shape | `[1, 640, 640, 3]` | `[1, 640, 640, 3]` | ✅ 확인 필요 |
| 입력 dtype | `float32` | `float32` | ✅ 확인 필요 |
| 데이터 범위 | `[0.0, 1.0]` | `[0.0, 1.0]` | ✅ 확인 필요 |
| 메모리 레이아웃 | C-contiguous | ? | ⚠️ 확인 필요 |

## 🔧 가능한 해결 방법

### 방법 1: 입력 텐서를 중첩 리스트로 전달 (현재 시도 중)
```dart
// 4차원 리스트로 구성
List<List<List<List<double>>>> input4D = List.generate(
  1, (b) => List.generate(640, (h) => 
    List.generate(640, (w) => 
      List.generate(3, (c) => pixelValue)
    )
  )
);
_interpreter!.run([input4D], outputs);
```

### 방법 2: 입력 텐서를 올바르게 재구성
`tflite_flutter`가 평탄화된 배열을 자동으로 재구성하도록 하는 대신,
명시적으로 4차원 리스트로 만들어 전달

### 방법 3: 다른 TFLite 라이브러리 사용 검토
- `tflite_flutter_helper` 패키지의 유틸리티 사용
- 또는 다른 TFLite Flutter 바인딩 라이브러리 검토

## 📊 다음 단계

1. **Python 디버깅 스크립트 실행**
   ```bash
   python test_tflite_debug.py > python_debug_output.txt
   ```

2. **Flutter 로그 수집**
   - 앱 실행 시 모든 디버그 로그를 파일로 저장

3. **결과 비교**
   - Python의 입력 텐서 형태와 값
   - Flutter의 입력 텐서 형태와 값
   - JSON 파일 (`tflite_debug_output.json`)의 샘플 값들

4. **코드 수정**
   - 비교 결과를 바탕으로 Flutter 코드의 입력 데이터 준비 방식을 수정

## 💡 추가 확인 사항

- [ ] TFLite 모델 파일이 Python과 Flutter에서 동일한지 확인 (파일 해시 비교)
- [ ] `tflite_flutter` 패키지 버전 확인 (최신 버전 사용)
- [ ] Android/iOS 네이티브 TFLite 라이브러리 버전 확인
- [ ] 모델 변환 시 사용한 옵션 확인 (동적 배치, 양자화 등)

