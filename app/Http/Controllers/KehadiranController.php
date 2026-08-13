<?php

namespace App\Http\Controllers;

use App\Models\Kehadiran;
use App\Models\LokasiKantor;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class KehadiranController extends Controller
{
    private function getNamaGedungByCoords($lat, $lng, $semuaLokasi)
    {
        if (!$lat || !$lng) return '-';

        $userLat = (float) $lat;
        $userLng = (float) $lng;

        foreach ($semuaLokasi as $lokasi) {
            $coords = $lokasi->coordinates;

            // Jika format string JSON, decode dulu
            if (is_string($coords)) {
                $coords = json_decode($coords, true);
            }

            if (!is_array($coords) || count($coords) < 3) continue;

            // Algoritma Point-in-Polygon
            $isInside = false;
            $j = count($coords) - 1;

            for ($i = 0; $i < count($coords); $i++) {
                $iLat = 0.0; $iLng = 0.0;
                $jLat = 0.0; $jLng = 0.0;

                // Parsing titik I
                if (is_array($coords[$i])) {
                    $iLat = (float) ($coords[$i][0] ?? $coords[$i]['lat'] ?? 0);
                    $iLng = (float) ($coords[$i][1] ?? $coords[$i]['lng'] ?? 0);
                }

                // Parsing titik J
                if (is_array($coords[$j])) {
                    $jLat = (float) ($coords[$j][0] ?? $coords[$j]['lat'] ?? 0);
                    $jLng = (float) ($coords[$j][1] ?? $coords[$j]['lng'] ?? 0);
                }

                $intersect = (($iLng > $userLng) != ($jLng > $userLng)) &&
                    ($userLat < ($jLat - $iLat) * ($userLng - $iLng) / (($jLng - $iLng) ?: 1) + $iLat);

                if ($intersect) $isInside = !$isInside;
                $j = $i;
            }

            if ($isInside) {
                return $lokasi->nama_gedung; // Kembalikan Nama Gedung jika koordinat di dalam polygon
            }
        }

        return 'Luar Area Kantor'; // Fallback jika koordinat tidak masuk ke polygon gedung manapun
    }

    // ===== GET ALL PRESENSI UNTUK VUE JS =====
    public function index()
    {
        $kehadirans = Kehadiran::with('user:id,name,nip')
            ->orderBy('created_at', 'desc')
            ->get();

        // Ambil semua data lokasi kantor sekaligus
        $semuaLokasi = LokasiKantor::all();

        // Append nama gedung masuk & keluar ke setiap record
        $kehadirans->transform(function ($item) use ($semuaLokasi) {
            $item->lokasi_masuk = $this->getNamaGedungByCoords(
                $item->latitude_masuk, 
                $item->longitude_masuk, 
                $semuaLokasi
            );

            $item->lokasi_keluar = $item->waktu_pulang 
                ? $this->getNamaGedungByCoords(
                    $item->latitude_pulang, 
                    $item->longitude_pulang, 
                    $semuaLokasi
                )
                : '-';

            return $item;
        });

        return response()->json($kehadirans);
    }    

    

    public function checkHariIni(Request $request)
    {
        $user = $request->user();
        $today = \Carbon\Carbon::now('Asia/Jakarta')->toDateString();

        $kehadiran = Kehadiran::where('user_id', $user->id)
            ->whereDate('tanggal', $today)
            ->first();

        return response()->json([
            'status' => 'success',
            'data'   => $kehadiran
        ]);
    }

    // POST: Endpoint presensi AI dari Flutter (/api/presensi)
    public function store(Request $request)
    {
        // 1. Dapatkan nama field file foto dari Flutter
        $photoField = $request->hasFile('image') ? 'image' : ($request->hasFile('foto') ? 'foto' : 'image');

        $request->validate([
            $photoField => 'required|image|mimes:jpeg,png,jpg|max:5000',
            'latitude'  => 'required',
            'longitude' => 'required',
        ]);

        $user  = $request->user();
        
        // --- PERBAIKAN 1: SET TIMEZONE SECARA EKSPLISIT KE WIB (Asia/Jakarta) ---
        $now   = Carbon::now('Asia/Jakarta');
        $today = $now->toDateString(); // Format: YYYY-MM-DD

        // ATURAN BATASAN WAKTU PRESENSI
        $jamBukaMasuk     = $now->copy()->setTime(6, 0, 0);
        $batasTepatWaktu = $now->copy()->setTime(10, 30, 0);
        $jamTutupMasuk   = $now->copy()->setTime(15, 30, 0); 

        $jamBukaPulang   = $now->copy()->setTime(16, 0, 0);
        $jamTutupPulang  = $now->copy()->setTime(23, 59, 59);

        // --- PERBAIKAN 2: QUERY PRESENSI HARI INI YANG LEBIH PRESISI ---
        // Cukup cek kolom 'tanggal' (atau 'created_at' yang di-cast ke timezone lokal)
        $kehadiranHariIni = Kehadiran::where('user_id', $user->id)
            ->whereDate('tanggal', $today)
            ->first();

        // Cek apakah user sudah presensi MASUK & PULANG pada hari ini
        // =========================================================
        // VALIDASI WAKTU OPERASIONAL PRESENSI
        // =========================================================
        if (!$kehadiranHariIni) {
            // JIKA BELUM ABSEN MASUK SAMA SEKALI
            if ($now->lessThan($jamBukaMasuk) || $now->greaterThan($jamTutupMasuk)) {
                return response()->json([
                    'message' => 'Presensi masuk hanya dibuka dari jam 06:00 sampai 15:00 WIB!'
                ], 422);
            }
        } else {
            // JIKA SUDAH ABSEN MASUK DAN MENCOBA ABSEN LAGI

            // Kondisi A: Belum masuk jam pulang (Misal: dicoba lagi jam 08:30 s/d 14:59)
            if ($now->lessThan($jamBukaPulang)) {
                return response()->json([
                    'message' => 'Anda sudah melakukan presensi masuk hari ini! Presensi pulang baru dibuka pukul 15:00 WIB.'
                ], 422);
            }

            // Kondisi B: Sudah lewat batas akhir jam pulang (Misal: dicoba jam 00:00 malam)
            if ($now->greaterThan($jamTutupPulang)) {
                return response()->json([
                    'message' => 'Waktu presensi pulang untuk hari ini telah berakhir (Batas: 23:59 WIB)!'
                ], 422);
            }
        }

        // 2. ATURAN VERIFIKASI WAJAH AI
        if (!$user->face_embedding) {
            return response()->json([
                'message' => 'Wajah Anda belum terdaftar di sistem. Hubungi Admin!'
            ], 422);
        }

        $colabUrl = config('services.colab.url') ?? env('COLAB_URL');
        if (!$colabUrl) {
            return response()->json([
                'status' => 'error',
                'message' => 'Key COLAB_URL belum diset di file .env!'
            ], 500);
        }

        $colabUrl = rtrim($colabUrl, '/');

        $rawEmbedding = $user->face_embedding;
        $embeddingString = is_string($rawEmbedding)
            ? $rawEmbedding
            : json_encode($rawEmbedding);

        try {
            // Tembak API Colab via Ngrok
            $response = Http::withoutVerifying()
                ->timeout(60)
                ->withHeaders([
                    'ngrok-skip-browser-warning' => 'true',
                    'Accept'                     => 'application/json',
                ])
                ->attach(
                    'file', 
                    file_get_contents($request->file($photoField)->getRealPath()), 
                    'foto.jpg'
                )
                ->post($colabUrl . '/compare-embedding', [
                    'registered_embedding' => $embeddingString,
                ]);

            if (!$response->successful()) {
                Log::error('Colab Error Response [' . $response->status() . ']: ' . $response->body());
                return response()->json([
                    'message' => 'Gagal memproses AI wajah!',
                    'detail' => $response->body()
                ], 500);
            }

            $resData = $response->json();
            
            if (!isset($resData['is_match']) || $resData['is_match'] !== true) {
                $distance = $resData['distance'] ?? 'N/A';
                Log::warning("Face match failed for User {$user->id}. Distance: {$distance}");

                return response()->json([
                    'message' => 'Verifikasi Wajah Gagal! Wajah tidak cocok dengan data pegawai.'
                ], 422);
            }

        } catch (\Exception $e) {
            Log::error('Exception AI Colab: ' . $e->getMessage());
            return response()->json(['message' => 'Gagal terhubung ke Server AI: ' . $e->getMessage()], 500);
        }

        // 3. PROSES SIMPAN FOTO KE STORAGE LOCAL
        $file = $request->file($photoField);
        $fileName = time() . '_' . $user->id . '_' . $file->getClientOriginalName();
        $filePath = 'presensi/' . $fileName;

        Storage::disk('public')->put($filePath, file_get_contents($file->getRealPath()));
        $photoUrl = asset('storage/' . $filePath);

        // 4. CATAT KEHADIRAN KE DATABASE (MASUK / PULANG)
        $isOutOfOffice = $request->boolean('is_outside_office', false);

        if (!$kehadiranHariIni) {
            $statusMasuk = $now->greaterThan($batasTepatWaktu) ? 'Terlambat' : 'Tepat Waktu';

            $kehadiran = Kehadiran::create([
                'user_id'          => $user->id,
                'tanggal'          => $today,
                'waktu_masuk'      => $now,
                'foto_masuk'       => $photoUrl,
                'status_kehadiran' => 'Hadir',
                'status_masuk'     => $statusMasuk,
                'latitude_masuk'   => $request->latitude,
                'longitude_masuk'  => $request->longitude,
                // (Opsional) tambahkan field 'keterangan' jika ada di DB:
                // 'keterangan'    => $isOutOfOffice ? 'Presensi Diluar Kantor' : 'Presensi Di Kantor',
            ]);

            return response()->json([
                'status'          => 'success',
                'message'         => $isOutOfOffice 
                                    ? 'Presensi Masuk Berhasil (Peringatan: Berada Diluar Wilayah Kantor)!' 
                                    : 'Presensi Masuk Berhasil!',
                'user_name'       => $user->name,
                'data_id'         => $kehadiran->id,
                'type'            => 'masuk',
                'is_out_of_office' => $isOutOfOffice,
            ], 200);

        } else {
            // Eksekusi Update Presensi Pulang
            $kehadiranHariIni->update([
                'waktu_pulang'     => $now,
                'foto_pulang'      => $photoUrl,
                'latitude_pulang'  => $request->latitude,
                'longitude_pulang' => $request->longitude,
            ]);

            return response()->json([
                'status'          => 'success',
                'message'         => $isOutOfOffice 
                                    ? 'Presensi Pulang Berhasil (Peringatan: Berada Diluar Wilayah Kantor)!' 
                                    : 'Presensi Pulang Berhasil!',
                'user_name'       => $user->name,
                'data_id'         => $kehadiranHariIni->id,
                'type'            => 'pulang',
                'is_out_of_office' => $isOutOfOffice,
            ], 200);
        }
    }

    public function summary(Request $request)
    {
        $user = $request->user();
        $now = Carbon::now('Asia/Jakarta');

        // Hitung total statistik bulan berjalan
        $hadir = Kehadiran::where('user_id', $user->id)
            ->whereYear('tanggal', $now->year)
            ->whereMonth('tanggal', $now->month)
            ->where('status_kehadiran', 'Hadir')
            ->count();

        $terlambat = Kehadiran::where('user_id', $user->id)
            ->whereYear('tanggal', $now->year)
            ->whereMonth('tanggal', $now->month)
            ->where('status_masuk', 'Terlambat')
            ->count();

        $izin = Kehadiran::where('user_id', $user->id)
            ->whereYear('tanggal', $now->year)
            ->whereMonth('tanggal', $now->month)
            ->whereIn('status_kehadiran', ['Izin', 'Cuti', 'Sakit'])
            ->count();

        // Ambil 3 data presensi terakhir
        $recent = Kehadiran::where('user_id', $user->id)
            ->orderBy('tanggal', 'desc')
            ->orderBy('created_at', 'desc')
            ->limit(3)
            ->get()
            ->map(function ($item) {
                $tgl = $item->tanggal ? Carbon::parse($item->tanggal)->locale('id') : Carbon::parse($item->created_at)->locale('id');
                $masuk = $item->waktu_masuk ? Carbon::parse($item->waktu_masuk)->timezone('Asia/Jakarta') : null;
                $pulang = $item->waktu_pulang ? Carbon::parse($item->waktu_pulang)->timezone('Asia/Jakarta') : null;

                return [
                    'id' => $item->id,
                    'tanggal_formatted' => $tgl->isoFormat('dddd, DD MMM YYYY'),
                    'waktu_masuk' => $masuk ? $masuk->format('H:i') . ' WIB' : '--:--',
                    'waktu_pulang' => $pulang ? $pulang->format('H:i') . ' WIB' : '--:--',
                    'status_masuk' => strtoupper($item->status_masuk ?? 'MASUK'),
                    'is_late' => strtolower($item->status_masuk ?? '') === 'terlambat',
                ];
            });

        return response()->json([
            'status' => 'success',
            'summary' => [
                'hadir' => $hadir,
                'total_hari_kerja' => 22,
                'terlambat' => $terlambat,
                'izin' => $izin,
            ],
            'recent' => $recent
        ]);
    }

    /**
     * Endpoint untuk RiwayatPage Flutter
     */
    public function history(Request $request)
    {
        $user = $request->user();
        $month = $request->query('month', Carbon::now('Asia/Jakarta')->month);
        $year = $request->query('year', Carbon::now('Asia/Jakarta')->year);

        $semuaLokasi = LokasiKantor::all();

        $kehadirans = Kehadiran::where('user_id', $user->id)
            ->whereYear('tanggal', $year)
            ->whereMonth('tanggal', $month)
            ->orderBy('tanggal', 'desc')
            ->orderBy('created_at', 'desc')
            ->get();

        $hadir = $kehadirans->where('status_kehadiran', 'Hadir')->count();
        $terlambat = $kehadirans->where('status_masuk', 'Terlambat')->count();
        $izin = $kehadirans->whereIn('status_kehadiran', ['Izin', 'Cuti', 'Sakit'])->count();

        $historyData = $kehadirans->map(function ($item) use ($semuaLokasi) {
            $tgl = $item->tanggal ? Carbon::parse($item->tanggal)->locale('id') : Carbon::parse($item->created_at)->locale('id');
            $clockIn = $item->waktu_masuk ? Carbon::parse($item->waktu_masuk)->timezone('Asia/Jakarta') : null;
            $clockOut = $item->waktu_pulang ? Carbon::parse($item->waktu_pulang)->timezone('Asia/Jakarta') : null;

            // Hitung Durasi Kerja
            $durationStr = '-';
            if ($clockIn && $clockOut) {
                $diffInMinutes = $clockIn->diffInMinutes($clockOut);
                $jam = floor($diffInMinutes / 60);
                $menit = $diffInMinutes % 60;
                $durationStr = sprintf('%02dj %02dm', $jam, $menit);
            }

            // Nama Lokasi Gedung
            $lokasi = $this->getNamaGedungByCoords($item->latitude_masuk, $item->longitude_masuk, $semuaLokasi);

            $status = strtoupper($item->status_masuk === 'Terlambat' ? 'TERLAMBAT' : ($item->status_kehadiran ?? 'HADIR'));

            return [
                'id' => $item->id,
                'day_number' => (int) $tgl->format('j'),
                'date' => $tgl->isoFormat('dddd, DD MMM'),
                'location' => $lokasi !== '-' ? $lokasi : 'Kemensetneg',
                'status' => $status,
                'clockIn' => $clockIn ? $clockIn->format('H:i') : '--:--',
                'clockOut' => $clockOut ? $clockOut->format('H:i') : '--:--',
                'duration' => $durationStr,
                'note' => $item->status_masuk === 'Terlambat' ? 'Terlambat masuk dari jadwal.' : null,
            ];
        })->values();

        return response()->json([
            'status' => 'success',
            'summary' => [
                'hadir' => $hadir,
                'terlambat' => $terlambat,
                'izin' => $izin,
            ],
            'data' => $historyData
        ]);
    }
}