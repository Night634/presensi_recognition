<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('lokasi_kantor', function (Blueprint $table) {
            // Hapus kolom lama jika ada
            if (Schema::hasColumn('lokasi_kantor', 'latitude')) {
                $table->dropColumn(['latitude', 'longitude', 'radius_meter']);
            }
            
            // Tambahkan kolom coordinates untuk polygon
            if (!Schema::hasColumn('lokasi_kantor', 'coordinates')) {
                $table->json('coordinates')->after('nama_gedung');
            }
        });
    }

    public function down(): void
    {
        Schema::table('lokasi_kantor', function (Blueprint $table) {
            $table->dropColumn('coordinates');
            $table->string('latitude')->nullable();
            $table->string('longitude')->nullable();
            $table->integer('radius_meter')->nullable();
        });
    }
};