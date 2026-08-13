<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Pengajuan extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'jenis_pengajuan',
        'dari_tanggal',
        'sampai_tanggal',
        'alasan',
        'lampiran',
        'status',
        'catatan_atasan',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}