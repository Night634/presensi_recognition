import 'package:flutter/material.dart';
import 'detail_pengajuan_page.dart';

class SemuaPengajuanPage extends StatelessWidget {
  const SemuaPengajuanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Riwayat Pengajuan Izin',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildIzinItem(
            context,
            title: 'Cuti Tahunan',
            date: '12 Jan - 15 Jan 2024',
            status: 'PENDING',
            textColor: const Color(0xFFD97706),
            bgColor: const Color(0xFFFEF3C7),
            icon: Icons.calendar_today,
            iconBgColor: const Color(0xFF001E66),
            alasan: 'Permohonan Cuti Tahunan untuk keperluan keluarga.',
          ),
          const SizedBox(height: 10),
          _buildIzinItem(
            context,
            title: 'Izin Sakit',
            date: '05 Jan 2024 (1 Hari)',
            status: 'DISETUJUHI',
            textColor: const Color(0xFF006C49),
            bgColor: const Color(0xFFE6F4EA),
            icon: Icons.medical_services_outlined,
            iconBgColor: const Color(0xFF006C49),
            alasan: 'Istirahat karena demam sesuai surat dokter.',
            catatanAtasan: 'Disetujui. Semoga cepat sembuh.',
          ),
          const SizedBox(height: 10),
          _buildIzinItem(
            context,
            title: 'Izin Keperluan Keluarga',
            date: '28 Des 2023',
            status: 'DITOLAK',
            textColor: const Color(0xFFEE0004),
            bgColor: const Color(0xFFFCE8E6),
            icon: Icons.error_outline,
            iconBgColor: const Color(0xFFEE0004),
            alasan: 'Ada urusan keluarga di luar kota.',
            catatanAtasan: 'Ditolak karena kuota izin harian unit sudah penuh.',
          ),
          const SizedBox(height: 10),
          _buildIzinItem(
            context,
            title: 'Cuti Menikah',
            date: '10 Nov - 12 Nov 2023',
            status: 'DISETUJUHI',
            textColor: const Color(0xFF006C49),
            bgColor: const Color(0xFFE6F4EA),
            icon: Icons.favorite_outline,
            iconBgColor: const Color(0xFF006C49),
            alasan: 'Acara pernikahan pribadi.',
            catatanAtasan: 'Selamat dan semoga lancar.',
          ),
        ],
      ),
    );
  }

  Widget _buildIzinItem(
    BuildContext context, {
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
      onTap: () {
        Navigator.push(
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