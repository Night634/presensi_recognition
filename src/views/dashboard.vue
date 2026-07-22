<template>
  <div class="flex h-screen bg-[#F0F4F8] font-sans text-gray-900 overflow-hidden">
    
    <!-- BACKDROP MOBILE OVERLAY -->
    <div 
      v-if="isSidebarOpen" 
      @click="toggleSidebar"
      class="fixed inset-0 bg-black/40 backdrop-blur-xs z-40 lg:hidden transition-opacity"
    ></div>

    <!-- SIDEBAR -->
    <aside 
      :class="[
        'fixed lg:static inset-y-0 left-0 w-64 bg-white border-r border-gray-200 flex flex-col justify-between z-50 transition-transform duration-300 ease-in-out shrink-0',
        isSidebarOpen ? 'translate-x-0 shadow-2xl' : '-translate-x-full lg:translate-x-0 shadow-none'
      ]"
    >
      <div>
        <!-- Sidebar Header -->
        <div class="h-16 flex items-center justify-between px-6 border-b border-gray-100">
          <div class="flex items-center space-x-3">
            <div class="w-7 h-7 rounded-full bg-blue-600 flex items-center justify-center text-white font-bold text-xs">P</div>
            <span class="font-bold text-sm text-gray-800">Admin Portal</span>
          </div>
          <button @click="toggleSidebar" class="lg:hidden text-gray-500 hover:text-gray-700">
            <X class="w-6 h-6" />
          </button>
        </div>

        <!-- Navigation Links -->
        <nav class="mt-4 px-4 space-y-1.5">
          <button
            v-for="item in navItems"
            :key="item.name"
            @click="navigateTo(item)"
            :class="[
              'w-full flex items-center justify-between px-4 py-3 rounded-xl transition-all duration-150',
              activeMenu === item.name 
                ? 'text-blue-600 bg-blue-50/60 font-semibold' 
                : 'text-gray-600 hover:bg-gray-50'
            ]"
          >
            <div class="flex items-center space-x-3.5">
              <component 
                :is="item.icon" 
                :class="['w-5 h-5', activeMenu === item.name ? 'text-blue-600' : 'text-gray-500']" 
                stroke-width="2"
              />
              <span class="text-sm">{{ item.name }}</span>
            </div>
            <div v-if="activeMenu === item.name" class="w-1.5 h-6 bg-blue-600 rounded-full"></div>
          </button>
        </nav>
      </div>

      <!-- Sidebar Footer (Logout) -->
      <div class="p-4 border-t border-gray-100">
        <button 
          @click="handleLogout" 
          class="flex items-center space-x-3.5 px-4 py-3 text-sm font-semibold text-red-600 hover:bg-red-50 rounded-xl w-full transition"
        >
          <LogOut class="w-5 h-5" stroke-width="2" />
          <span>Keluar</span>
        </button>
      </div>
    </aside>

    <!-- MAIN WRAPPER -->
    <div class="flex-1 flex flex-col min-w-0 h-full overflow-hidden">
      
      <!-- HEADER NAVBAR -->
      <header class="h-16 bg-white border-b border-gray-200 flex items-center justify-between px-4 sm:px-8 z-30 shrink-0">
        <div class="flex items-center space-x-3">
          <button @click="isSidebarOpen = true" class="p-2 -ml-2 text-gray-600 lg:hidden">
            <Menu class="w-6 h-6" />
          </button>
          <div class="flex items-center space-x-3">
            <div class="w-8 h-8 bg-white flex items-center justify-center">
              <img :src="logoSetneg" alt="Logo Setneg" class="w-full h-full object-cover" />
            </div>
            <span class="font-bold text-xs uppercase tracking-wide text-gray-800">Kementerian Sekretariat Negara Republik Indonesia</span>
          </div>
        </div>
        <button @click="isNotifOpen = !isNotifOpen" class="p-2 text-gray-700 hover:bg-gray-100 rounded-full transition relative">
          <Bell class="w-6 h-6" />
        </button>
      </header>

      <!-- DASHBOARD BODY CONTENT -->
      <main class="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8 space-y-6">
        
        <!-- Welcome Banner -->
        <div class="bg-gradient-to-r from-blue-100/80 via-blue-200/60 to-blue-300/60 rounded-2xl p-5 sm:p-6 shadow-xs border border-blue-200/50">
          <p class="text-xs font-medium text-gray-500 mb-1">Hello, {{ username }}</p>
          <h1 class="text-xl sm:text-2xl font-bold text-gray-900 mb-2">Welcome to Dashboard</h1>
          <p class="text-xs sm:text-sm text-gray-600 max-w-3xl leading-relaxed">
            Pengelolaan, Pemantauan dan Rekapitulasi Presensi pegawai Kementerian Sekretariat Negara
          </p>
        </div>

        <!-- Stats Cards -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 sm:gap-6">
          <div 
            v-for="(stat, idx) in statsCards" 
            :key="idx" 
            class="bg-white rounded-2xl p-5 shadow-xs border border-gray-100 flex items-center justify-between transition hover:shadow-md"
          >
            <div class="flex items-center space-x-4">
              <div class="w-12 h-12 sm:w-14 sm:h-14 rounded-full bg-blue-600 flex items-center justify-center shrink-0 shadow-md shadow-blue-500/20">
                <component :is="stat.icon" class="w-6 h-6 sm:w-7 sm:h-7 text-white" stroke-width="2" />
              </div>
              <div>
                <p class="text-xs font-semibold text-gray-700 mb-1">{{ stat.title }}</p>
                <h3 class="text-2xl sm:text-3xl font-bold text-blue-600 leading-none">{{ stat.value }}</h3>
              </div>
            </div>
            <div class="w-1 h-10 bg-blue-600 rounded-full shrink-0"></div>
          </div>
        </div>

        <!-- Aktivitas Terakhir Section -->
        <div class="bg-white rounded-2xl p-5 sm:p-6 shadow-xs border border-gray-100">
          <h2 class="text-base font-bold text-gray-900 mb-4">Aktivitas Terakhir</h2>
          
          <div v-if="isLoadingActivities" class="text-xs text-gray-400">Memuat data aktivitas...</div>
          <div v-else-if="activities.length === 0" class="text-xs text-gray-400">Belum ada aktivitas hari ini.</div>
          <div v-else class="space-y-3">
            <div 
              v-for="act in activities" 
              :key="act.id" 
              class="flex items-center space-x-4 p-3.5 bg-white rounded-xl border border-gray-200/80 hover:border-gray-300 transition"
            >
              <div :class="['w-4 h-4 sm:w-5 sm:h-5 rounded-full shrink-0', act.color]"></div>
              <div class="text-xs sm:text-sm text-gray-700 flex-1" v-html="act.content"></div>
            </div>
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
        <div v-for="notif in notifications" :key="notif.id" class="py-3 flex items-center justify-between hover:bg-gray-50 cursor-pointer transition px-1">
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
          <div class="flex items-center space-x-1">
            <div v-if="notif.unread" class="w-2 h-2 rounded-full bg-red-500"></div>
            <ChevronRight class="w-4 h-4 text-gray-400" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import logoSetneg from '../assets/logosetneg.png'
