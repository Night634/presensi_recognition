import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  DateTime _focusedDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  // Kode Warna Spesifik Sesuai Instruksi
  static const Color greenColor = Color(0xFF006C49);
  static const Color redColor = Color(0xFFEE0004);
  static const Color blueColor = Color(0xFF001E66);

  final List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  List<Map<String, dynamic>> _aktivitasTerbaru = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchHistoryData();
  }

  String _getApiUrl() {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/presensi/history';
    } else {
      return 'http://10.0.2.2:8000/api/presensi/history';
    }
  }

  Future<void> _fetchHistoryData() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    if (token.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse(_getApiUrl()),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['data'] != null) {
            setState(() {
              _aktivitasTerbaru = List<Map<String, dynamic>>.from(data['data']);
              _isLoading = false;
            });
            return;
          }
        }
      } catch (e) {
        debugPrint('Gagal mengambil riwayat dari API: $e');
      }
    }

    // Default Fallback Data (Jika offline/server belum terhubung)
    setState(() {
      _aktivitasTerbaru = [
        {
          'date': 'Senin, 09 Okt',
          'location': 'Kemensetneg, Gedung II',
          'status': 'HADIR',
          'statusColor': greenColor,
          'clockIn': '07:55',
          'clockOut': '17:05',
          'duration': '09j 10m',
        },
        {
          'date': 'Jumat, 06 Okt',
          'location': 'Remote Working',
          'status': 'TERLAMBAT',
          'statusColor': redColor,
          'clockIn': '08:12',
          'clockOut': '17:30',
          'duration': '09j 18m',
          'note': 'Terlambat 12 menit dari jadwal.',
        },
        {
          'date': 'Kamis, 05 Okt',
          'location': 'Kemensetneg, Gedung Utama',
          'status': 'HADIR',
          'statusColor': greenColor,
          'clockIn': '07:48',
          'clockOut': '17:01',
          'duration': '09j 13m',
        },
      ];
      _isLoading = false;
    });
  }

  void _previousMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
    });
  }

  Future<void> _selectYearMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _focusedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _focusedDate = picked;
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(_focusedDate.year, _focusedDate.month);
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final startingWeekday = firstDayOfMonth.weekday;

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
            // Title Header dengan Garis Biru Kiri
            Row(
              children: [
                Container(
                  width: 4,
                  height: 38,
                  decoration: BoxDecoration(
                    color: blueColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Riwayat Kehadiran',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Sistem Pemantauan Presensi Pegawai Terpadu',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Card Kalender
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => _selectYearMonth(context),
                        child: Row(
                          children: [
                            Text(
                              '${_monthNames[_focusedDate.month - 1]} ${_focusedDate.year}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, size: 18),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, size: 20, color: Colors.black87),
                            onPressed: _previousMonth,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, size: 20, color: Colors.black87),
                            onPressed: _nextMonth,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Header Nama Hari (SN - MG)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const ['SN', 'SL', 'RB', 'KM', 'JM', 'SB', 'MG']
                        .map((day) => Expanded(
                              child: Center(
                                child: Text(
                                  day,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 10),

                  // Grid Tanggal
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: daysInMonth + (startingWeekday - 1),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    itemBuilder: (context, index) {
                      if (index < startingWeekday - 1) {
                        return const SizedBox.shrink();
                      }

                      final dayNumber = index - (startingWeekday - 1) + 1;
                      final date = DateTime(_focusedDate.year, _focusedDate.month, dayNumber);

                      bool isSelected = date.day == _selectedDate.day &&
                          date.month == _selectedDate.month &&
                          date.year == _selectedDate.year;

                      bool hasHadir = [2, 3, 4, 6].contains(dayNumber);
                      bool hasTerlambat = [5].contains(dayNumber);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$dayNumber',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            if (!isSelected && (hasHadir || hasTerlambat)) ...[
                              const SizedBox(height: 2),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: hasHadir ? greenColor : Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ]
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // STATUS CHIPS DI LUAR KALENDER (SAMA PANJANG DAN PRESISI)
            Row(
              children: [
                Expanded(child: _buildStatusChip('Hadir: 18', greenColor, Icons.check_circle)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatusChip('Terlambat: 2', redColor, Icons.access_time_filled)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatusChip('Izin: 1', blueColor, Icons.info)),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              'AKTIVITAS TERBARU',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),

            // Daftar Aktivitas Terbaru Secara Dinamis
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _aktivitasTerbaru.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _aktivitasTerbaru[index];
                      return _buildHistoryCard(
                        date: item['date'] ?? '-',
                        location: item['location'] ?? 'Kemensetneg',
                        status: item['status'] ?? 'HADIR',
                        statusColor: item['statusColor'] ?? greenColor,
                        clockIn: item['clockIn'] ?? '-',
                        clockOut: item['clockOut'] ?? '-',
                        duration: item['duration'] ?? '-',
                        note: item['note'],
                      );
                    },
                  ),
            const SizedBox(height: 24),

            // Tombol "Tampilkan Lebih Banyak"
            Center(
              child: SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                  label: const Text(
                    'Tampilkan Lebih Banyak',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0052FF),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard({
    required String date,
    required String location,
    required String status,
    required Color statusColor,
    required String clockIn,
    required String clockOut,
    required String duration,
    String? note,
  }) {
    bool isLate = status == 'TERLAMBAT';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text(location, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, size: 6, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeColumn('CLOCK IN', clockIn, valueColor: isLate ? statusColor : Colors.black87),
              _buildTimeColumn('CLOCK OUT', clockOut, valueColor: Colors.black87),
              _buildTimeColumn('DURASI', duration, valueColor: isLate ? Colors.black87 : greenColor, isBold: true),
            ],
          ),

          if (note != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(note, style: TextStyle(color: statusColor, fontSize: 11)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String label, String value, {required Color valueColor, bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}