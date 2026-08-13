<?php

namespace App\Http\Controllers;

use App\Models\Kehadiran;
use Carbon\Carbon;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index()
    {
        // Ambil data presensi yang usernya ber-role 'pegawai'
        $notifications = Kehadiran::with(['user' => function ($query) {
                $query->where('role', 'pegawai');
            }])
            ->whereHas('user', function ($query) {
                // Pastikan hanya ambil data dari user ber-role 'pegawai'
                $query->where('role', 'pegawai');
            })
            ->orderBy('created_at', 'desc')
            ->take(6)
            ->get()
            ->map(function ($item) {
                // Ambil waktu dari created_at atau waktu_masuk sebagai acuan
                $waktu = $item->created_at ?? $item->waktu_masuk ?? now();
                $formattedTime = Carbon::parse($waktu)->format('H:i');
                $timeAgo = Carbon::parse($waktu)->diffForHumans();

                // Tentukan kalimat aksi berdasarkan status
                $actionText = 'Melakukan presensi pada ' . $formattedTime;
                if ($item->status_kehadiran === 'terlambat') {
                    $actionText = 'Terlambat presensi (Masuk pukul ' . $formattedTime . ')';
                } elseif ($item->status_kehadiran === 'izin') {
                    $actionText = 'Mengajukan izin';
                }

                return [
                    'id' => $item->id,
                    'name' => $item->user ? $item->user->name : 'Pegawai',
                    'action' => $actionText,
                    'time' => $timeAgo,
                    'unread' => true,
                ];
            });

        return response()->json($notifications);
    }
}