<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Tambah kolom pendukung radius pada lokasi_kantor jika disetujui
        Schema::table('lokasi_kantor', function (Blueprint $table) {
            if (!Schema::hasColumn('lokasi_kantor', 'tipe')) {
                $table->enum('tipe', ['polygon', 'radius'])->default('polygon')->after('id');
                $table->decimal('latitude', 10, 8)->nullable()->after('coordinates');
                $table->decimal('longitude', 11, 8)->nullable()->after('latitude');
                $table->integer('radius_meter')->nullable()->default(30)->after('longitude');
            }
        });

        // 2. Tabel Pengajuan Lokasi dari Pegawai Mobile
        Schema::create('pengajuan_lokasi', function (Blueprint $table) {
            $table->id();
            $table->string('nama_gedung');
            $table->string('nama_pengaju');
            $table->string('nip_pengaju');
            $table->decimal('latitude', 10, 8);
            $table->decimal('longitude', 11, 8);
            $table->integer('radius_meter')->default(30);
            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->text('alasan_penolakan')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pengajuan_lokasi');
        Schema::table('lokasi_kantor', function (Blueprint $table) {
            $table->dropColumn(['tipe', 'latitude', 'longitude', 'radius_meter']);
        });
    }
};