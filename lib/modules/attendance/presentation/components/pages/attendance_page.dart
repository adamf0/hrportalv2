import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:hrportalv2/modules/attendance/presentation/attendance_bloc.dart';
import 'package:hrportalv2/core/app_theme.dart';

// Modular Organisms
import 'package:hrportalv2/modules/attendance/presentation/components/organisms/attendance_success_card.dart';
import 'package:hrportalv2/modules/attendance/presentation/components/organisms/camera_scanner_view.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  String _detectionStatus = 'Mencari wajah...';
  late AnimationController _pulseController;
  bool _isSuccessTriggered = false;

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  FaceDetector? _faceDetector;
  bool _isProcessingFrame = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector?.close();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await getAvailableCameras();
      if (_cameras.isEmpty) return;

      final frontCamera = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });

      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: false,
          enableLandmarks: false,
          enableTracking: true,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

      _startImageStreaming(frontCamera);
    } catch (e) {
      debugPrint("Camera initialization failed: $e");
    }
  }

  void _startImageStreaming(CameraDescription camera) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    int frameSkipCounter = 0;

    _cameraController!.startImageStream((CameraImage image) async {
      if (_isProcessingFrame || _isSuccessTriggered) return;

      frameSkipCounter++;
      if (frameSkipCounter % 3 != 0) return;

      _isProcessingFrame = true;

      try {
        final inputImage = _inputImageFromCameraImage(image, camera);
        if (inputImage != null && _faceDetector != null) {
          final faces = await _faceDetector!.processImage(inputImage);
          if (!mounted || _isSuccessTriggered) return;

          debugPrint("ML Kit Faces detected: ${faces.length}");

          if (faces.isEmpty) {
            setState(() {
              _detectionStatus = 'Mencari wajah...';
            });
          } else {
            final face = faces.first;
            final yaw = face.headEulerAngleY;

            debugPrint("Liveness Face Yaw: $yaw | BoundingBox: ${face.boundingBox}");

            if (yaw != null) {
              setState(() {
                final absYaw = yaw.abs();
                
                if (absYaw > 15.0) {
                  double targetProgress = ((absYaw - 10.0) / 20.0).clamp(0.0, 1.0);
                  if (targetProgress > _progress) {
                    _progress = targetProgress;
                  }

                  if (_progress >= 1.0) {
                    _progress = 1.0;
                    _detectionStatus = 'Selesai!';
                    _onVerificationSuccess();
                  } else {
                    _detectionStatus = 'Bagus! Putar lebih ke kiri... (${(absYaw).toStringAsFixed(0)}°)';
                  }
                } else if (absYaw > 8.0) {
                  _detectionStatus = 'Sedikit lagi, putar lebih ke kiri...';
                } else {
                  _detectionStatus = 'Wajah terdeteksi. Silakan tengok ke kiri!';
                  if (_progress > 0) {
                    _progress = (_progress - 0.01).clamp(0.0, 1.0);
                  }
                }
              });
            } else {
              setState(() {
                _detectionStatus = 'Wajah terdeteksi (menunggu data rotasi...)';
              });
            }
          }
        } else {
          debugPrint("InputImage conversion returned null");
        }
      } catch (e) {
        debugPrint("Error processing liveness frame: $e");
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  InputImage? _inputImageFromCameraImage(CameraImage image, CameraDescription camera) {
    try {
      final sensorOrientation = camera.sensorOrientation;
      final isFrontCamera = camera.lensDirection == CameraLensDirection.front;

      InputImageRotation rotation;
      if (Platform.isAndroid) {
        rotation = _rotationFromSensor(sensorOrientation) ?? InputImageRotation.rotation0deg;
      } else {
        rotation = _rotationFromSensor(sensorOrientation) ?? InputImageRotation.rotation0deg;
      }

      debugPrint("Camera: sensor=$sensorOrientation, isFront=$isFrontCamera, mlkitRotation=$rotation, imgSize=${image.width}x${image.height}, planes=${image.planes.length}");

      Uint8List bytes;
      InputImageFormat format;

      if (Platform.isAndroid) {
        bytes = _yuv420ToNv21(image);
        format = InputImageFormat.nv21;
      } else {
        final WriteBuffer allBytes = WriteBuffer();
        for (final Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        bytes = allBytes.done().buffer.asUint8List();
        format = InputImageFormat.bgra8888;
      }

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    } catch (e) {
      debugPrint("Error converting camera image: $e");
      return null;
    }
  }

  Uint8List _yuv420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    
    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;
    
    final numPixels = width * height;
    final nv21 = Uint8List(numPixels + (numPixels ~/ 2));
    
    final yRowStride = yPlane.bytesPerRow;
    for (int row = 0; row < height; row++) {
      int srcOffset = row * yRowStride;
      int dstOffset = row * width;
      for (int col = 0; col < width; col++) {
        if (srcOffset + col < yBuffer.length) {
          nv21[dstOffset + col] = yBuffer[srcOffset + col];
        }
      }
    }
    
    int uvIndex = numPixels;
    final uRowStride = uPlane.bytesPerRow;
    final vRowStride = vPlane.bytesPerRow;
    final uPixelStride = uPlane.bytesPerPixel ?? 1;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;
    
    for (int row = 0; row < height ~/ 2; row++) {
      for (int col = 0; col < width ~/ 2; col++) {
        final vIndex = row * vRowStride + col * vPixelStride;
        final uIndex = row * uRowStride + col * uPixelStride;
        
        if (vIndex < vBuffer.length && uIndex < uBuffer.length && uvIndex < nv21.length - 1) {
          nv21[uvIndex++] = vBuffer[vIndex];
          nv21[uvIndex++] = uBuffer[uIndex];
        }
      }
    }
    return nv21;
  }

  InputImageRotation? _rotationFromSensor(int rotation) {
    switch (rotation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
    }
    return null;
  }

  void _manageCameraLifecycle(AttendanceBloc appState) {
    final stopCamera = appState.isUpacaraCheckInIntent
        ? (appState.isUpacaraCheckedIn || appState.currentTabIndex != 1)
        : (appState.isCheckedIn || appState.currentTabIndex != 1);

    if (stopCamera) {
      if (_cameraController != null) {
        final controller = _cameraController;
        _cameraController = null;
        _isCameraInitialized = false;
        _faceDetector?.close();
        _faceDetector = null;
        controller?.dispose();
        
        setState(() {
          _progress = 0.0;
          _detectionStatus = 'Mencari wajah...';
        });
      }
    } else {
      if (_cameraController == null && !_isSuccessTriggered) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_cameraController == null && !_isSuccessTriggered) {
            _initializeCamera();
          }
        });
      }
    }
  }

  void _onVerificationSuccess() async {
    if (_isSuccessTriggered) return;
    _isSuccessTriggered = true;

    if (_cameraController != null) {
      final controller = _cameraController;
      _cameraController = null;
      _isCameraInitialized = false;
      _faceDetector?.close();
      _faceDetector = null;
      controller?.dispose();
    }

    final appState = Provider.of<AttendanceBloc>(context, listen: false);
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    
    if (appState.isUpacaraCheckInIntent) {
      await appState.doUpacaraCheckIn(timeStr);
      appState.isUpacaraCheckInIntent = false;
    } else {
      await appState.doCheckIn(timeStr);
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.successContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppTheme.success, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Absen Masuk Berhasil',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kehadiran Anda hari ini telah berhasil diverifikasi pada jam $timeStr.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                appState.setTabIndex(0);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size(double.infinity, 44),
                elevation: 0,
              ),
              child: Text(
                'Masuk Dashboard',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AttendanceBloc>(context);

    _manageCameraLifecycle(appState);

    final showSuccess = appState.isUpacaraCheckInIntent
        ? appState.isUpacaraCheckedIn
        : appState.isCheckedIn;

    if (showSuccess) {
      return AttendanceSuccessCard(
        isUpacara: appState.isUpacaraCheckInIntent,
        time: appState.isUpacaraCheckInIntent ? appState.upacaraTime : appState.checkInTime,
        onBackTap: () => appState.setTabIndex(0),
      );
    }

    return CameraScannerView(
      isCameraInitialized: _isCameraInitialized,
      cameraController: _cameraController,
      progress: _progress,
      detectionStatus: _detectionStatus,
      pulseController: _pulseController,
      onRefreshTap: () {
        if (_cameraController != null) {
          final controller = _cameraController;
          _cameraController = null;
          _isCameraInitialized = false;
          _faceDetector?.close();
          _faceDetector = null;
          controller?.dispose();
        }
        setState(() {
          _progress = 0.0;
          _detectionStatus = 'Mencari wajah...';
          _isSuccessTriggered = false;
        });
        _initializeCamera();
      },
      onHelpTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menghubungi bantuan verifikasi...')),
        );
      },
    );
  }
}

// Available cameras mock check helper
Future<List<CameraDescription>> getAvailableCameras() async {
  try {
    return await availableCameras();
  } catch (_) {
    return [];
  }
}
