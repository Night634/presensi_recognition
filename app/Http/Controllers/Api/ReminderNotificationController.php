<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class ReminderNotificationController extends Controller
{
    // 1. Get All Notifications untuk User yang Login
    public function index(Request $request)
    {
        $user = $request->user();
        
        $notifications = $user->notifications()->get()->map(function ($notif) {
            return [
                'id' => $notif->id,
                'title' => $notif->data['title'] ?? 'Pengingat',
                'message' => $notif->data['message'] ?? '',
                'read_at' => $notif->read_at,
                'created_at' => $notif->created_at->diffForHumans(),
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $notifications
        ]);
    }

    // 2. Simpan FCM Token Device dari Flutter
    public function updateFcmToken(Request $request)
    {
        $request->validate(['fcm_token' => 'required|string']);
        
        $request->user()->update([
            'fcm_token' => $request->fcm_token
        ]);

        return response()->json(['message' => 'FCM Token updated successfully']);
    }

    // 3. Hapus Notifikasi Spesifik
    public function destroy(Request $request, $id)
    {
        $notif = $request->user()->notifications()->find($id);

        if ($notif) {
            $notif->delete();
            return response()->json(['success' => true, 'message' => 'Notifikasi berhasil dihapus']);
        }

        return response()->json(['success' => false, 'message' => 'Notifikasi tidak ditemukan'], 404);
    }

    // 4. Hapus Semua Notifikasi User
    public function clearAll(Request $request)
    {
        $request->user()->notifications()->delete();
        return response()->json(['success' => true, 'message' => 'Semua notifikasi dibersihkan']);
    }
}