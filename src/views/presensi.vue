<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'
import logoSetneg from '../assets/logosetneg.png'
import * as XLSX from 'xlsx'
import { useNotifications } from '../composables/useNotifications'
import { 
  LayoutGrid, Users, Scan, CalendarCheck, MapPin, LogOut, Bell, Search, 
  ArrowUpDown, ChevronLeft, ChevronRight, Menu, X, User, Download
} from 'lucide-vue-next'

const router = useRouter()
const API_URL = 'http://localhost:8000/api/kehadiran'

const getAuthHeader = () => ({
  headers: { Authorization: `Bearer ${sessionStorage.getItem('admin_token')}` }
})

const isSidebarOpen = ref(false)
const isNotifOpen = ref(false)
const isLoading = ref(false)
const searchQuery = ref('')
const currentPage = ref(1)
const pageSize = ref(6)
const activeMenu = ref('Presensi')

const presensiList = ref([])
const { notifications, fetchNotifications, removeNotification, clearAllNotif } = useNotifications()
const selectedTimeFilter = ref('all')

const jakartaDateFormatter = new Intl.DateTimeFormat('en-CA', {
  timeZone: 'Asia/Jakarta',
  year: 'numeric',
  month: '2-digit',
  day: '2-digit'
})
const jakartaTimeFormatter = new Intl.DateTimeFormat('en-GB', {
  timeZone: 'Asia/Jakarta',
  hour12: false,
  hour: '2-digit',
  minute: '2-digit',
  second: '2-digit'
})
const jakartaWeekdayFormatter = new Intl.DateTimeFormat('en-US', {
  timeZone: 'Asia/Jakarta',
  weekday: 'short'
})

const parseJakartaDate = (rawValue) => {
  if (!rawValue) return null
  if (rawValue instanceof Date) return rawValue

  let value = String(rawValue).trim()

  if (/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    value = `${value}T00:00:00+07:00`
  } else if (/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/.test(value)) {
    value = value.replace(' ', 'T') + '+07:00'
  } else if (/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$/.test(value)) {
    value = `${value}+07:00`
  }

  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? null : date
}

const formatJakartaDate = (rawValue) => {
  const date = parseJakartaDate(rawValue)
  return date ? jakartaDateFormatter.format(date) : (rawValue || '-')
}

const formatJakartaTime = (rawValue) => {
  const date = parseJakartaDate(rawValue)
  if (date) return jakartaTimeFormatter.format(date)

  if (!rawValue) return '-'
  if (typeof rawValue === 'string' && rawValue.includes('T')) return rawValue.split('T')[1].slice(0, 8)
  if (typeof rawValue === 'string' && rawValue.includes(' ')) return rawValue.split(' ')[1]
  return rawValue
}

const getJakartaDayInfo = (rawValue) => {
  const date = parseJakartaDate(rawValue)
  if (!date) return null
  return {
    dateString: jakartaDateFormatter.format(date),
    weekday: jakartaWeekdayFormatter.format(date)
  }
}

const getUtcDayIndex = (dateString) => Math.floor(new Date(`${dateString}T00:00:00Z`).getTime() / 86400000)

const isWithinSelectedTimeFilter = (rawValue, filter) => {
  if (filter === 'all') return true
  const valueInfo = getJakartaDayInfo(rawValue)
  if (!valueInfo) return false

  const todayInfo = getJakartaDayInfo(new Date())
  if (!todayInfo) return false

  if (filter === 'today') {
    return valueInfo.dateString === todayInfo.dateString
  }

  if (filter === 'month') {
    return valueInfo.dateString.slice(0, 7) === todayInfo.dateString.slice(0, 7)
  }

  if (filter === 'week') {
    const targetIndex = getUtcDayIndex(valueInfo.dateString)
    const currentIndex = getUtcDayIndex(todayInfo.dateString)
    const currentWeekday = new Date(`${todayInfo.dateString}T00:00:00Z`).getUTCDay()
    const mondayIndex = currentIndex - ((currentWeekday + 6) % 7)
    const sundayIndex = mondayIndex + 6
    return targetIndex >= mondayIndex && targetIndex <= sundayIndex
  }

  return true
}

