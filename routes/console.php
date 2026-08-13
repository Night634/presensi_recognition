<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;
use App\Models\User;
use App\Models\Presensi; // Model absensi kamu
use App\Notifications\AbsensiReminderNotification;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// 1. Pengingat Jam Absen Masuk (Misal Jam 08:00)
Schedule::call(function () {
    $today = now()->toDateString();
    
    // Cari user yang BELUM absen hari ini
    $usersBelumAbsen = User::whereDoesntHave('presensis', function($q) use ($today) {
        $q->whereDate('created_at', $today);
    })->get();

    foreach ($usersBelumAbsen as $user) {
        $user->notify(new AbsensiReminderNotification(
            'Waktunya Absen Masuk! ⏰',
            'Halo, jangan lupa untuk melakukan absen masuk hari ini ya.'
        ));
    }
})->dailyAt('08:00');

// 2. Warning 10 Menit Sebelum Absen Masuk Ditutup (Misal Jam 08:50)
Schedule::call(function () {
    $today = now()->toDateString();

    $usersBelumAbsen = User::whereDoesntHave('presensis', function($q) use ($today) {
        $q->whereDate('created_at', $today);
    })->get();

    foreach ($usersBelumAbsen as $user) {
        $user->notify(new AbsensiReminderNotification(
            'Peringatan Absen Masuk! ⚠️',
            'Batas waktu absen masuk tinggal 10 menit lagi (09:00)! Segera lakukan absen.'
        ));
    }
})->dailyAt('08:50');