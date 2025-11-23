# TFLite 입력 텐서 문제 해결

## 문제

오류 메시지:
```
E/tflite: tensorflow/lite/kernels/pad.cc:79 SizeOfDimension(op_context->paddings, 0) != op_context->dims (4 != 5)
```

모델의 첫 번째 노드(PAD)가 5차원 텐서를 기대하는데 4차원을 받고 있습니다.

## 원인

Python에서는 `interpreter.set_tensor()`와 `interpreter.invoke()`를 사용하지만,
Flutter의 `tflite_flutter`는 `interpreter.run([input], outputs)` 형식만 지원합니다.

## 해결 방법

`Float32List`를 평탄화된 형태로 전달해야 합니다. Python의 numpy array처럼
`[1, H, W, 3]` 형태가 평탄화되어 `1 * H * W * 3` 개의 값으로 전달됩니다.

현재 코드는 이미 `Float32List`로 평탄화되어 있으므로, 이를 올바르게 전달하면 됩니다.