import { 
  LayoutGrid, 
  Users, 
  Scan, 
  CalendarCheck, 
  LogOut, 
  Bell, 
  UserCheck, 
  Clock, 
  FileSignature,
  User,
  ChevronRight,
  Menu,
  X
} from 'lucide-vue-next'

const router = useRouter()

// State Mobile Menu & UI
const isSidebarOpen = ref(false)
const isNotifOpen = ref(false)
const activeMenu = ref('Dashboard')
const isLoadingActivities = ref(true)

// Ambil Nama User dari LocalStorage
const storedUser = JSON.parse(localStorage.getItem('user') || '{}')
const username = ref(storedUser.name || localStorage.getItem('username') || 'Admin')

// Reactive Stat Cards Data
const statsCards = ref([
  { title: "Akun Yang Terdaftar", value: 0, icon: Users },
  { title: "Total Pegawai Terlambat", value: 0, icon: Clock },
  { title: "Persetujuan Cuti/Izin/Dinas", value: 0, icon: UserCheck },
  { title: "Total Pegawai Cuti/Izin/Dinas", value: 0, icon: FileSignature },
])

// Reactive Activities
const activities = ref([])

const toggleSidebar = () => {
  isSidebarOpen.value = !isSidebarOpen.value
}

// Fungsi Fetch Data dari Laravel Backend (Menembak Endpoint /api/dashboard-stats)
const fetchDashboardData = async () => {
  const token = localStorage.getItem('token')

  // Buat header dinamis (mengirim Token jika ada)
  const headers = {
    'Accept': 'application/json'
  }
  if (token) {
    headers['Authorization'] = `Bearer ${token}`
  }

  try {
    const response = await fetch('http://127.0.0.1:8000/api/dashboard-stats', { headers })

    const res = await response.json()
    console.log('HASIL RESPONSE DARI LARAVEL:', res)

    if (response.ok && res.status === 'success') {
      const d = res.data

      // Update Angka Card secara Dinamis dari Database
      statsCards.value[0].value = d.total_pegawai ?? 0
      statsCards.value[1].value = d.total_terlambat ?? 0
      statsCards.value[2].value = d.pending_cuti ?? 0
      statsCards.value[3].value = d.approved_cuti ?? 0

      // Update Aktivitas Terakhir dari DB
      activities.value = d.activities || []
    } else {
      console.warn('Response API gagal status:', response.status, res)
    }
  } catch (err) {
    console.error('Gagal mengambil data dashboard:', err)
  } finally {
    isLoadingActivities.value = false
  }
}

onMounted(() => {
  const isAuthenticated = localStorage.getItem('isAuthenticated') === 'true'
  if (!isAuthenticated) {
    router.push({ name: 'Login' })
  } else {
    fetchDashboardData()
  }
})

const notifications = ref([
  { id: 1, name: 'Muh Fahrul', action: 'Mengajukan Cuti', time: '0 min', unread: true },
  { id: 2, name: 'Ramzy', action: 'Terlambat Presensi', time: '6 min', unread: true },
  { id: 3, name: 'Atchallah', action: 'Mengajukan Cuti', time: '15 min', unread: false },
])

const clearAllNotif = () => {
  notifications.value = []
}

const navItems = [
  { name: 'Dashboard', icon: LayoutGrid, route: 'Dashboard' },
  { name: 'Pegawai', icon: Users, route: 'Pegawai' },
  { name: 'Presensi', icon: Scan, route: 'Presensi' },
  { name: 'Cuti', icon: CalendarCheck, route: 'Cuti' },
]

const navigateTo = (item) => {
  activeMenu.value = item.name
  isSidebarOpen.value = false
  router.push({ name: item.route })
}

// Fungsi Logout Bersih
const handleLogout = () => {
  localStorage.removeItem('isAuthenticated')
  localStorage.removeItem('username')
  localStorage.removeItem('user')
  localStorage.removeItem('token')
  router.push({ name: 'Login' })
}
</script>