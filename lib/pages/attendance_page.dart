import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../state/app_state.dart';
import '../core/responsive_helper.dart';

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

  // Real Camera & Face Detector variables
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
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      // Find front camera
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

      // Initialize Face Detector with tracking enabled to fetch Euler angles
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: false,
          enableLandmarks: false,
          enableTracking: true,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

      // Start stream
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

      // Process every 3rd frame to reduce CPU load
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
            final yaw = face.headEulerAngleY; // Yaw rotation of head

            debugPrint("Liveness Face Yaw: $yaw | BoundingBox: ${face.boundingBox}");

            if (yaw != null) {
              setState(() {
                // On front camera (mirrored): turning head physically to YOUR left
                // produces positive yaw on some devices, negative on others.
                // We check both directions and use absolute threshold.
                final absYaw = yaw.abs();
                
                if (absYaw > 15.0) {
                  // Head is turned significantly
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
                  // Slowly decay progress when facing forward
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

      // For Android front camera in portrait mode:
      // Most front cameras have sensorOrientation=270
      // ML Kit needs the rotation that describes how to rotate the image to upright
      // For front camera with sensor 270 in portrait: use rotation270deg
      // But some devices need different handling, so we try the sensor orientation directly
      InputImageRotation rotation;
      if (Platform.isAndroid) {
        // On Android in portrait, front camera sensor is typically 270
        // The image from camera stream is already in sensor orientation
        // ML Kit expects rotation from image orientation to display orientation
        rotation = _rotationFromSensor(sensorOrientation) ?? InputImageRotation.rotation0deg;
      } else {
        rotation = _rotationFromSensor(sensorOrientation) ?? InputImageRotation.rotation0deg;
      }

      debugPrint("Camera: sensor=$sensorOrientation, isFront=$isFrontCamera, mlkitRotation=$rotation, imgSize=${image.width}x${image.height}, planes=${image.planes.length}");

      Uint8List bytes;
      InputImageFormat format;

      if (Platform.isAndroid) {
        // On Android, camera produces YUV_420_888
        // ML Kit on Android works best with NV21 format
        bytes = _yuv420ToNv21(image);
        format = InputImageFormat.nv21;
      } else {
        // For iOS (BGRA8888), copy planes directly
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
    
    // Copy Y plane row by row (respecting bytesPerRow stride)
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
    
    // Interleave V and U planes for NV21
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

  void _manageCameraLifecycle(AppState appState) {
    final stopCamera = appState.isUpacaraCheckInIntent
        ? (appState.isUpacaraCheckedIn || appState.currentTabIndex != 1)
        : (appState.isCheckedIn || appState.currentTabIndex != 1);

    if (stopCamera) {
      // Stop and dispose camera if running
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
      // Start camera if on active tab and not initialized yet
      if (_cameraController == null && !_isSuccessTriggered) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_cameraController == null && !_isSuccessTriggered) {
            _initializeCamera();
          }
        });
      }
    }
  }

  void _onVerificationSuccess() {
    if (_isSuccessTriggered) return;
    _isSuccessTriggered = true;

    // Stop and dispose camera immediately on success
    if (_cameraController != null) {
      final controller = _cameraController;
      _cameraController = null;
      _isCameraInitialized = false;
      _faceDetector?.close();
      _faceDetector = null;
      controller?.dispose();
    }

    final appState = Provider.of<AppState>(context, listen: false);

    // Perform check in state update
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    
    if (appState.isUpacaraCheckInIntent) {
      appState.doUpacaraCheckIn(timeStr);
      appState.isUpacaraCheckInIntent = false;
    } else {
      appState.doCheckIn(timeStr);
    }

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
                color: Color(0xFFE6F4EA),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.check_circle, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Absen Masuk Berhasil',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF191C1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kehadiran Anda hari ini telah berhasil diverifikasi pada jam $timeStr.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF434654),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Pop dialog
                appState.setTabIndex(0); // Navigate to Home (Dashboard)
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003D9B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
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
    final appState = Provider.of<AppState>(context);

    // Theme Colors
    const primaryColor = Color(0xFF003D9B);
    const background = Color(0xFFF8F9FB);
    const onSurface = Color(0xFF191C1E);
    const onSurfaceVariant = Color(0xFF434654);

    // Dynamic camera lifecycle manager
    _manageCameraLifecycle(appState);

    final showSuccess = appState.isUpacaraCheckInIntent
        ? appState.isUpacaraCheckedIn
        : appState.isCheckedIn;

    if (showSuccess) {
      // Show beautiful success check-in page instead of scanning
      return Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HR Connect',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Verifikasi Kehadiran',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Success Box Container matching design mockup
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE6F4EA),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle, color: Colors.green, size: 64),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        appState.isUpacaraCheckedIn ? 'Presensi Upacara Berhasil' : 'Absen Masuk Berhasil',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        appState.isUpacaraCheckedIn
                            ? 'Kehadiran Upacara Bendera Anda hari ini telah berhasil diverifikasi pada jam ${appState.upacaraTime}.'
                            : 'Kehadiran Anda hari ini telah berhasil diverifikasi pada jam ${appState.checkInTime}.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          appState.setTabIndex(0); // Navigate to Home
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          minimumSize: const Size(double.infinity, 48),
                          elevation: 0,
                        ),
                        child: Text(
                          'Masuk Dashboard',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.isWatch ? 10.0 : 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // Title Section
              Text(
                'Verifikasi Liveness',
                style: GoogleFonts.inter(
                  fontSize: context.sp(22),
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Silakan tengokkan kepala Anda secara perlahan ke arah kiri untuk verifikasi kehadiran.',
                style: GoogleFonts.inter(
                  fontSize: context.sp(13),
                  color: onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              SizedBox(height: context.h(24)),

              // CAMERA / FEED SIMULATOR
              Center(
                child: Container(
                  width: context.isWatch ? 140 : 260,
                  height: context.isWatch ? 140 : 260,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Real Camera Feed or Fallback Grid background
                        if (_isCameraInitialized && _cameraController != null)
                          FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _cameraController!.value.previewSize!.height,
                              height: _cameraController!.value.previewSize!.width,
                              child: CameraPreview(_cameraController!),
                            ),
                          )
                        else
                          Container(
                            color: const Color(0xFFEBEFF5),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 10,
                              ),
                              itemBuilder: (context, index) => Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.1),
                                    width: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Face frame outline overlay (CustomPaint or Icon)
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: 0.3 + (_pulseController.value * 0.7),
                              child: child,
                            );
                          },
                          child: Icon(
                            Icons.face_retouching_natural,
                            size: context.isWatch ? 80 : 150,
                            color: primaryColor.withOpacity(0.4),
                          ),
                        ),

                        // Scan lines overlay
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Positioned(
                              top: (context.isWatch ? 140 : 260) * _pulseController.value,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 2,
                                color: primaryColor.withOpacity(0.6),
                              ),
                            );
                          },
                        ),

                        // Inner green/blue progress boundary arc or border
                        SizedBox(
                          width: context.isWatch ? 120 : 230,
                          height: context.isWatch ? 120 : 230,
                          child: CircularProgressIndicator(
                            value: _progress,
                            strokeWidth: 4,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // PROGRESS INFORMATION
              Container(
                padding: EdgeInsets.all(context.isWatch ? 8.0 : 12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress Deteksi',
                          style: GoogleFonts.inter(
                            fontSize: context.sp(12),
                            fontWeight: FontWeight.w500,
                            color: onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${(_progress * 100).toInt()}%',
                          style: GoogleFonts.inter(
                            fontSize: context.sp(14),
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: context.isWatch ? 4 : 8,
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.psychology,
                            size: context.w(16), color: primaryColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _detectionStatus,
                            style: GoogleFonts.inter(
                              fontSize: context.sp(11),
                              fontWeight: FontWeight.w600,
                              color: onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.h(24)),

              // HELP BUTTON OR RESET
              OutlinedButton.icon(
                onPressed: () {
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
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[350]!),
                  padding: EdgeInsets.symmetric(vertical: context.isWatch ? 8.0 : 14.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.refresh,
                    color: onSurfaceVariant, size: 18),
                label: Text(
                  'Ulangi Deteksi',
                  style: GoogleFonts.inter(
                    color: onSurfaceVariant,
                    fontSize: context.sp(12),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Menghubungi bantuan verifikasi...')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[350]!),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.help_outline,
                    color: onSurfaceVariant, size: 18),
                label: Text(
                  'Butuh Bantuan?',
                  style: GoogleFonts.inter(
                    color: onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
