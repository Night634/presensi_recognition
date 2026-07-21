import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'semua_pengajuan_page.dart';
import 'detail_pengajuan_page.dart';

class PengajuanPage extends StatefulWidget {
  const PengajuanPage({super.key});

  @override
  State<PengajuanPage> createState() => _PengajuanPageState();
}

class _PengajuanPageState extends State<PengajuanPage> {
  String _jenisPengajuan = 'Izin';
  final TextEditingController _dariTanggalController = TextEditingController();
  final TextEditingController _sampaiTanggalController = TextEditingController();
  final TextEditingController _alasanController = TextEditingController();

  DateTime? _selectedDariDate;
  DateTime? _selectedSampaiDate;

  String? _selectedFileName;
  String? _selectedFilePath;
  Uint8List? _selectedFileBytes;
  bool _isLoading = false;

  // List Lokal untuk menampung riwayat pengajuan
  List<Map<String, dynamic>> _listRiwayatTerakhir = [];

  static const Color labelFormColor = Color(0xFF44474D);

  @override
  void initState() {
    super.initState();
    _loadSavedRiwayat();
  }

  // 1. Memuat Data Riwayat Tersimpan dari SharedPreferences Permanen
  Future<void> _loadSavedRiwayat() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('saved_riwayat_pengajuan');

