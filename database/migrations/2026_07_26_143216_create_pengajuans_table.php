<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('pengajuans', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->string('jenis_pengajuan'); // Cuti, Izin, Sakit
            $table->date('dari_tanggal');
            $table->date('sampai_tanggal');
            $table->text('alasan');
            $table->string('lampiran')->nullable();
            $table->enum('status', ['PENDING', 'DISETUJUI', 'DITOLAK', 'DIBATALKAN'])->default('PENDING');
            $table->text('catatan_atasan')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void {
        Schema::dropIfExists('pengajuans');
    }
};