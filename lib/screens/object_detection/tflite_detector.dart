import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math' as math;
import 'package:camera/camera.dart';

/// TFLite 모델을 사용한 객체 탐지 클래스
class TfliteDetector {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  List<int>? _inputShape;
  int? _inputWidth;
  int? _inputHeight;
  List<List<int>>? _outputShapes;

  /// 모델 초기화
  Future<void> initialize({
    String modelPath = 'assets/best_float32.tflite',
  }) async {
    if (_isInitialized) return;

    try {
      // Assets에서 모델 파일 로드
      final ByteData modelData = await rootBundle.load(modelPath);
      final Uint8List modelBytes = modelData.buffer.asUint8List();

      // 임시 파일로 저장 (TFLite는 파일에서 로드해야 함)
      final tempDir = await getTemporaryDirectory();
      final modelFile = File('${tempDir.path}/${modelPath.split('/').last}');
      await modelFile.writeAsBytes(modelBytes);

      // TFLite Interpreter 생성
      _interpreter = Interpreter.fromFile(modelFile);
      
      // 텐서 할당 (명시적으로 호출)
      _interpreter!.allocateTensors();
      
      // 입력 텐서 정보 가져오기
      final inputTensorInfo = _interpreter!.getInputTensor(0);
      debugPrint('📊 입력 텐서 타입: ${inputTensorInfo.type}');
      debugPrint('📊 입력 텐서 형태: ${inputTensorInfo.shape}');
      _inputShape = inputTensorInfo.shape;

      // 입력 텐서 형태가 [batch, height, width, channels] 또는 [batch, channels, height, width]일 수 있음
      if (_inputShape != null && _inputShape!.length >= 4) {
        // [batch, height, width, channels] 형태인 경우
        if (_inputShape![1] == _inputShape![2] || _inputShape![1] == 3 || _inputShape![2] == 3) {
          _inputHeight = _inputShape![1];
          _inputWidth = _inputShape![2];
        } else {
          // [batch, channels, height, width] 형태인 경우
          _inputHeight = _inputShape![2];
          _inputWidth = _inputShape![3];
        }
      } else {
        // 기본값 설정
        _inputHeight = 640;
        _inputWidth = 640;
      }

      // 출력 텐서 정보 가져오기
      final outputTensors = _interpreter!.getOutputTensors();
      _outputShapes = outputTensors.map((t) => t.shape).toList();

      debugPrint('✅ TFLite 모델 초기화 완료');
      debugPrint('   입력 크기: ${_inputWidth}x${_inputHeight}');
      debugPrint('   출력 텐서 개수: ${_outputShapes!.length}');
      debugPrint('   출력 형태: $_outputShapes');

      _isInitialized = true;
    } catch (e, stackTrace) {
      debugPrint('❌ TFLite 모델 초기화 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// Uint8List 이미지에서 객체 탐지
  Future<List<Map<String, dynamic>>> detectFromImageBytes(
    Uint8List imageBytes, {
    double threshold = 0.25,
    int maxDetections = 10,
  }) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('모델이 초기화되지 않았습니다. initialize()를 먼저 호출하세요.');
    }

    try {
      // 이미지 디코딩
      final inputImage = img.decodeImage(imageBytes);
      if (inputImage == null) {
        debugPrint('❌ 이미지 디코딩 실패');
        return [];
      }

      // 이미지 전처리
      final inputTensorFlat = _preprocessImage(inputImage);

      // 출력 텐서 준비
      final outputs = _prepareOutputs();

      debugPrint('🚀 TFLite 추론 시작...');
      debugPrint('📊 입력 텐서 형태: [${_inputShape![0]}, ${_inputShape![1]}, ${_inputShape![2]}, ${_inputShape![3]}]');
      debugPrint('📊 입력 텐서 데이터 크기: ${inputTensorFlat.length}');
      
      // 평탄화된 리스트를 그대로 전달 (tflite_flutter가 자동으로 형태 추론)
      final inputList = inputTensorFlat.map((e) => e.toDouble()).toList();
      _interpreter!.run([inputList], outputs);
      debugPrint('✅ TFLite 추론 완료');

      // 결과 파싱
      final detections = _parseOutput(outputs, threshold, maxDetections);

      return detections;
    } catch (e, stackTrace) {
      debugPrint('❌ 객체 탐지 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
      return [];
    }
  }

  /// CameraImage에서 객체 탐지
  Future<List<Map<String, dynamic>>> detectFromCameraImage(
    CameraImage cameraImage, {
    double threshold = 0.25,
    int maxDetections = 10,
  }) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('모델이 초기화되지 않았습니다.');
    }

    try {
      // CameraImage를 RGB Uint8List로 변환
      final rgbBytes = _cameraImageToBytes(cameraImage);
      if (rgbBytes == null) {
        debugPrint('❌ 카메라 이미지 변환 실패');
        return [];
      }

      debugPrint('📸 카메라 이미지 처리 시작: ${cameraImage.width}x${cameraImage.height}, RGB ${rgbBytes.length} bytes');
      
      // RGB 바이트를 직접 전처리 (이미지 객체로 변환하지 않고)
      final inputTensorFlat = _preprocessRGBBytesDirect(rgbBytes, cameraImage.width, cameraImage.height);

      // 출력 텐서 준비
      final outputs = _prepareOutputs();

      debugPrint('🚀 TFLite 추론 시작...');
      debugPrint('📊 입력 텐서 형태: [${_inputShape![0]}, ${_inputShape![1]}, ${_inputShape![2]}, ${_inputShape![3]}]');
      debugPrint('📊 입력 텐서 데이터 크기: ${inputTensorFlat.length} (예상: ${_inputShape![0] * _inputShape![1] * _inputShape![2] * _inputShape![3]})');
      
      // Python과 유사하게 입력 텐서 버퍼에 직접 복사 후 invoke 사용
      try {
        final inputTensor = _interpreter!.getInputTensor(0);
        final inputBuffer = inputTensor.data;
        // TypedData를 Float32List로 변환
        final inputFloat32 = Float32List.view(inputBuffer.buffer, inputBuffer.offsetInBytes, inputTensorFlat.length);
        inputFloat32.setRange(0, inputTensorFlat.length, inputTensorFlat);
        _interpreter!.invoke();
        debugPrint('✅ TFLite 추론 완료 (invoke 방식)');
        // 출력 가져오기
        final outputTensor = _interpreter!.getOutputTensor(0);
        final outputBuffer = outputTensor.data;
        final outputSize = outputTensor.shape.reduce((a, b) => a * b);
        final outputFloat32 = Float32List.view(outputBuffer.buffer, outputBuffer.offsetInBytes, outputSize);
        outputs[0] = outputFloat32.toList();
      } catch (e, stackTrace) {
        debugPrint('⚠️ invoke 방식 실패, run() 메서드 사용: $e');
        debugPrint('스택 트레이스: $stackTrace');
        // invoke가 실패하면 run() 메서드 사용
        final inputList = inputTensorFlat.map((e) => e.toDouble()).toList();
        _interpreter!.run([inputList], outputs);
        debugPrint('✅ TFLite 추론 완료 (run 방식)');
      }

      // 결과 파싱
      final detections = _parseOutput(outputs, threshold, maxDetections);

      // 바운딩 박스 좌표를 원본 카메라 이미지 크기에 맞게 스케일링
      final scaleX = cameraImage.width / _inputWidth!;
      final scaleY = cameraImage.height / _inputHeight!;

      for (var det in detections) {
        final bbox = det['bbox'] as List<double>;
        det['bbox'] = [
          bbox[0] * scaleX,
          bbox[1] * scaleY,
          bbox[2] * scaleX,
          bbox[3] * scaleY,
        ];
      }

      return detections;
    } catch (e, stackTrace) {
      debugPrint('❌ 카메라 이미지 탐지 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
      return [];
    }
  }

  /// RGB 바이트를 직접 전처리 (카메라 이미지용, 성능 최적화)
  Float32List _preprocessRGBBytesDirect(Uint8List rgbBytes, int originalWidth, int originalHeight) {
    final batch = _inputShape![0];
    final targetHeight = _inputHeight!;
    final targetWidth = _inputWidth!;
    final channels = 3;

    // Python과 동일하게 1차원 Float32List로 만들기 (NHWC 순서로 평탄화)
    final inputSize = batch * targetHeight * targetWidth * channels;
    final input = Float32List(inputSize);
    
    // 성능 최적화: 스케일 팩터 미리 계산
    final scaleX = originalWidth / targetWidth;
    final scaleY = originalHeight / targetHeight;
    final inv255 = 1.0 / 255.0; // 나눗셈 최소화
    
    int index = 0;
    for (int h = 0; h < targetHeight; h++) {
      final srcY = (h * scaleY).round().clamp(0, originalHeight - 1);
      final yOffset = srcY * originalWidth * 3;
      
      for (int w = 0; w < targetWidth; w++) {
        final srcX = (w * scaleX).round().clamp(0, originalWidth - 1);
        final pixelIndex = yOffset + srcX * 3;
        
        if (pixelIndex + 2 < rgbBytes.length) {
          input[index++] = rgbBytes[pixelIndex] * inv255;      // R
          input[index++] = rgbBytes[pixelIndex + 1] * inv255;  // G
          input[index++] = rgbBytes[pixelIndex + 2] * inv255;  // B
        } else {
          index += 3; // 0.0으로 채워짐
        }
      }
    }

    return input;
  }

  /// 이미지 전처리 (파일 이미지용)
  Float32List _preprocessImage(img.Image image) {
    // 이미지 리사이즈
    final resizedImage = img.copyResize(
      image,
      width: _inputWidth!,
      height: _inputHeight!,
    );

    debugPrint('📸 이미지 전처리: ${image.width}x${image.height} -> ${resizedImage.width}x${resizedImage.height}');
    debugPrint('📊 입력 텐서 형태: $_inputShape');

    // 입력 텐서 형태에 맞게 데이터 준비
    final batch = _inputShape![0];
    final height = _inputHeight!;
    final width = _inputWidth!;
    final channels = _inputShape!.length >= 4 ? _inputShape![3] : 3;

    // Python과 동일하게 1차원 Float32List로 만들기 (NHWC 순서로 평탄화)
    final inputSize = batch * height * width * channels;
    final input = Float32List(inputSize);
    
    int index = 0;
    for (int b = 0; b < batch; b++) {
      for (int h = 0; h < height; h++) {
        for (int w = 0; w < width; w++) {
          final pixel = resizedImage.getPixel(w, h);
          // RGB 정규화 (0.0 ~ 1.0), NHWC 순서
          input[index++] = pixel.r / 255.0;
          input[index++] = pixel.g / 255.0;
          input[index++] = pixel.b / 255.0;
        }
      }
    }

    debugPrint('📊 입력 텐서 생성 완료: ${input.length}개 값 (${batch}x${height}x${width}x${channels})');

    return input;
  }

  /// 출력 텐서 준비
  List<dynamic> _prepareOutputs() {
    final outputs = <dynamic>[];

    for (final shape in _outputShapes!) {
      final size = shape.reduce((a, b) => a * b);
      outputs.add(List.filled(size, 0.0));
    }

    return outputs;
  }

  /// 출력 파싱 (동적 형태 지원: [batch, features, detections] 또는 [batch, detections, features])
  List<Map<String, dynamic>> _parseOutput(
    List<dynamic> outputs,
    double threshold,
    int maxDetections,
  ) {
    if (outputs.isEmpty) return [];

    final output = outputs[0] as List;
    
    // 출력 형태 확인
    final outputShape = _outputShapes![0];
    debugPrint('📊 출력 형태: $outputShape');

    // 동적으로 형태 감지
    int numDetections = 8400;
    int features = 26; // 기본값은 실제 모델에 맞게 조정됨
    bool isFeatureFirst = true; // [batch, features, detections] 형태인지

    if (outputShape.length == 3) {
      final batch = outputShape[0];
      final dim1 = outputShape[1];
      final dim2 = outputShape[2];
      
      // Python 결과에 따르면 [1, 26, 8400] 형태
      // [batch, features, detections] 또는 [batch, detections, features] 형태 자동 감지
      if (dim2 == 8400) {
        // [batch, features, 8400] 형태
        numDetections = dim2;
        features = dim1;
        isFeatureFirst = true;
        debugPrint('📊 형태 감지: [batch=$batch, features=$features, detections=$numDetections]');
      } else if (dim1 == 8400) {
        // [batch, 8400, features] 형태
        numDetections = dim1;
        features = dim2;
        isFeatureFirst = false;
        debugPrint('📊 형태 감지: [batch=$batch, detections=$numDetections, features=$features]');
      } else {
        // 기본값 사용하되 경고
        debugPrint('⚠️ 알 수 없는 출력 형태. 기본값 사용: features=$features, detections=$numDetections');
      }
    } else {
      debugPrint('⚠️ 예상하지 못한 출력 차원: ${outputShape.length}');
    }

    debugPrint('📊 탐지 후보 개수: $numDetections, 특징 차원: $features (4 bbox + ${features - 4} classes)');
    debugPrint('📊 출력 배열 크기: ${output.length} (예상: ${outputShape.reduce((a, b) => a * b)})');

    // 출력 값 샘플 확인
    if (output.length > 100) {
      debugPrint('📊 출력 첫 10개 값: ${output.take(10).map((v) => v.toStringAsFixed(4)).join(", ")}');
    }

    final detections = <Map<String, dynamic>>[];

    for (int i = 0; i < numDetections; i++) {
      double cx, cy, w, h;
      double maxScore = 0.0;
      int bestClass = 0;

      try {
        if (isFeatureFirst) {
          // [batch, features, detections] 형태: output[0, feature, detection]
          // 평탄화된 배열 인덱스: batch * features * numDetections + feature * numDetections + detection
          final baseOffset = 0 * features * numDetections; // batch = 0
          
          // 바운딩 박스 읽기 (feature 0~3)
          if (baseOffset + 3 * numDetections + i < output.length) {
            cx = output[baseOffset + 0 * numDetections + i].toDouble();
            cy = output[baseOffset + 1 * numDetections + i].toDouble();
            w = output[baseOffset + 2 * numDetections + i].toDouble();
            h = output[baseOffset + 3 * numDetections + i].toDouble();

            // 클래스 점수 찾기 (feature 4 ~ features-1)
            for (int j = 4; j < features; j++) {
              final idx = baseOffset + j * numDetections + i;
              if (idx < output.length) {
                final score = output[idx].toDouble();
                if (score > maxScore) {
                  maxScore = score;
                  bestClass = j - 4; // 클래스 인덱스는 0부터 시작
                }
              }
            }
          } else {
            continue; // 인덱스 범위 초과
          }
        } else {
          // [batch, detections, features] 형태: output[0, detection, feature]
          // 평탄화된 배열 인덱스: batch * numDetections * features + detection * features + feature
          final baseOffset = 0 * numDetections * features; // batch = 0
          final detOffset = baseOffset + i * features;
          
          if (detOffset + 3 < output.length) {
            cx = output[detOffset + 0].toDouble();
            cy = output[detOffset + 1].toDouble();
            w = output[detOffset + 2].toDouble();
            h = output[detOffset + 3].toDouble();

            // 클래스 점수 찾기 (feature 4 ~ features-1)
            for (int j = 4; j < features; j++) {
              final idx = detOffset + j;
              if (idx < output.length) {
                final score = output[idx].toDouble();
                if (score > maxScore) {
                  maxScore = score;
                  bestClass = j - 4; // 클래스 인덱스는 0부터 시작
                }
              }
            }
          } else {
            continue; // 인덱스 범위 초과
          }
        }
      } catch (e) {
        debugPrint('❌ 탐지 파싱 오류 (detection $i): $e');
        continue;
      }

      // 신뢰도가 임계값 이상인 경우만 추가
      if (maxScore >= threshold) {
        // 중심 좌표를 좌상단/우하단 좌표로 변환
        // bbox 좌표는 정규화된 값(0~1)이므로 픽셀 좌표로 변환
        final x1 = ((cx - w / 2) * _inputWidth!).clamp(0.0, _inputWidth!.toDouble());
        final y1 = ((cy - h / 2) * _inputHeight!).clamp(0.0, _inputHeight!.toDouble());
        final x2 = ((cx + w / 2) * _inputWidth!).clamp(0.0, _inputWidth!.toDouble());
        final y2 = ((cy + h / 2) * _inputHeight!).clamp(0.0, _inputHeight!.toDouble());

        detections.add({
          'bbox': [x1, y1, x2, y2],
          'classIndex': bestClass,
          'score': maxScore,
        });
        
        // 처음 3개만 로그 출력
        if (detections.length <= 3) {
          debugPrint('🔍 탐지 ${detections.length}: 클래스=$bestClass, 점수=${maxScore.toStringAsFixed(4)}, bbox=[${x1.toStringAsFixed(1)}, ${y1.toStringAsFixed(1)}, ${x2.toStringAsFixed(1)}, ${y2.toStringAsFixed(1)}]');
        }
      }
    }

    debugPrint('📊 임계값 필터링 후: ${detections.length}개 탐지');

    // 신뢰도 순으로 정렬 후 상위 N개만 선택 (NMS 전에 필터링)
    detections.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    final topDetections = detections.take(maxDetections * 2).toList(); // NMS를 위해 2배로 선택

    // NMS 적용
    final filtered = _applyNMS(topDetections, threshold: 0.5);

    // 최종 상위 N개만 반환
    final result = filtered.take(maxDetections).toList();

    return result;
  }

  /// Non-Maximum Suppression 적용 (성능 최적화)
  List<Map<String, dynamic>> _applyNMS(
    List<Map<String, dynamic>> detections, {
    double threshold = 0.5,
  }) {
    if (detections.isEmpty) return [];

    final List<Map<String, dynamic>> result = [];
    final List<bool> suppressed = List<bool>.filled(detections.length, false);

    // 이미 정렬되어 있다고 가정 (정렬 최소화)
    for (int i = 0; i < detections.length && result.length < 20; i++) {
      if (suppressed[i]) continue;

      result.add(detections[i]);
      final bbox1 = detections[i]['bbox'] as List<double>;
      final maxSize = math.max(bbox1[2] - bbox1[0], bbox1[3] - bbox1[1]);

      // 빠른 거리 기반 필터링 (거리가 너무 멀면 IOU 계산 생략)
      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;

        final bbox2 = detections[j]['bbox'] as List<double>;
        
        // 빠른 거리 체크
        final centerX1 = (bbox1[0] + bbox1[2]) / 2;
        final centerY1 = (bbox1[1] + bbox1[3]) / 2;
        final centerX2 = (bbox2[0] + bbox2[2]) / 2;
        final centerY2 = (bbox2[1] + bbox2[3]) / 2;
        
        final distX = (centerX1 - centerX2).abs();
        final distY = (centerY1 - centerY2).abs();
        
        // 거리가 너무 멀면 IOU 계산 생략
        if (distX > maxSize * 2 || distY > maxSize * 2) {
          continue;
        }

        final iou = _calculateIOU(bbox1, bbox2);
        if (iou > threshold) {
          suppressed[j] = true;
        }
      }
    }

    return result;
  }

