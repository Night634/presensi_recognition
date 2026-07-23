<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import logoSetneg from '../assets/logosetneg.png'
import { 
  LayoutGrid, Users, Scan, CalendarCheck, MapPin, LogOut, Bell, Search, 
  ArrowUpDown, ChevronLeft, ChevronRight, Menu, X, User
} from 'lucide-vue-next'

const router = useRouter()

// State Navigation & Layout
const isSidebarOpen = ref(false)
const isNotifOpen = ref(false)
const searchQuery = ref('')
const currentPage = ref(1)
const pageSize = ref(4)
const activeMenu = ref('Presensi')

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
  localStorage.removeItem('isAuthenticated')
  localStorage.removeItem('username')
  router.push({ name: 'Login' })
}

// Data Presensi Dummy
const presensiList = ref([
  { id: 1, nama: 'Muh Fahrul Fahrezi', jamMasuk: '08:00', jamKeluar: '16:00', totalJamKerja: '08:00:00' },
  { id: 2, nama: 'Muh Fahrul Fahrezi', jamMasuk: '08:00', jamKeluar: '16:00', totalJamKerja: '08:00:00' },
  { id: 3, nama: 'Muh Fahrul Fahrezi', jamMasuk: '08:00', jamKeluar: '16:00', totalJamKerja: '08:00:00' },
  { id: 4, nama: 'Muh Fahrul Fahrezi', jamMasuk: '08:00', jamKeluar: '16:00', totalJamKerja: '08:00:00' },
  { id: 5, nama: 'Ramzy Atchallah Putra', jamMasuk: '08:00', jamKeluar: '16:00', totalJamKerja: '08:00:00' },
])

// Notifications Data
const notifications = ref([
  { id: 1, name: 'Muh Fahrul', action: 'Mengajukan Cuti', time: '0 min', unread: true },
  { id: 2, name: 'Ramzy', action: 'Terlambat Presensi', time: '6 min', unread: true },
  { id: 3, name: 'Atchallah', action: 'Mengajukan Cuti', time: '15 min', unread: false },
  { id: 4, name: 'Putra', action: 'Mengajukan Cuti', time: '16 min', unread: false },
  { id: 5, name: 'thejoeswanson', action: 'High fived your workout', time: '18 min', unread: true },
])

const clearAllNotif = () => {
  notifications.value = []
}

const filteredPresensi = computed(() => {
  return presensiList.value.filter(item => 
    item.nama.toLowerCase().includes(searchQuery.value.toLowerCase())
  )
})

const totalPages = computed(() => Math.max(1, Math.ceil(filteredPresensi.value.length / pageSize.value)))
const paginatedPresensi = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  return filteredPresensi.value.slice(start, start + pageSize.value)
})
const displayFrom = computed(() => filteredPresensi.value.length === 0 ? 0 : (currentPage.value - 1) * pageSize.value + 1)
const displayTo = computed(() => Math.min(filteredPresensi.value.length, currentPage.value * pageSize.value))

watch(searchQuery, () => {
  currentPage.value = 1
})

const goToPrev = () => {
  if (currentPage.value > 1) currentPage.value -= 1
}

const goToNext = () => {
  if (currentPage.value < totalPages.value) currentPage.value += 1
}
</script>

<template>
  <div class="flex h-screen bg-[#F0F4F8] font-sans text-gray-900 overflow-hidden relative">
    
    <!-- BACKDROP MOBILE -->
    <div 
      v-if="isSidebarOpen" 
      @click="isSidebarOpen = false"
      class="fixed inset-0 bg-black/40 backdrop-blur-xs z-40 lg:hidden"
    ></div>

    <!-- SIDEBAR -->
    <aside 
      :class="[
        'fixed lg:static inset-y-0 left-0 w-64 bg-white border-r border-gray-200 flex flex-col justify-between z-40 transition-transform duration-300 ease-in-out shrink-0',
        isSidebarOpen ? 'translate-x-0 shadow-2xl' : '-translate-x-full lg:translate-x-0'
      ]"
    >
      <div>
        <div class="h-16 flex items-center justify-between px-6 border-b border-gray-100">
          <div class="flex items-center space-x-3">
            <div class="w-7 h-7 rounded-full bg-blue-600 flex items-center justify-center text-white font-bold text-xs">P</div>
            <span class="font-bold text-sm text-gray-800">Admin Portal</span>
          </div>
          <button @click="isSidebarOpen = false" class="lg:hidden text-gray-500">
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

      <!-- BODY -->
      <main class="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8 space-y-6">
        <div>
          <p class="text-xs font-semibold text-gray-400 mb-1">Hello, Admin</p>
          <h1 class="text-2xl font-bold text-gray-950">Welcome to List Presensi!</h1>
        </div>

        <!-- SEARCH & EXPORT -->
        <div class="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4">
          <div class="relative w-full sm:w-80">
            <input v-model="searchQuery" type="text" placeholder="Search..." class="w-full bg-white border border-gray-200 rounded-xl pl-4 pr-10 py-2.5 text-sm text-gray-700 focus:outline-none" />
            <Search class="w-4 h-4 text-gray-400 absolute right-3.5 top-1/2 -translate-y-1/2" />
          </div>
          <button class="bg-blue-600 hover:bg-blue-700 text-white font-semibold text-sm px-6 py-2.5 rounded-xl transition">Export</button>
        </div>

        <!-- TABLE DATA PRESENSI -->
        <div class="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse min-w-[650px]">
              <thead>
                <tr class="border-b border-gray-100 text-xs font-bold text-gray-800 bg-white">
                  <th class="py-4 px-6 text-center w-16">No</th>
                  <th class="py-4 px-6">
                    <div class="flex items-center space-x-1.5 cursor-pointer">
                      <span>Nama</span>
                      <ArrowUpDown class="w-3.5 h-3.5 text-gray-400" />
                    </div>
                  </th>
                  <th class="py-4 px-6">Jam Masuk</th>
                  <th class="py-4 px-6">Jam Keluar</th>
                  <th class="py-4 px-6">Total Jam Kerja</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100 text-sm font-medium text-gray-800">
                <tr v-for="(item, index) in paginatedPresensi" :key="item.id" class="hover:bg-gray-50/80 transition">
                  <td class="py-4 px-6 text-center">{{ displayFrom + index }}</td>
                  <td class="py-4 px-6">{{ item.nama }}</td>
                  <td class="py-4 px-6">{{ item.jamMasuk }}</td>
                  <td class="py-4 px-6">{{ item.jamKeluar }}</td>
                  <td class="py-4 px-6">{{ item.totalJamKerja }}</td>
                </tr>
                <tr v-if="paginatedPresensi.length === 0">
                  <td colspan="5" class="py-8 text-center text-gray-400 text-sm">Tidak ada data presensi yang ditemukan.</td>
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
