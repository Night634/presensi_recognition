import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum LivenessStep { turnLeft, turnRight, completed }

class PresensiPage extends StatefulWidget {
  const PresensiPage({super.key});

  @override
  State<PresensiPage> createState() => _PresensiPageState();
}

class _PresensiPageState extends State<PresensiPage> {
  // Web Native Video Element
  html.VideoElement? _videoElement;
  String _viewId = 'web-camera-view';

  bool _isCameraInitialized = false;
  bool _isSubmitting = false;

  String _statusMessage = 'Mendeteksi lokasi & kamera...';
  Color _statusBorderColor = Colors.white;

  Position? _currentPosition;
  bool _isInRadius = false;
  String _namaGedungTerdekat = '-';

  // Liveness & ML Kit State Variables
  FaceDetector? _faceDetector;
  LivenessStep _currentLivenessStep = LivenessStep.turnLeft;
  bool _isLivenessVerified = false;

  String get _baseUrl => kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';

  @override
  void initState() {
    super.initState();
    _initializeAll();
  }

  Future<void> _initializeAll() async {
    _initFaceDetector();
    await _initWebCamera();
    await _fetchLokasiAndCheckPosition();
  }

  // ===== 1. INISIALISASI ML KIT FACE DETECTOR =====
  void _initFaceDetector() {
    try {
      final options = FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableTracking: true,
      );
      _faceDetector = FaceDetector(options: options);
    } catch (e) {
      debugPrint('ML Kit Face Detector tidak tersedia di lingkungan ini: $e');
    }
  }

  // ===== 2. INISIALISASI KAMERA WEB NATIVE =====
  Future<void> _initWebCamera() async {
    try {
      _viewId = 'web-camera-view-${DateTime.now().millisecondsSinceEpoch}';

      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        _viewId,
        (int viewId) => _videoElement!,
      );

      final mediaStream = await html.window.navigator.mediaDevices?.getUserMedia({
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 1280},
          'height': {'ideal': 720}
        },
        'audio': false,
      });

      if (mediaStream != null && _videoElement != null) {
        _videoElement!.srcObject = mediaStream;
        if (!mounted) return;
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error Inisialisasi Kamera Native: $e');
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Gagal memuat kamera. Izinkan akses kamera pada browser.';
        _statusBorderColor = Colors.red;
      });
    }
  }

  // ===== Algoritma Point-in-Polygon (Ray-Casting) =====
  // ===== Fungsi Ray-Casting Khusus Format Array [[lat, lng], ...] =====
  bool _isPointInPolygon(double userLat, double userLng, List<dynamic> polygonCoords) {
    if (polygonCoords.length < 3) return false;

    bool isInside = false;
    int j = polygonCoords.length - 1;

    for (int i = 0; i < polygonCoords.length; i++) {
      double iLat = 0.0, iLng = 0.0;
      double jLat = 0.0, jLng = 0.0;

      // Parsing Titik I
      var pointI = polygonCoords[i];
      if (pointI is List && pointI.length >= 2) {
        iLat = double.tryParse(pointI[0].toString()) ?? 0.0;
        iLng = double.tryParse(pointI[1].toString()) ?? 0.0;
      } else if (pointI is Map) {
        iLat = double.tryParse(pointI['lat']?.toString() ?? '0') ?? 0.0;
        iLng = double.tryParse(pointI['lng']?.toString() ?? '0') ?? 0.0;
      }

      // Parsing Titik J
      var pointJ = polygonCoords[j];
      if (pointJ is List && pointJ.length >= 2) {
        jLat = double.tryParse(pointJ[0].toString()) ?? 0.0;
        jLng = double.tryParse(pointJ[1].toString()) ?? 0.0;
      } else if (pointJ is Map) {
        jLat = double.tryParse(pointJ['lat']?.toString() ?? '0') ?? 0.0;
        jLng = double.tryParse(pointJ['lng']?.toString() ?? '0') ?? 0.0;
      }

      // Hitung perpotongan garis (Ray-Casting)
      bool intersect = ((iLng > userLng) != (jLng > userLng)) &&
          (userLat < (jLat - iLat) * (userLng - iLng) / (jLng - iLng) + iLat);

      if (intersect) isInside = !isInside;
      j = i;
    }

    return isInside;
  }

  // ===== 3. FETCH LOKASI POLYGON & FIX GEOLOCATION WEB =====
  Future<void> _fetchLokasiAndCheckPosition() async {
    try {
      // FIX GPS WEB: Cek apakah Geolocation aktif
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _updateLocationError('Layanan GPS perangkat belum aktif.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _updateLocationError('Izin akses lokasi ditolak oleh pengguna.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _updateLocationError('Izin lokasi ditolak permanen. Aktifkan di setelan browser.');
        return;
      }

      // FIX GPS WEB: Tambahkan timeout agar tidak menggantung tanpa respon
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _currentPosition = position;

      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('access_token') ?? prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('$_baseUrl/api/office-location'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      bool insideAnyPolygon = false;
      String namaAreaTerdeteksi = '-';

      if (response.statusCode == 200) {
        var decoded = jsonDecode(response.body);
        List<dynamic> listLokasi = [];

        if (decoded is List) {
          listLokasi = decoded;
        } else if (decoded is Map && decoded.containsKey('data')) {
          listLokasi = decoded['data'] is List ? decoded['data'] : [decoded['data']];
        }

        for (var lokasi in listLokasi) {
          String nama = lokasi['nama_gedung'] ?? 'Area';
          List<dynamic> coords = [];

          if (lokasi['coordinates'] is List) {
            coords = lokasi['coordinates'];
          } else if (lokasi['coordinates'] is String) {
            try {
              coords = jsonDecode(lokasi['coordinates']);
            } catch (_) {}
          }

          if (coords.length >= 3) {
            bool matched = _isPointInPolygon(position.latitude, position.longitude, coords);
            
            if (matched) {
              insideAnyPolygon = true;
              namaAreaTerdeteksi = nama;
              break;
            }
          }
          // Pakai ini di dalam _fetchLokasiAndCheckPosition():
          debugPrint('=== DEBUG GPS USER ===');
          debugPrint('Lat User: ${position.latitude}');
          debugPrint('Lng User: ${position.longitude}');
          debugPrint('Data Polygon DB: $coords');
        }
      }

      if (!mounted) return;

      setState(() {
        _isInRadius = insideAnyPolygon;
        _namaGedungTerdekat = namaAreaTerdeteksi;

        if (_isInRadius) {
          _statusMessage = 'Anda berada di wilayah terdaftar ($namaAreaTerdeteksi).\nPosisikan wajah Anda pada area bingkai.';
          _statusBorderColor = const Color(0xFF006C49);
        } else {
          _statusMessage = 'Anda berada di luar seluruh wilayah terdaftar (Kantor/Rumah)!';
          _statusBorderColor = Colors.red;
        }
      });
    } catch (e) {
      debugPrint('Error Cek Polygon Lokasi: $e');
      _updateLocationError('Gagal mendeteksi lokasi GPS. Pastikan GPS aktif.');
    }
  }

  void _updateLocationError(String message) {
    if (!mounted) return;
    setState(() {
      _isInRadius = false;
      _statusMessage = message;
      _statusBorderColor = Colors.red;
    });
  }

  // ===== 4. CAPTURE CANVAS GAMBAR & SUBMIT KE BACKEND =====
  Future<void> _submitPresensi() async {
    if (_videoElement == null || !_isCameraInitialized) return;

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
          description: 'Token autentikasi tidak ditemukan. Silakan login ulang.',
        );
        return;
      }

      // Capture frame video ke Canvas HTML
      final canvas = html.CanvasElement(
        width: _videoElement!.videoWidth > 0 ? _videoElement!.videoWidth : 640,
        height: _videoElement!.videoHeight > 0 ? _videoElement!.videoHeight : 480,
      );
      final ctx = canvas.context2D;
      ctx.drawImage(_videoElement!, 0, 0);

      final dataUrl = canvas.toDataUrl('image/jpeg', 0.85);
      final base64String = dataUrl.split(',').last;
      Uint8List imageBytes = base64Decode(base64String);

      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/api/presensi'));
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['latitude'] = (_currentPosition?.latitude ?? 0.0).toString();
      request.fields['longitude'] = (_currentPosition?.longitude ?? 0.0).toString();
      request.fields['is_liveness_verified'] = _isLivenessVerified ? '1' : '0';

      request.files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: 'presensi.jpg'));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;
      final resData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        DateTime now = DateTime.now();
        String formattedTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB";

        String tipePresensi = (resData['type'] == 'pulang') ? 'Pulang' : 'Masuk';

        _showResultDialog(
          isSuccess: true,
          userName: resData['user_name'] ?? 'Pegawai',
          waktu: formattedTime,
          lokasi: _namaGedungTerdekat,
          presensiId: 'PRE-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${resData['data_id'] ?? "001"}',
          customTitle: 'Presensi $tipePresensi Berhasil!',
        );
      } else {
        _showResultDialog(
          isSuccess: false,
          title: 'Presensi Ditolak',
          description: resData['message'] ?? 'Verifikasi wajah gagal atau posisi berada di luar kantor.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showResultDialog(
        isSuccess: false,
        title: 'Sistem Error',
        description: 'Gagal terhubung ke server Laravel.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Pop-up Result Dialog
  void _showResultDialog({
    required bool isSuccess,
    String? userName,
    String? waktu,
    String? lokasi,
    String? presensiId,
    String? title,
    String? description,
    String? customTitle,
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
              ? _buildSuccessPopUp(userName, waktu, lokasi, presensiId, customTitle)
              : _buildErrorPopUp(title, description),
        ),
      ),
    );
  }

  Widget _buildSuccessPopUp(String? userName, String? waktu, String? lokasi, String? presensiId, String? customTitle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(color: Color(0xFF63F5AD), shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: Color(0xFF005031), size: 48),
        ),
        const SizedBox(height: 18),
        Text(customTitle ?? 'Presensi Berhasil!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.4),
            children: [
              const TextSpan(text: 'Halo '),
              TextSpan(text: '${userName ?? "Pegawai"}. ', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              const TextSpan(text: 'Data presensi Anda telah berhasil dicatat.'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.access_time_filled, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text('Waktu', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                  const Spacer(),
                  Text(waktu ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827))),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: Color(0xFFF3F4F6)),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.location_on, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text('Lokasi', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                  const Spacer(),
                  Text(lokasi ?? 'Area Kantor', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0052FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
            ),
            child: const Text('Kembali ke Beranda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorPopUp(String? title, String? description) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(color: Color(0xFFFFD1D1), shape: BoxShape.circle),
          child: const Icon(Icons.warning_rounded, color: Color(0xFF990000), size: 48),
        ),
        const SizedBox(height: 18),
        Text(title ?? 'Presensi Ditolak', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
        const SizedBox(height: 8),
        Text(description ?? 'Terjadi kesalahan sistem.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0052FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
            ),
            child: const Text('Coba Lagi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _faceDetector?.close();
    if (_videoElement != null && _videoElement!.srcObject != null) {
      final tracks = _videoElement!.srcObject!.getTracks();
      for (var track in tracks) {
        track.stop();
      }
    }
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
          // 1. Live Camera Stream Preview (Web Native)
          _isCameraInitialized
              ? SizedBox.expand(
                  child: HtmlElementView(viewType: _viewId),
                )
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),

          // 2. Bingkai Oval Wajah
          Center(
            child: Container(
              width: 260,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(160),
                border: Border.all(color: _statusBorderColor, width: 3.5),
              ),
            ),
          ),

          // 3. Banner Status Lokasi & Petunjuk
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _statusBorderColor, width: 1.5),
              ),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // 4. Tombol Presensi
          Positioned(
            bottom: 40,
            left: 40,
            right: 40,
            child: ElevatedButton(
              onPressed: (_isSubmitting || !_isInRadius) ? null : _submitPresensi,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006C49),
                disabledBackgroundColor: Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
                        Text('AMBIL FOTO & PRESENSI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}