  /// IoU (Intersection over Union) 계산 (최적화)
  double _calculateIOU(List<double> bbox1, List<double> bbox2) {
    final x1 = math.max(bbox1[0], bbox2[0]);
    final y1 = math.max(bbox1[1], bbox2[1]);
    final x2 = math.min(bbox1[2], bbox2[2]);
    final y2 = math.min(bbox1[3], bbox2[3]);

    final intersectionWidth = x2 - x1;
    final intersectionHeight = y2 - y1;
    
    if (intersectionWidth <= 0 || intersectionHeight <= 0) return 0.0;

    final intersection = intersectionWidth * intersectionHeight;
    final area1 = (bbox1[2] - bbox1[0]) * (bbox1[3] - bbox1[1]);
    final area2 = (bbox2[2] - bbox2[0]) * (bbox2[3] - bbox2[1]);
    final union = area1 + area2 - intersection;

    if (union <= 0) return 0.0;
    return intersection / union;
  }

  /// CameraImage를 Uint8List로 변환
  Uint8List? _cameraImageToBytes(CameraImage cameraImage) {
    try {
      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420ToRGB(cameraImage);
      } else if (cameraImage.format.group == ImageFormatGroup.nv21) {
        return _convertNV21ToRGB(cameraImage);
      } else {
        // 단일 플레인 이미지 (JPEG 등)
        if (cameraImage.planes.length == 1) {
          return cameraImage.planes[0].bytes;
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ 카메라 이미지 변환 오류: $e');
      return null;
    }
  }

  /// YUV420을 RGB로 변환
  Uint8List _convertYUV420ToRGB(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;

    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    final vPlane = cameraImage.planes[2];

    final rgb = Uint8List(width * height * 3);
    int rgbIndex = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = (y * yPlane.bytesPerRow) + x;
        final uvIndex = ((y ~/ 2) * uPlane.bytesPerRow) + (x ~/ 2);

        final yVal = yPlane.bytes[yIndex];
        final uVal = uPlane.bytes[uvIndex] - 128;
        final vVal = vPlane.bytes[uvIndex] - 128;

        // YUV to RGB 변환
        var r = (yVal + 1.402 * vVal).clamp(0, 255);
        var g = (yVal - 0.344 * uVal - 0.714 * vVal).clamp(0, 255);
        var b = (yVal + 1.772 * uVal).clamp(0, 255);

        rgb[rgbIndex++] = r.toInt();
        rgb[rgbIndex++] = g.toInt();
        rgb[rgbIndex++] = b.toInt();
      }
    }

