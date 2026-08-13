<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Kehadiran extends Model
{
    use HasFactory;

    protected $table = 'kehadirans';

    protected $fillable = [
        'user_id',
        'tanggal',
        'waktu_masuk',
        'waktu_pulang',
        'foto_masuk',
        'foto_pulang',
        'latitude_masuk',
        'longitude_masuk',
        'latitude_pulang',
        'longitude_pulang',
        'status_kehadiran',
        'status_masuk',
    ];

    /**
     * Cast kolom datetime & date agar otomatis menjadi object Carbon
     */
    protected $casts = [
        'tanggal' => 'date',
        'waktu_masuk' => 'datetime',
        'waktu_pulang' => 'datetime',
    ];

    /**
     * Relasi ke model User
     */
    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'id');
    }
}