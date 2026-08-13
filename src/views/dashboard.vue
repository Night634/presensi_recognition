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
        <div class="h-16 flex items-center justify-between px-6 border-b border-gray-100">
          <div class="flex items-center space-x-3">
            <div class="w-7 h-7 rounded-full bg-blue-600 flex items-center justify-center text-white font-bold text-xs">P</div>
            <span class="font-bold text-sm text-gray-800">Admin Portal</span>
          </div>
          <button @click="toggleSidebar" class="lg:hidden text-gray-500 hover:text-gray-700">
            <X class="w-6 h-6" />
          </button>
        </div>

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
        <button @click="toggleNotifications" class="p-2 text-gray-700 hover:bg-gray-100 rounded-full transition relative">
          <Bell class="w-6 h-6" />
        </button>
      </header>

      <main class="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8 space-y-6">
        
        <div class="bg-gradient-to-r from-blue-100/80 via-blue-200/60 to-blue-300/60 rounded-2xl p-5 sm:p-6 shadow-xs border border-blue-200/50">
          <p class="text-xs font-medium text-gray-500 mb-1">Hello, {{ username }}</p>
          <h1 class="text-xl sm:text-2xl font-bold text-gray-900 mb-2">Welcome to Dashboard</h1>
          <p class="text-xs sm:text-sm text-gray-600 max-w-3xl leading-relaxed">
            Pengelolaan, Pemantauan dan Rekapitulasi Presensi pegawai Kementrian Sekretariat Negara
          </p>
        </div>

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

        <div class="bg-white rounded-2xl p-5 sm:p-6 shadow-xs border border-gray-100">
          <h2 class="text-base font-bold text-gray-900 mb-4">Aktivitas Terakhir</h2>
          
          <div class="space-y-3">
            <div 
              v-for="act in activities" 
              :key="act.id" 
              class="flex items-center space-x-4 p-3.5 bg-white rounded-xl border border-gray-200/80 hover:border-gray-300 transition"
            >
              <div :class="['w-4 h-4 sm:w-5 sm:h-5 rounded-full shrink-0', act.color]"></div>
              <div class="text-xs sm:text-sm text-gray-700 flex-1" v-html="act.content"></div>
            </div>
            <div v-if="activities.length === 0" class="text-xs text-gray-400 py-2">Belum ada aktivitas presensi.</div>
          </div>
        </div>
        <router-view />
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
        <div 
          v-for="notif in notifications" 
          :key="notif.id" 
          class="py-3 flex items-center justify-between hover:bg-gray-50 transition px-1 group"
        >
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

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import logoSetneg from '../assets/logosetneg.png'
import axios from 'axios'
import { useNotifications } from '../composables/useNotifications'
import { 
  LayoutGrid, Users, Scan, CalendarCheck, MapPin, LogOut, Bell, UserCheck, Clock, FileSignature, User, Menu, X
} from 'lucide-vue-next'

const router = useRouter()

const isSidebarOpen = ref(false)
const isNotifOpen = ref(false)
const username = ref('Admin')

const { notifications, fetchNotifications, removeNotification, clearAllNotif } = useNotifications()

const statsCards = ref([
  { title: "Akun Yang Terdaftar", value: 0, icon: Users },
  { title: "Total Pegawai Terlambat", value: 0, icon: Clock },
  { title: "Persetujuan Cuti/Izin/Dinas", value: 0, icon: UserCheck },
  { title: "Total Pegawai Cuti/Izin/Dinas", value: 0, icon: FileSignature },
])

const activities = ref([])

const fetchDashboardStats = async () => {
  try {
    const token = sessionStorage.getItem('admin_token') || localStorage.getItem('token')
    const res = await axios.get('http://localhost:8000/api/dashboard/stats', {
      headers: { Authorization: `Bearer ${token}` }
    })

    // Update Card Values
    statsCards.value[0].value = res.data.total_pegawai || 0
    statsCards.value[1].value = res.data.total_terlambat || 0
    statsCards.value[2].value = res.data.persetujuan_cuti || 0
    statsCards.value[3].value = res.data.total_pegawai_cuti || 0

    // Update Activities List
    activities.value = res.data.activities || []
  } catch (error) {
    console.error('Gagal mengambil data statistik dashboard:', error)
  }
}

const toggleSidebar = () => { isSidebarOpen.value = !isSidebarOpen.value }

const toggleNotifications = async () => {
  isNotifOpen.value = !isNotifOpen.value
  if (isNotifOpen.value) {
    await fetchNotifications()
  }
}

onMounted(() => {
  const adminUserData = sessionStorage.getItem('admin_user')
  if (adminUserData) {
    try {
      const parsedUser = JSON.parse(adminUserData)
      username.value = parsedUser.nama || parsedUser.name || parsedUser.nip || 'Admin'
    } catch (e) {
      username.value = localStorage.getItem('username') || 'Admin'
    }
  }

  fetchNotifications()
  fetchDashboardStats()
})

const activeMenu = ref('Dashboard')

const navItems = [
  { name: 'Dashboard', icon: LayoutGrid, path: '/dashboard' },
  { name: 'Pegawai', icon: Users, path: '/pegawai' },
  { name: 'Presensi', icon: Scan, path: '/presensi' },
  { name: 'Cuti', icon: CalendarCheck, path: '/cuti' },
  { name: 'Lokasi', icon: MapPin, path: '/lokasi' },
]

const navigateTo = (item) => {
  activeMenu.value = item.name
  isSidebarOpen.value = false
  router.push(item.path)
}

const handleLogout = async () => {
  try {
    const token = sessionStorage.getItem('admin_token')
    if (token) {
      await axios.post('http://127.0.0.1:8000/api/admin/logout', {}, {
        headers: { Authorization: `Bearer ${token}` }
      }).catch(() => {})
    }
  } finally {
    sessionStorage.clear()
    router.replace({ name: 'Login' })
  }
}
</script>