const toggleNotifications = async () => {
  isNotifOpen.value = !isNotifOpen.value
  if (isNotifOpen.value) {
    await fetchNotifications()
  }
}

// Fetch Data Presensi dari Backend
const fetchPresensi = async () => {
  isLoading.value = true
  try {
    const res = await axios.get(`${API_URL}?filter=${selectedTimeFilter.value}`, getAuthHeader())
    
    let rawData = []
    if (Array.isArray(res.data)) {
      rawData = res.data
    } else if (res.data && Array.isArray(res.data.data)) {
      rawData = res.data.data
    }

    // Mapping Data Berdasarkan Kolom Backend
    presensiList.value = rawData.map(item => ({
    id: item.id,
    nama: item.user ? item.user.name : (item.nama || '-'),
    nip: item.user ? item.user.nip : (item.nip || '-'),
    sourceDate: item.created_at || item.tanggal || item.waktu_masuk,
    tanggal: formatJakartaDate(item.created_at || item.tanggal || item.waktu_masuk),
    
    // JAM & LOKASI MASUK
    jam_masuk: formatJakartaTime(item.waktu_masuk),
    lokasi_masuk: item.lokasi_masuk || '-', // <--- Langsung berisi Nama Gedung dari DB
    status_masuk: item.status_masuk || item.status || '-',
    
    // JAM & LOKASI KELUAR
    jam_keluar: item.waktu_pulang ? formatJakartaTime(item.waktu_pulang) : '-',
    lokasi_keluar: item.lokasi_keluar || '-', // <--- Langsung berisi Nama Gedung dari DB
    status_pulang: item.status_pulang || item.status_kehadiran || '-'
  }))

  } catch (error) {
    console.error('Gagal mengambil data presensi:', error)
    presensiList.value = []
  } finally {
    isLoading.value = false
  }
}

const getBadgeClass = (status) => {
  const cleanStatus = status.toLowerCase()
  if (cleanStatus.includes('tepat')) return 'bg-emerald-100 text-emerald-700 border border-emerald-200'
  if (cleanStatus.includes('lambat')) return 'bg-red-100 text-red-700 border border-red-200'
  if (cleanStatus.includes('cepat')) return 'bg-amber-100 text-amber-700 border border-amber-200'
  return 'bg-gray-100 text-gray-700 border border-gray-200'
}

watch(selectedTimeFilter, () => {
  currentPage.value = 1
  fetchPresensi()
})

const exportToExcel = () => {
  if (filteredPresensi.value.length === 0) {
    alert('Tidak ada data presensi untuk diexport.')
    return
  }

  const exportData = filteredPresensi.value.map((item, index) => ({
    No: index + 1,
    Nama: item.nama,
    NIP: item.nip,
    Tanggal: item.tanggal,
    'Jam Masuk': item.jam_masuk,
    'Lokasi Masuk': item.lokasi_masuk,
    'Status Masuk': item.status_masuk,
    'Jam Keluar': item.jam_keluar,
    'Lokasi Keluar': item.lokasi_keluar,
    'Status Pulang': item.status_pulang
  }))

  const worksheet = XLSX.utils.json_to_sheet(exportData)
  const workbook = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(workbook, worksheet, 'Data Presensi')
  XLSX.writeFile(workbook, `Rekap_Presensi_${new Date().toISOString().slice(0,10)}.xlsx`)
}

const filteredPresensi = computed(() => {
  return presensiList.value
    .filter(item => isWithinSelectedTimeFilter(item.sourceDate, selectedTimeFilter.value))
    .filter(item => 
      (item.nama && item.nama.toLowerCase().includes(searchQuery.value.toLowerCase())) ||
      (item.nip && item.nip.includes(searchQuery.value))
    )
})

const totalPages = computed(() => Math.max(1, Math.ceil(filteredPresensi.value.length / pageSize.value)))
const paginatedPresensi = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  return filteredPresensi.value.slice(start, start + pageSize.value)
})
const displayFrom = computed(() => filteredPresensi.value.length === 0 ? 0 : (currentPage.value - 1) * pageSize.value + 1)
const displayTo = computed(() => Math.min(filteredPresensi.value.length, currentPage.value * pageSize.value))