    return rgb;
  }

  /// NV21을 RGB로 변환
  Uint8List _convertNV21ToRGB(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;

    final yPlane = cameraImage.planes[0];
    final uvPlane = cameraImage.planes[1];

    final rgb = Uint8List(width * height * 3);
    int rgbIndex = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = (y * yPlane.bytesPerRow) + x;
        final uvIndex = ((y ~/ 2) * uvPlane.bytesPerRow) + ((x ~/ 2) * 2);

        final yVal = yPlane.bytes[yIndex];
        final uVal = uvPlane.bytes[uvIndex] - 128;
        final vVal = uvPlane.bytes[uvIndex + 1] - 128;

        // YUV to RGB 변환
        var r = (yVal + 1.402 * vVal).clamp(0, 255);
        var g = (yVal - 0.344 * uVal - 0.714 * vVal).clamp(0, 255);
        var b = (yVal + 1.772 * uVal).clamp(0, 255);

        rgb[rgbIndex++] = r.toInt();
        rgb[rgbIndex++] = g.toInt();
        rgb[rgbIndex++] = b.toInt();
      }
    }

    return rgb;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }

  bool get isInitialized => _isInitialized;

  /// 클래스 인덱스를 여행 클래스 이름으로 변환
  String? getTravelClassName(int classIndex) {
    if (classIndex < 0 || classIndex >= _travelLabels.length) {
      return null;
    }
    return _travelLabels[classIndex];
  }

  /// 여행 클래스 라벨 목록 (22개)
  static const List<String> _travelLabels = [
    'passport',
    'power bank',
    'lighter',
    'battery',
    'knife',
    'scissors',
    'tool',
    'spray',
    'bottle',
    'laptop',
    'tablet',
    'camera',
    'drone',
    'luggage',
    'suitcase',
    'backpack',
    'sunglasses',
    'hat',
    'neck pillow',
    'cosmetics',
    'charger',
    'shoes',
  ];
}

