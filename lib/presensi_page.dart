import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart'; // Variabel global 'cameras'

enum LivenessStep { turnLeft, turnRight, completed }

class PresensiPage extends StatefulWidget {
  const PresensiPage({super.key});

  @override
  State<PresensiPage> createState() => _PresensiPageState();
}

class _PresensiPageState extends State<PresensiPage> {
  CameraController? _cameraController;
  late FaceDetector _faceDetector;

  bool _isCameraInitialized = false;
  bool _isSubmitting = false;
  bool _isProcessingFrame = false;
  bool _isStreaming = false; // Flag status stream kamera

  // State Liveness Detection
  LivenessStep _currentLivenessStep = LivenessStep.turnLeft;
  bool _isLivenessVerified = false;

  String _statusMessage = 'Mendeteksi posisi GPS...';
  Color _statusBorderColor = Colors.white;

  Position? _currentPosition;
  bool _isInRadius = false;

  // Koordinat Kantor (Jl. Veteran)
  final double _officeLat = -6.168305;
  final double _officeLng = 106.824700;
  final double _allowedRadius = 3000.0; // Meter

  @override
  void initState() {
    super.initState();
    _initFaceDetector();
    _initCamera();
    _checkLocationAndRadius();
  }

  // 1. Inisialisasi Google ML Kit Face Detector
  void _initFaceDetector() {
    final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableTracking: true,
    );
    _faceDetector = FaceDetector(options: options);
  }

  // 2. Inisialisasi Kamera Depan & Image Stream untuk Liveness
  void _initCamera() async {
    if (cameras.isEmpty) return;

    CameraDescription frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });

      // Mulai Stream Per Frame untuk Membaca Gelengan Kepala
      _cameraController!.startImageStream((CameraImage image) {
        _isStreaming = true; // Set flag true saat streaming berjalan

        if (!_isProcessingFrame && !_isLivenessVerified && _isInRadius && !_isSubmitting) {
          _isProcessingFrame = true;
          _processCameraFrame(image);
        }
      });
    } catch (e) {
      debugPrint('Error kamera: $e');
    }
  }

  // 3. Proses Logika Deteksi Tengok Kiri -> Tengok Kanan
  Future<void> _processCameraFrame(CameraImage image) async {
    try {
      final inputImage = _getInputImageFromCameraImage(image);
      if (inputImage == null) return;

      final List<Face> faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        final Face face = faces.first;
        final double? headAngleY = face.headEulerAngleY; // (- = Kiri, + = Kanan)

        if (headAngleY != null) {
          // STEP 1: Deteksi Tengok Kiri (Angle < -20)
          if (_currentLivenessStep == LivenessStep.turnLeft && headAngleY < -20) {
            setState(() {
              _currentLivenessStep = LivenessStep.turnRight;
              _statusMessage = 'Bagus! Sekarang Tengok ke KANAN ➡️';
              _statusBorderColor = Colors.amber;
            });
          }
          // STEP 2: Deteksi Tengok Kanan (Angle > 20)
          else if (_currentLivenessStep == LivenessStep.turnRight && headAngleY > 20) {
            setState(() {
              _currentLivenessStep = LivenessStep.completed;
              _isLivenessVerified = true;
              _statusMessage = 'Wajah Asli Terverifikasi! Memproses Presensi... ✅';
              _statusBorderColor = const Color(0xFF006C49);
            });

            // Hentikan Stream & Langsung Submit Presensi Otomatis
            await _cameraController!.stopImageStream();
            _isStreaming = false; // Set flag false saat streaming berhenti
            
            _submitPresensi();
          }
        }
      }
    } catch (e) {
      debugPrint("Error Liveness: $e");
    } finally {
      _isProcessingFrame = false;
    }
  }

  InputImage? _getInputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;
    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;

    final InputImageRotation rotation =
        InputImageRotationValue.fromRawValue(sensorOrientation) ??
            InputImageRotation.rotation0deg;

    final InputImageFormat format =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
            InputImageFormat.nv21;

    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  // 4. Cek Lokasi GPS (Disesuaikan dengan Geolocator v10)
  Future<void> _checkLocationAndRadius() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // FIX: Pakai desiredAccuracy untuk Geolocator v10
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentPosition = position;

      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _officeLat,
        _officeLng,
      );

      if (!mounted) return;

      setState(() {
        _isInRadius = distance <= _allowedRadius;

        if (_isInRadius) {
          _statusMessage = 'Silakan Tengok ke KIRI ⬅️';
          _statusBorderColor = Colors.blue;
        } else {
          _statusMessage = 'Di luar area kantor! (${distance.toStringAsFixed(1)}m)';
          _statusBorderColor = Colors.red;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInRadius = true;
        _statusMessage = 'Silakan Tengok ke KIRI ⬅️';
        _statusBorderColor = Colors.blue;
      });
    }
  }

  // 5. Eksekusi Ambil Foto Snapshot & Kirim ke Backend Laravel
  Future<void> _submitPresensi() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('access_token') ?? prefs.getString('token') ?? '';

      if (token.isEmpty) {
        _showResultDialog(
          isSuccess: false,
          title: 'Sesi Berakhir',
          description: 'Token login tidak ditemukan/expired. Silakan Login Ulang!',
          errorType: 'AUTENTIKASI GAGAL',
          errorMessage: 'Silakan masuk kembali ke akun Anda.',
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      XFile imageFile = await _cameraController!.takePicture();

      String apiUrl = kIsWeb ? 'http://127.0.0.1:8000/api/presensi' : 'http://10.0.2.2:8000/api/presensi';
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['latitude'] = (_currentPosition?.latitude ?? _officeLat).toString();
      request.fields['longitude'] = (_currentPosition?.longitude ?? _officeLng).toString();
      request.fields['is_liveness_verified'] = '1';

      if (kIsWeb) {
        var bytes = await imageFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: 'presensi.jpg'));
      } else {
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      final resData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        DateTime now = DateTime.now();
        String formattedTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB";

        _showResultDialog(
          isSuccess: true,
          userName: 'Ramzy Atchallah',
          waktu: formattedTime,
          lokasi: 'Gedung Utama',
          presensiId: 'PRE-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${resData['data_id'] ?? "001"}',
        );
      } else if (response.statusCode == 401) {
        _showResultDialog(
          isSuccess: false,
          title: 'Sesi Kedaluwarsa',
          description: 'Token login Anda tidak valid lagi. Silakan Login Ulang!',
          errorType: 'AKSES DITOLAK',
          errorMessage: 'Token Sanctum telah kadaluwarsa.',
        );
      } else {
        _showResultDialog(
          isSuccess: false,
          title: 'Presensi Ditolak',
          description: resData['message'] ?? 'Maaf, wajah tidak dikenali atau lokasi Anda berada di luar radius kantor.',
          errorType: 'VERIFIKASI GAGAL',
          errorMessage: 'Data wajah atau lokasi tidak sesuai.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showResultDialog(
        isSuccess: false,
        title: 'Error System',
        description: 'Gagal terhubung ke Server. Pastikan koneksi atau server backend aktif.',
        errorType: 'KONEKSI TERPUTUS',
        errorMessage: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Dialog Custom
  void _showResultDialog({
    required bool isSuccess,
    String? userName,
    String? waktu,
    String? lokasi,
    String? presensiId,
    String? title,
    String? description,
    String? errorType,
    String? errorMessage,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: isSuccess
              ? _buildSuccessPopUp(userName, waktu, lokasi, presensiId)
              : _buildErrorPopUp(title, description, errorType, errorMessage),
        ),
      ),
    );
  }

  // Tampilan Pop-up SUKSES
  Widget _buildSuccessPopUp(String? userName, String? waktu, String? lokasi, String? presensiId) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            color: Color(0xFF63F5AD),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Color(0xFF005031),
            size: 50,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Presensi Berhasil!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 10),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563), height: 1.4),
            children: [
              const TextSpan(text: 'Selamat bekerja, '),
              TextSpan(
                text: '${userName ?? "Pegawai"}. ',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),
              const TextSpan(text: 'Data kehadiran Anda telah tersimpan.'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.access_time_filled, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Waktu', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                  const Spacer(),
                  Text(
                    waktu ?? '07:30 WIB',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF111827)),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Color(0xFFF3F4F6)),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Lokasi', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                  const Spacer(),
                  Text(
                    lokasi ?? 'Gedung Utama',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF111827)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0052FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Kembali ke Beranda',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ID PRESENSI: ${presensiId ?? "PRE-20260727-001"}',
          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ],
    );
  }

  // Tampilan Pop-up GAGAL
  Widget _buildErrorPopUp(String? title, String? description, String? errorType, String? errorMessage) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            color: Color(0xFFFFD1D1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.warning_rounded,
            color: Color(0xFF990000),
            size: 50,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title ?? 'Presensi Ditolak',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          description ?? 'Maaf, wajah tidak dikenali atau lokasi Anda berada di luar radius kantor.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.4),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.wifi_off_rounded, color: Color(0xFFDC2626), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      errorType ?? 'KESALAHAN TEKNIS',
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      errorMessage ?? 'Lokasi: Di luar jangkauan (Radius > 50m)',
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Reset status liveness untuk mencoba ulang
              setState(() {
                _currentLivenessStep = LivenessStep.turnLeft;
                _isLivenessVerified = false;
                _statusMessage = 'Silakan Tengok ke KIRI ⬅️';
                _statusBorderColor = Colors.blue;
              });

              // Jalankan ulang stream kamera
              if (_cameraController != null && !_isStreaming) {
                _isStreaming = true;
                _cameraController!.startImageStream((CameraImage image) {
                  if (!_isProcessingFrame && !_isLivenessVerified && _isInRadius && !_isSubmitting) {
                    _isProcessingFrame = true;
                    _processCameraFrame(image);
                  }
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0052FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Coba Lagi',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Hubungi Admin',
            style: TextStyle(color: Color(0xFF4B5563), fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Presensi Wajah', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 1. Live Camera Preview
          _isCameraInitialized && _cameraController != null
              ? SizedBox.expand(
                  child: CameraPreview(_cameraController!),
                )
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),

          // 2. Overlay Bingkai Wajah Oval
          Center(
            child: Container(
              width: 260,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(160),
                border: Border.all(
                  color: _statusBorderColor,
                  width: 3.5,
                ),
              ),
            ),
          ),

          // 3. Banner Petunjuk Gerakan Liveness & Status
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _statusBorderColor,
                  width: 1.5,
                ),
              ),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 4. Loading / Indicator Status di Bagian Bawah
          Positioned(
            bottom: 40,
            left: 40,
            right: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Mengirim Data Presensi...',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isLivenessVerified ? Icons.check_circle : Icons.face,
                            color: _isLivenessVerified ? Colors.greenAccent : Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isLivenessVerified
                                ? 'Liveness Sukses'
                                : 'Ikuti Petunjuk di Atas',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}