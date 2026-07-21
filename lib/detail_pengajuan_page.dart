import 'package:flutter/material.dart';

class DetailPengajuanPage extends StatefulWidget {
  final String title;
  final String date;
  final String status;
  final Color statusTextColor;
  final Color statusBgColor;
  final IconData icon;
  final Color iconBgColor;
  final String alasan;
  final String? catatanAtasan;
  final String? namaFile;

  const DetailPengajuanPage({
    super.key,
    required this.title,
    required this.date,
    required this.status,
    required this.statusTextColor,
    required this.statusBgColor,
    required this.icon,
    required this.iconBgColor,
    this.alasan = 'Urusan keluarga yang mendesak dan tidak dapat ditinggalkan.',
    this.catatanAtasan,
    this.namaFile = 'Surat_Keterangan_Dokumen.pdf',
  });

  @override
  State<DetailPengajuanPage> createState() => _DetailPengajuanPageState();
}

class _DetailPengajuanPageState extends State<DetailPengajuanPage> {
  late String _currentStatus;
  late Color _currentStatusTextColor;
  late Color _currentStatusBgColor;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.status;
    _currentStatusTextColor = widget.statusTextColor;
    _currentStatusBgColor = widget.statusBgColor;
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pengajuan?'),
        content: const Text('Apakah Anda yakin ingin membatalkan pengajuan ini? Data tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog konfirmasi
              setState(() {
                _currentStatus = 'DIBATALKAN';
                _currentStatusTextColor = const Color(0xFFDC2626);
                _currentStatusBgColor = const Color(0xFFFEE2E2);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pengajuan berhasil dibatalkan.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEE0004)),
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isPending = _currentStatus == 'PENDING';

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _currentStatus);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'Detail Pengajuan',
            style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context, _currentStatus),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Info Pengajuan
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: widget.iconBgColor,
                      child: Icon(widget.icon, size: 24, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.date,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _currentStatusBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _currentStatus,
                        style: TextStyle(color: _currentStatusTextColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card Rincian
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ALASAN / DESKRIPSI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF44474D))),
                    const SizedBox(height: 6),
                    Text(
                      widget.alasan,
                      style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                    ),
                    const Divider(height: 24),

                    const Text('LAMPIRAN PENDUKUNG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF44474D))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, color: Colors.red, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.namaFile ?? 'Tidak ada lampiran',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.download_rounded, color: Color(0xFF1D4ED8), size: 20),
                        ],
                      ),
                    ),

                    if (widget.catatanAtasan != null) ...[
                      const Divider(height: 24),
                      const Text('CATATAN ATASAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF44474D))),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _currentStatusBgColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: _currentStatusTextColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.catatanAtasan!,
                                style: TextStyle(fontSize: 12, color: _currentStatusTextColor, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // TOMBOL BATALKAN PENGAJUAN (Hanya Tampil saat PENDING)
              if (isPending)
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: _confirmCancel,
                    icon: const Icon(Icons.cancel_outlined, size: 18, color: Color(0xFFEE0004)),
                    label: const Text(
                      'Batalkan Pengajuan',
                      style: TextStyle(color: Color(0xFFEE0004), fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEE0004), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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