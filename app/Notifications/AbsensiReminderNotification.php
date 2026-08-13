<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class AbsensiReminderNotification extends Notification
{
    use Queueable;

    protected $title;
    protected $message;
    protected $type;

    public function __construct($title, $message, $type = 'absen_reminder')
    {
        $this->title = $title;
        $this->message = $message;
        $this->type = $type;
    }

    // Tentukan channel: disimpan ke Database + dikirim via FCM (Firebase)
    public function via($notifiable)
    {
        return ['database']; // Tambahkan 'fcm' jika sudah install package FCM Laravel
    }

    // Format yang disimpan di tabel database notifications
    public function toDatabase($notifiable)
    {
        return [
            'title' => $this->title,
            'message' => $this->message,
            'type' => $this->type,
        ];
    }
}
