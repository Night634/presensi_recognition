import { ref } from 'vue'
import axios from 'axios'

// PERTAHANKAN SEMUA ENDPOINT KAMU
const notificationEndpoints = [
  'http://localhost:8000/api/notifications',
  'http://localhost:8000/api/notifikasi',
  'http://127.0.0.1:8000/api/notifications',
  'http://127.0.0.1:8000/api/notifikasi',
]

const notifications = ref([])

const getAuthHeader = () => {
  const token = sessionStorage.getItem('admin_token') || localStorage.getItem('token')
  return {
    headers: {
      Authorization: `Bearer ${token}`
    }
  }
}

const formatNotificationTime = (value) => {
  if (!value) return 'baru'
  if (typeof value === 'string') {
    const trimmed = value.trim()
    if (!trimmed) return 'baru'
    if (/^\d{4}-\d{2}-\d{2}/.test(trimmed)) {
      return trimmed.split('T')[0]
    }
    return trimmed
  }
  return String(value)
}

const normalizeNotifications = (payload) => {
  if (Array.isArray(payload)) return payload.map((item, index) => normalizeNotification(item, index))

  if (payload && typeof payload === 'object') {
    if (Array.isArray(payload.data)) return payload.data.map((item, index) => normalizeNotification(item, index))
    if (Array.isArray(payload.notifications)) return payload.notifications.map((item, index) => normalizeNotification(item, index))
    if (Array.isArray(payload.result)) return payload.result.map((item, index) => normalizeNotification(item, index))
  }

  return []
}

const normalizeNotification = (item, index) => {
  const name = item?.name || item?.nama || item?.user_name || item?.sender_name || item?.pegawai_name || 'Sistem'
  const action = item?.message || item?.action || item?.deskripsi || item?.title || item?.type || 'Ada aktivitas terbaru'
  const time = formatNotificationTime(item?.time || item?.created_at || item?.createdAt || item?.tanggal || item?.updated_at)
  const unread = item?.unread ?? (item?.is_read === false) ?? (item?.read_at === null)

  return {
    id: item?.id ?? index + 1,
    name,
    action,
    time,
    unread,
  }
}

export function useNotifications() {
  // Hanya 1 deklarasi fetchNotifications (mencoba endpoint list kamu & menggunakan normalizer)
  const fetchNotifications = async () => {
    let success = false
    
    // Coba tembak endpoint satu per satu sampai berhasil
    for (const endpoint of notificationEndpoints) {
      try {
        const res = await axios.get(endpoint, getAuthHeader())
        // Memakai fungsi normalizeNotifications buatanmu agar data selalu rapi
        notifications.value = normalizeNotifications(res.data)
        success = true
        break // Keluar loop jika sukses
      } catch (error) {
        // Lanjut mencoba endpoint berikutnya
      }
    }

    if (!success) {
      console.error('Gagal mengambil notifikasi dari seluruh endpoint.')
    }
  }

  // Hapus SATU notifikasi
  const removeNotification = (id) => {
    notifications.value = notifications.value.filter(item => item.id !== id)
  }

  // Hapus SEMUA notifikasi
  const clearAllNotif = () => {
    notifications.value = []
  }

  return {
    notifications,
    fetchNotifications,
    removeNotification,
    clearAllNotif
  }
}