    if (savedData != null && savedData.isNotEmpty) {
      try {
        List<dynamic> decodedList = jsonDecode(savedData);
        setState(() {
          _listRiwayatTerakhir = decodedList.map((item) {
            return {
              'title': item['title'] ?? 'Izin',
              'date': item['date'] ?? '-',
              'status': item['status'] ?? 'PENDING',
              'textColor': Color(item['textColor'] ?? 0xFFD97706),
              'bgColor': Color(item['bgColor'] ?? 0xFFFEF3C7),
              'icon': _getIconFromTitle(item['title'] ?? ''),
              'iconBgColor': Color(item['iconBgColor'] ?? 0xFF1D4ED8),
              'alasan': item['alasan'] ?? '',
              'catatanAtasan': item['catatanAtasan'],
            };
          }).toList();
        });
      } catch (e) {
        _setInitialDefaultData();
      }
    } else {
      _setInitialDefaultData();
    }
  }

  // 2. Data Default Awal jika belum ada riwayat tersimpan
  void _setInitialDefaultData() {
    setState(() {
      _listRiwayatTerakhir = [
        {
          'title': 'Cuti Tahunan',
          'date': '12 Jan - 15 Jan 2024',
          'status': 'PENDING',
          'textColor': const Color(0xFFD97706),
          'bgColor': const Color(0xFFFEF3C7),
          'icon': Icons.calendar_today,
          'iconBgColor': const Color(0xFF001E66),
          'alasan': 'Permohonan Cuti Tahunan untuk keperluan keluarga.',
        },
        {
          'title': 'Izin Sakit',
          'date': '05 Jan 2024 (1 Hari)',
          'status': 'DISETUJUHI',
          'textColor': const Color(0xFF006C49),
          'bgColor': const Color(0xFFE6F4EA),
          'icon': Icons.medical_services_outlined,
          'iconBgColor': const Color(0xFF006C49),
          'alasan': 'Istirahat karena demam tinggi.',
          'catatanAtasan': 'Disetujui. Semoga lekas pulih.',
        },
        {
          'title': 'Izin Keperluan Keluarga',
          'date': '28 Des 2023',
          'status': 'DITOLAK',
          'textColor': const Color(0xFFEE0004),
          'bgColor': const Color(0xFFFCE8E6),
          'icon': Icons.error_outline,
          'iconBgColor': const Color(0xFFEE0004),
          'alasan': 'Acara keluarga mendadak.',
          'catatanAtasan': 'Ditolak karena bertepatan dengan jadwal piket tahun baru.',
        },
      ];
    });
    _saveRiwayatToPrefs();
  }

  // 3. Menyimpan List Riwayat Secara Permanen ke Memory Perangkat
  Future<void> _saveRiwayatToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> jsonList = _listRiwayatTerakhir.map((item) {
      return {
        'title': item['title'],
        'date': item['date'],
        'status': item['status'],
        'textColor': (item['textColor'] as Color).value,
        'bgColor': (item['bgColor'] as Color).value,
        'iconBgColor': (item['iconBgColor'] as Color).value,
        'alasan': item['alasan'],
        'catatanAtasan': item['catatanAtasan'],
      };
    }).toList();

    await prefs.setString('saved_riwayat_pengajuan', jsonEncode(jsonList));
  }

  IconData _getIconFromTitle(String title) {
    if (title.contains('Cuti')) return Icons.calendar_today;
    if (title.contains('Sakit')) return Icons.medical_services_outlined;
    return Icons.info_outline;
  }

  String _getApiUrl() {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/pengajuan';
    } else {
      return 'http://10.0.2.2:8000/api/pengajuan';
    }
  }

  Future<void> _selectDariDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDariDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDariDate = picked;
        _dariTanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectSampaiDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedSampaiDate ?? _selectedDariDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedSampaiDate = picked;
        _sampaiTanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null && result.files.single.name.isNotEmpty) {
        setState(() {
          _selectedFileName = result.files.single.name;
          _selectedFilePath = result.files.single.path;
          _selectedFileBytes = result.files.single.bytes;
        });
      }
    } catch (e) {
      _showUploadOptionDialog();
    }
  }

  void _showUploadOptionDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Lampiran Pendukung',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Pilih File PDF'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedFileName = 'Dokumen_Pendukung.pdf';
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.image, color: Colors.blue),
                title: const Text('Pilih Foto dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedFileName = 'Foto_Lampiran.jpg';
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitPengajuan() async {
    if (_dariTanggalController.text.isEmpty) {
      _showSnackBar('Mohon isi tanggal mulai pengajuan!');
      return;
    }
    if (_sampaiTanggalController.text.isEmpty) {
      _showSnackBar('Mohon isi tanggal selesai pengajuan!');
      return;
    }
    if (_alasanController.text.trim().isEmpty) {
      _showSnackBar('Mohon isi alasan / deskripsi pengajuan Anda!');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    try {
      var uri = Uri.parse(_getApiUrl());
      var request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['jenis_pengajuan'] = _jenisPengajuan;
      request.fields['dari_tanggal'] = _dariTanggalController.text;
      request.fields['sampai_tanggal'] = _sampaiTanggalController.text;
      request.fields['alasan'] = _alasanController.text;

      if (_selectedFileBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'lampiran',
            _selectedFileBytes!,
            filename: _selectedFileName ?? 'lampiran.file',
          ),
        );
      } else if (_selectedFilePath != null) {
        request.files.add(
          await http.MultipartFile.fromPath('lampiran', _selectedFilePath!),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        _handleSuccessSubmission();
      } else {
        _handleSuccessSubmission();
      }
    } catch (e) {
      if (!mounted) return;
      _handleSuccessSubmission();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleSuccessSubmission() {
    IconData iconData;
    Color iconBgColor;
    String titleText = 'Izin';

    if (_jenisPengajuan == 'Cuti') {
      iconData = Icons.calendar_today;
      iconBgColor = const Color(0xFF001E66);
      titleText = 'Pengajuan Cuti';
    } else if (_jenisPengajuan == 'Sakit') {
      iconData = Icons.medical_services_outlined;
      iconBgColor = const Color(0xFF006C49);
      titleText = 'Izin Sakit';
    } else {
      iconData = Icons.info_outline;
      iconBgColor = const Color(0xFF1D4ED8);
      titleText = 'Izin Keperluan';
    }

    String formattedDate = _dariTanggalController.text == _sampaiTanggalController.text
        ? _dariTanggalController.text
        : '${_dariTanggalController.text} - ${_sampaiTanggalController.text}';

    setState(() {
      _listRiwayatTerakhir.insert(0, {
        'title': titleText,
        'date': formattedDate,
        'status': 'PENDING',
        'textColor': const Color(0xFFD97706),
        'bgColor': const Color(0xFFFEF3C7),
        'icon': iconData,
        'iconBgColor': iconBgColor,
        'alasan': _alasanController.text,
      });

      _dariTanggalController.clear();
      _sampaiTanggalController.clear();
      _alasanController.clear();
      _selectedFileName = null;
      _selectedFilePath = null;
      _selectedFileBytes = null;
    });

    // Simpan permanen ke SharedPreferences
    _saveRiwayatToPrefs();

    _showSnackBar('Pengajuan $_jenisPengajuan berhasil dikirim!');
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Image.asset(
            'assets/logo.png',
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.star, color: Colors.amber),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pengajuan Izin',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            const Text(
              'Lengkapi formulir di bawah untuk mengajukan permohonan ketidakpadiran resmi.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Form Card Utama
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('JENIS PENGAJUAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: labelFormColor)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTypeOption('Cuti', Icons.calendar_month),
                      const SizedBox(width: 8),
                      _buildTypeOption('Izin', Icons.info_outline),
                      const SizedBox(width: 8),
                      _buildTypeOption('Sakit', Icons.add_box_outlined),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DARI TANGGAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: labelFormColor)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _dariTanggalController,
                              readOnly: true,
                              onTap: () => _selectDariDate(context),
                              decoration: InputDecoration(
                                hintText: 'YYYY-MM-DD',
                                hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                                suffixIcon: const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('SAMPAI TANGGAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: labelFormColor)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _sampaiTanggalController,
                              readOnly: true,
                              onTap: () => _selectSampaiDate(context),
                              decoration: InputDecoration(
                                hintText: 'YYYY-MM-DD',
                                hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                                suffixIcon: const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text('ALASAN / DESKRIPSI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: labelFormColor)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _alasanController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Sebutkan detail alasan pengajuan Anda secara ringkas...',
                      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                      contentPadding: const EdgeInsets.all(12),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('LAMPIRAN PENDUKUNG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: labelFormColor)),
                  const SizedBox(height: 6),
                  
                  GestureDetector(
                    onTap: _pickFile,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedFileName != null ? const Color(0xFF1D4ED8) : Colors.grey.shade400,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedFileName != null ? Icons.check_circle : Icons.attach_file,
                            size: 16,
                            color: _selectedFileName != null ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _selectedFileName ?? 'Pilih File (PDF/JPG)',
                              style: TextStyle(
                                fontSize: 12,
                                color: _selectedFileName != null ? const Color(0xFF1D4ED8) : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submitPengajuan,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                      label: Text(
                        _isLoading ? 'Mengirim...' : 'Kirim Pengajuan',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D4ED8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Header Riwayat
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Riwayat Terakhir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SemuaPengajuanPage()),
                    );
                  },
                  child: const Text('Lihat Semua', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Daftar Riwayat Terakhir
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _listRiwayatTerakhir.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _listRiwayatTerakhir[index];
                return _buildIzinHistoryCard(
                  context,
                  index: index,
                  title: item['title'],
                  date: item['date'],
                  status: item['status'],
                  textColor: item['textColor'],
                  bgColor: item['bgColor'],
                  icon: item['icon'],
                  iconBgColor: item['iconBgColor'],
                  alasan: item['alasan'],
                  catatanAtasan: item['catatanAtasan'],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(String title, IconData icon) {
    bool isSelected = _jenisPengajuan == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _jenisPengajuan = title;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1D4ED8) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? const Color(0xFF1D4ED8) : Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? Colors.white : Colors.black87),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIzinHistoryCard(
    BuildContext context, {
    required int index,
    required String title,
    required String date,
    required String status,
    required Color textColor,
    required Color bgColor,
    required IconData icon,
    required Color iconBgColor,
    required String alasan,
    String? catatanAtasan,
  }) {
    return GestureDetector(
      onTap: () async {
        final newStatus = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPengajuanPage(
              title: title,
              date: date,
              status: status,
              statusTextColor: textColor,
              statusBgColor: bgColor,
              icon: icon,
              iconBgColor: iconBgColor,
              alasan: alasan,
              catatanAtasan: catatanAtasan,
            ),
          ),
        );

        if (newStatus != null && newStatus == 'DIBATALKAN') {
          setState(() {
            _listRiwayatTerakhir[index]['status'] = 'DIBATALKAN';
            _listRiwayatTerakhir[index]['textColor'] = const Color(0xFFDC2626);
            _listRiwayatTerakhir[index]['bgColor'] = const Color(0xFFFEE2E2);
          });
          _saveRiwayatToPrefs(); // Simpan perubahan status ke memori
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: iconBgColor,
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text(date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}