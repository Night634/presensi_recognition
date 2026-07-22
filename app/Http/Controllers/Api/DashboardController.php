<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class DashboardController extends Controller
{
    public function stats()
    {
        try {
            // 1. Hitung Total User langsung dari Model User (Pasti dapat angka 2)
            $totalPegawai = User::where('role', 'pegawai')->count();

            // 2. Hitung Terlambat (Cek dulu apakah tabel kehadirans ada)
            $totalTerlambat = 0;
            if (Schema::hasTable('kehadirans')) {
                $totalTerlambat = DB::table('kehadirans')
                    ->whereDate('created_at', now()->toDateString())
                    ->where('status_kehadiran', 'LIKE', '%TERLAMBAT%')
                    ->count();
            }

            // 3. Hitung Pending Cuti (Cek tabel pengajuan_izins)
            $pendingCuti = 0;
            $approvedCuti = 0;
            if (Schema::hasTable('pengajuan_izins')) {
                $pendingCuti = DB::table('pengajuan_izins')->where('status', 'PENDING')->count();
                $approvedCuti = DB::table('pengajuan_izins')->where('status', 'APPROVED')->count();
            }

            // 4. Hitung Aktivitas Terakhir
            $activities = [];
            if (Schema::hasTable('kehadirans')) {
                $activities = DB::table('kehadirans')
                    ->leftJoin('users', 'kehadirans.user_id', '=', 'users.id')
                    ->select('kehadirans.*', 'users.name as user_name')
                    ->latest('kehadirans.created_at')
                    ->take(5)
                    ->get()
                    ->map(function ($item) {
                        $nama = $item->user_name ?? 'Pegawai';
                        $status = $item->status_kehadiran ?? 'Presensi';
                        $waktu = \Carbon\Carbon::parse($item->created_at)->diffForHumans();
                        $isTerlambat = str_contains(strtoupper($status), 'TERLAMBAT');

                        return [
                            'id' => $item->id,
                            'color' => $isTerlambat ? 'bg-amber-400' : 'bg-emerald-600',
                            'content' => "<strong>{$nama}</strong> melakukan presensi ({$status}) - <span class='text-gray-400 text-xs'>{$waktu}</span>"
                        ];
                    });
            }

            return response()->json([
                'status' => 'success',
                'data' => [
                    'total_pegawai'   => $totalPegawai,
                    'total_terlambat' => $totalTerlambat,
                    'pending_cuti'    => $pendingCuti,
                    'approved_cuti'   => $approvedCuti,
                    'activities'      => $activities,
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status'  => 'error',
                'message' => $e->getMessage()
            ], 500);
        }
    }
}