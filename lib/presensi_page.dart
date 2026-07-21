import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart'; // Variabel global 'cameras'

class PresensiPage extends StatefulWidget {
  const PresensiPage({super.key});

  @override
  State<PresensiPage> createState() => _PresensiPageState();
}

class _PresensiPageState extends State<PresensiPage> {
  CameraController? _cameraController;

  bool _isCameraInitialized = false;
  bool _isSubmitting = false;

  String _statusMessage = 'Mendeteksi posisi GPS...';
  Color _statusBorderColor = Colors.white;

  Position? _currentPosition;
  bool _isInRadius = false;

  // Koordinat Kantor (Jl. Veteran)
  final double _officeLat = -6.168305;
  final double _officeLng = 106.824700;
  final double _allowedRadius = 3000000.0; // Meter

  @override
  void initState() {
    super.initState();
    _initCamera();
    _checkLocationAndRadius();
  }

  // Inisialisasi Kamera Depan
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
    } catch (e) {
      debugPrint('Error kamera: $e');
    }
  }

  // Cek Lokasi GPS
  Future<void> _checkLocationAndRadius() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
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
          _statusMessage = 'Posisikan wajah Anda lalu tekan tombol Presensi';
          _statusBorderColor = const Color(0xFF006C49);
        } else {
          _statusMessage = 'Di luar area kantor! (${distance.toStringAsFixed(1)}m)';
          _statusBorderColor = Colors.red;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInRadius = true;
        _statusMessage = 'Posisikan wajah Anda lalu tekan tombol Presensi';
        _statusBorderColor = const Color(0xFF006C49);
      });
    }
  }

  // Eksekusi Ambil Foto & Kirim Presensi ke Laravel
  Future<void> _submitPresensi() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 1. Ambil Token dari SharedPreferences (Cek 'access_token' & 'token')
      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('access_token') ?? prefs.getString('token') ?? '';

      debugPrint('TOKEN DARI STORAGE: $token');

      // Jika token tidak ada di storage, minta user login ulang
      if (token.isEmpty) {
        _showResultDialog(
          title: 'Sesi Berakhir',
          message: 'Token login tidak ditemukan/expired. Silakan Login Ulang!',
          isSuccess: false,
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      // 2. Capture Foto dari Kamera
      XFile imageFile = await _cameraController!.takePicture();

      // 3. Setup Request Multipart HTTP
      String apiUrl = kIsWeb ? 'http://127.0.0.1:8000/api/presensi' : 'http://10.0.2.2:8000/api/presensi';
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // Header Wajib Sanctum
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['latitude'] = (_currentPosition?.latitude ?? _officeLat).toString();
      request.fields['longitude'] = (_currentPosition?.longitude ?? _officeLng).toString();

      // Lampirkan Foto
      if (kIsWeb) {
        var bytes = await imageFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: 'presensi.jpg'));
      } else {
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      }

      // 4. Kirim Request ke Laravel
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      final resData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showResultDialog(
          title: 'Presensi Berhasil!',
          message: 'Wajah Terverifikasi! (Kemiripan: ${resData['similarity'] ?? '-'})',
          isSuccess: true,
        );
      } else if (response.statusCode == 401) {
        _showResultDialog(
          title: 'Sesi Kedaluwarsa',
          message: 'Token login Anda tidak valid lagi. Silakan Login Ulang!',
          isSuccess: false,
        );
      } else {
        _showResultDialog(
          title: 'Presensi Gagal!',
          message: resData['message'] ?? 'Wajah tidak cocok!',
          isSuccess: false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showResultDialog(
        title: 'Error System',
        message: 'Gagal terhubung ke Server: $e',
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showResultDialog({required String title, required String message, required bool isSuccess}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.cancel,
              color: isSuccess ? const Color(0xFF006C49) : Colors.red,
              size: 60,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (isSuccess) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSuccess ? const Color(0xFF1D4ED8) : Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                isSuccess ? 'Kembali ke Beranda' : 'Coba Lagi',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
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

          // 3. Banner Petunjuk
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
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
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 4. TOMBOL PRESENSI MANUAL
          Positioned(
            bottom: 40,
            left: 40,
            right: 40,
            child: ElevatedButton(
              onPressed: (_isSubmitting || !_isInRadius) ? null : _submitPresensi,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006C49),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'AMBIL FOTO & PRESENSI',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}