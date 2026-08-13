<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Hanya tambah kolom foto karena face_embedding sudah ada
            if (!Schema::hasColumn('users', 'foto')) {
                $table->string('foto')->nullable()->after('status_aktif');
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['foto']);
        });
    }
};