watch(searchQuery, () => { currentPage.value = 1 })

const goToPrev = () => { if (currentPage.value > 1) currentPage.value -= 1 }
const goToNext = () => { if (currentPage.value < totalPages.value) currentPage.value += 1 }

const navItems = [
  { name: 'Dashboard', icon: LayoutGrid, route: 'Dashboard' },
  { name: 'Pegawai', icon: Users, route: 'Pegawai' },
  { name: 'Presensi', icon: Scan, route: 'Presensi' },
  { name: 'Cuti', icon: CalendarCheck, route: 'Cuti' },
  { name: 'Lokasi', icon: MapPin, route: 'Lokasi' },
]

const navigateTo = (item) => {
  activeMenu.value = item.name
  isSidebarOpen.value = false
  router.push({ name: item.route })
}

const handleLogout = () => {
  sessionStorage.clear()
  router.replace({ name: 'Login' })
}

onMounted(() => {
  fetchPresensi()
  fetchNotifications()
})
</script>

<template>
  <div class="flex h-screen bg-[#F0F4F8] font-sans text-gray-900 overflow-hidden relative">
    
    <div v-if="isSidebarOpen" @click="isSidebarOpen = false" class="fixed inset-0 bg-black/40 backdrop-blur-xs z-40 lg:hidden"></div>

    <!-- SIDEBAR -->
    <aside :class="['fixed lg:static inset-y-0 left-0 w-64 bg-white border-r border-gray-200 flex flex-col justify-between z-40 transition-transform duration-300 ease-in-out shrink-0', isSidebarOpen ? 'translate-x-0 shadow-2xl' : '-translate-x-full lg:translate-x-0']">
      <div>
        <div class="h-16 flex items-center justify-between px-6 border-b border-gray-100">
          <div class="flex items-center space-x-3">
            <div class="w-7 h-7 rounded-full bg-blue-600 flex items-center justify-center text-white font-bold text-xs">P</div>
            <span class="font-bold text-sm text-gray-800">Admin Portal</span>
          </div>
          <button @click="isSidebarOpen = false" class="lg:hidden text-gray-500"><X class="w-6 h-6" /></button>
        </div>
        <nav class="mt-4 px-4 space-y-1.5">
          <button v-for="item in navItems" :key="item.name" @click="navigateTo(item)" :class="['w-full flex items-center justify-between px-4 py-3 rounded-xl transition-all duration-150', activeMenu === item.name ? 'text-blue-600 bg-blue-50/60 font-semibold' : 'text-gray-600 hover:bg-gray-50']">
            <div class="flex items-center space-x-3.5">
              <component :is="item.icon" :class="['w-5 h-5', activeMenu === item.name ? 'text-blue-600' : 'text-gray-500']" stroke-width="2" />
              <span class="text-sm">{{ item.name }}</span>
            </div>
            <div v-if="activeMenu === item.name" class="w-1.5 h-6 bg-blue-600 rounded-full"></div>
          </button>
        </nav>
      </div>
      <div class="p-4 border-t border-gray-100">
        <button @click="handleLogout" class="flex items-center space-x-3.5 px-4 py-3 text-sm font-semibold text-red-600 hover:bg-red-50 rounded-xl w-full transition">
          <LogOut class="w-5 h-5" stroke-width="2" />
          <span>Keluar</span>
        </button>
      </div>
    </aside>

    <!-- MAIN CONTAINER -->
    <div class="flex-1 flex flex-col min-w-0 h-full overflow-hidden">
      <!-- HEADER -->
      <header class="h-16 bg-white border-b border-gray-200 flex items-center justify-between px-4 sm:px-8 z-30 shrink-0">
        <div class="flex items-center space-x-3">
          <button @click="isSidebarOpen = true" class="p-2 -ml-2 text-gray-600 lg:hidden"><Menu class="w-6 h-6" /></button>
          <div class="flex items-center space-x-3">
            <div class="w-8 h-8 bg-white flex items-center justify-center">
              <img :src="logoSetneg" alt="Logo Setneg" class="w-full h-full object-cover" />
            </div>
            <span class="font-bold text-xs uppercase tracking-wide text-gray-800">Kementerian Sekretariat Negara Republik Indonesia</span>
          </div>
        </div>
        <button @click="toggleNotifications" class="p-2 text-gray-700 hover:bg-gray-100 rounded-full transition relative"><Bell class="w-6 h-6" /></button>
      </header>

      <!-- BODY -->
      <main class="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8 space-y-6">
        <div>
          <p class="text-xs font-semibold text-gray-400 mb-1">Hello, Admin</p>
          <h1 class="text-2xl font-bold text-gray-950">Welcome to List Presensi!</h1>
        </div>

        <div class="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4">
          <div class="flex flex-col sm:flex-row items-center gap-3 w-full sm:w-auto">
            <div class="relative w-full sm:w-72">
              <input v-model="searchQuery" type="text" placeholder="Cari nama atau NIP..." class="w-full bg-white border border-gray-200 rounded-xl pl-4 pr-10 py-2.5 text-sm text-gray-700 focus:outline-none" />
              <Search class="w-4 h-4 text-gray-400 absolute right-3.5 top-1/2 -translate-y-1/2" />
            </div>
            <select v-model="selectedTimeFilter" class="w-full sm:w-auto bg-white border border-gray-200 rounded-xl px-4 py-2.5 text-sm font-semibold text-gray-700 focus:outline-none">
              <option value="all">Semua Waktu</option>
              <option value="today">Hari Ini</option>
              <option value="week">Minggu Ini</option>
              <option value="month">Bulan Ini</option>
            </select>
          </div>

          <button @click="exportToExcel" class="bg-emerald-600 hover:bg-emerald-700 text-white font-semibold text-sm px-5 py-2.5 rounded-xl transition flex items-center justify-center space-x-2">
            <Download class="w-4 h-4" />
            <span>Export Excel</span>
          </button>
        </div>

        <!-- TABLE DATA PRESENSI -->
        <div class="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse min-w-[900px]">
              <thead>
                <tr class="border-b border-gray-100 text-xs font-bold text-gray-800 bg-white">
                  <th class="py-4 px-6 text-center w-16">No</th>
                  <th class="py-4 px-6">
                    <div class="flex items-center space-x-1.5 cursor-pointer">
                      <span>Nama Pegawai</span>
                      <ArrowUpDown class="w-3.5 h-3.5 text-gray-400" />
                    </div>
                  </th>
                  <th class="py-4 px-6">Jam Masuk</th>
                  <th class="py-4 px-6">Lokasi Masuk</th>
                  <th class="py-4 px-6">Status Masuk</th>
                  <th class="py-4 px-6">Jam Keluar</th>
                  <th class="py-4 px-6">Lokasi Keluar</th>
                  <th class="py-4 px-6">Status Keluar</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100 text-sm font-medium text-gray-800">
                <tr v-for="(item, index) in paginatedPresensi" :key="item.id" class="hover:bg-gray-50/80 transition">
                  <td class="py-4 px-6 text-center text-gray-500">{{ displayFrom + index }}</td>
                  
                  <td class="py-4 px-6">
                    <div class="font-bold text-gray-900">{{ item.nama }}</div>
                    <div class="text-[11px] text-gray-400 font-normal">NIP: {{ item.nip }} | {{ item.tanggal }}</div>
                  </td>

                  <td class="py-4 px-6 font-semibold text-gray-700">{{ item.jam_masuk }}</td>
                  <td class="py-4 px-6 text-xs text-gray-600 max-w-[150px] truncate" :title="item.lokasi_masuk">{{ item.lokasi_masuk }}</td>
                  
                  <td class="py-4 px-6">
                    <span 
                      v-if="item.status_masuk !== '-'"
                      :class="['px-2.5 py-1 rounded-full text-xs font-bold inline-block', getBadgeClass(item.status_masuk)]"
                    >
                      {{ item.status_masuk }}
                    </span>
                    <span v-else class="text-gray-400">-</span>
                  </td>

                  <td class="py-4 px-6 font-semibold text-gray-700">{{ item.jam_keluar }}</td>
                  <td class="py-4 px-6 text-xs text-gray-600 max-w-[150px] truncate" :title="item.lokasi_keluar">{{ item.lokasi_keluar }}</td>

                  <td class="py-4 px-6">
                    <span 
                      v-if="item.status_pulang !== '-'"
                      :class="['px-2.5 py-1 rounded-full text-xs font-bold inline-block', getBadgeClass(item.status_pulang)]"
                    >
                      {{ item.status_pulang }}
                    </span>
                    <span v-else class="text-gray-400">-</span>
                  </td>
                </tr>

                <tr v-if="paginatedPresensi.length === 0">
                  <td colspan="8" class="py-8 text-center text-gray-400 text-sm">
                    {{ isLoading ? 'Memuat data presensi...' : 'Tidak ada data presensi yang ditemukan.' }}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- PAGINASI -->
        <div class="flex items-center justify-end space-x-4 text-xs font-medium text-gray-600 pt-2">
          <div class="flex items-center space-x-2">
            <span>Halaman:</span>
            <select v-model="currentPage" class="border border-gray-300 rounded-md px-2 py-1 bg-white focus:outline-none">
              <option v-for="page in totalPages" :key="page" :value="page">{{ page }}</option>
            </select>
          </div>

          <span>{{ displayFrom }} - {{ displayTo }} dari {{ filteredPresensi.length }}</span>

          <div class="flex items-center space-x-1">
            <button @click="goToPrev" :disabled="currentPage === 1" class="p-1 text-gray-400 hover:text-gray-600 disabled:opacity-30">
              <ChevronLeft class="w-4 h-4" />
            </button>
            <button @click="goToNext" :disabled="currentPage === totalPages" class="p-1 text-gray-600 hover:text-gray-900 disabled:opacity-30">
              <ChevronRight class="w-4 h-4" />
            </button>
          </div>
        </div>
      </main>
    </div>

    <!-- DRAWER NOTIFIKASI -->
    <div v-if="isNotifOpen" class="absolute top-16 right-0 w-80 bg-white border-l border-b border-gray-200 shadow-xl z-50 p-4 transition-all">
      <div class="flex items-center justify-between pb-3 border-b border-gray-100">
        <h3 class="font-bold text-sm text-gray-800">Notifications</h3>
        <div class="flex items-center space-x-3">
          <button @click="clearAllNotif" class="text-xs text-gray-500 hover:text-gray-800 font-medium">Clear All</button>
          <button @click="isNotifOpen = false" class="text-gray-400 hover:text-gray-600"><X class="w-4 h-4" /></button>
        </div>
      </div>
      <div class="divide-y divide-gray-50 max-h-96 overflow-y-auto">
        <div v-for="notif in notifications" :key="notif.id" class="py-3 flex items-center justify-between hover:bg-gray-50 cursor-pointer transition px-1 group">
          <div class="flex items-center space-x-3">
            <div class="w-8 h-8 rounded-full bg-black flex items-center justify-center text-white shrink-0">
              <User class="w-4 h-4" />
            </div>
            <div>
              <p class="text-xs font-bold text-gray-900 leading-tight">{{ notif.name }}</p>
              <p class="text-[10px] text-gray-500">{{ notif.action }}</p>
              <span class="text-[9px] text-gray-400">{{ notif.time }}</span>
            </div>
          </div>
          <div class="flex items-center space-x-2">
            <div v-if="notif.unread" class="w-2 h-2 rounded-full bg-red-500"></div>
            <button
              @click.stop="removeNotification(notif.id)"
              class="p-1 text-gray-400 hover:text-red-500 hover:bg-gray-100 rounded-md transition"
              title="Hapus notifikasi"
            >
              <X class="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
        <div v-if="notifications.length === 0" class="py-6 text-center text-xs text-gray-400">
          Tidak ada notifikasi baru
        </div>
      </div>
    </div>
  </div>
</template>