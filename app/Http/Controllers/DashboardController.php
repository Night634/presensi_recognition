<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Kehadiran;
use App\Models\Pengajuan; // Pastikan Import Model Pengajuan Cuti Anda
use Carbon\Carbon;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index()
    {
        $today = Carbon::today()->format('Y-m-d');

        // 1. Akun Pegawai Terdaftar
        $totalPegawai = User::where('role', 'pegawai')->count();

        // 2. Total Pegawai Terlambat Hari Ini
        $totalTerlambat = Kehadiran::whereDate('waktu_masuk', $today)
            ->whereTime('waktu_masuk', '>', '08:00:00')
            ->count();

        // 3. Persetujuan Cuti / Pending Approval
        $persetujuanCuti = Pengajuan::where('status', 'PENDING')->count();

        // 4. Total Pegawai Aktif Cuti Hari Ini (Disetujui & Tanggal Berjalan)
        $totalPegawaiCuti = Pengajuan::where('status', 'DISETUJUHI')
            ->whereDate('dari_tanggal', '<=', $today)
            ->whereDate('sampai_tanggal', '>=', $today)
            ->count();

        // 5. Ambil 3 Aktivitas Presensi Terakhir
        $recentKehadiran = Kehadiran::with('user:id,name')
            ->orderBy('created_at', 'desc')
            ->take(3)
            ->get();

        $activities = $recentKehadiran->map(function ($item) {
            $nama = $item->user ? $item->user->name : 'Pegawai';
            $waktuMasuk = $item->waktu_masuk ? Carbon::parse($item->waktu_masuk) : null;
            
            $color = 'bg-emerald-600';
            $statusStr = 'Melakukan Presensi Tepat Waktu';

            if ($waktuMasuk) {
                $batasTepat = $waktuMasuk->copy()->setTime(8, 0, 0);
                $jamBuka = $waktuMasuk->copy()->setTime(6, 30, 0);

                if ($waktuMasuk->lessThan($jamBuka)) {
                    $color = 'bg-amber-400';
                    $statusStr = 'Melakukan Presensi Sebelum Jam Masuk';
                } elseif ($waktuMasuk->greaterThan($batasTepat)) {
                    $color = 'bg-red-500';
                    $statusStr = 'Melakukan Presensi Terlambat';
                }
            }

            return [
                'id' => $item->id,
                'color' => $color,
                'content' => "<strong>{$nama}</strong> {$statusStr}"
            ];
        });

        return response()->json([
            'total_pegawai' => $totalPegawai,
            'total_terlambat' => $totalTerlambat,
            'persetujuan_cuti' => $persetujuanCuti,
            'total_pegawai_cuti' => $totalPegawaiCuti,
            'activities' => $activities
        ]);
    }
}