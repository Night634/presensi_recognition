<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import logoSetneg from '../assets/logosetneg.png'
import { 
  LayoutGrid, Users, Scan, CalendarCheck, MapPin, LogOut, Bell, Search, 
  ArrowUpDown, ChevronLeft, ChevronRight, Menu, X, User
} from 'lucide-vue-next'

const router = useRouter()

onMounted(() => {
  const isAuthenticated = localStorage.getItem('isAuthenticated') === 'true'
  if (!isAuthenticated) {
    router.push({ name: 'Login' })
  }
})

// State Navigation & Modal
const isSidebarOpen = ref(false)
const isNotifOpen = ref(false)
const isInspectOpen = ref(false)
const searchQuery = ref('')
const currentPage = ref(1)
const pageSize = ref(4)
const activeMenu = ref('Cuti')

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

// Selected Cuti Detail untuk Inspect Modal
const selectedCuti = ref({
  nip: '',
  nama: '',
  status: '',
  startDate: '',
  endDate: '',
  alasan: '',
  lampiran: 'surat_keterangan.pdf'
})

// Data Cuti Dummy
const cutiList = ref([
  { id: 1, nama: 'Muh Fahrul Fahrezi', startDate: '16/07/2025', endDate: '19/07/2025', status: 'Cuti', lampiran: 'surat_cuti_1.pdf' },
  { id: 2, nama: 'Muh Fahrul Fahrezi', startDate: '16/07/2025', endDate: '19/07/2025', status: 'Sakit', lampiran: 'surat_sakit_2.pdf' },
  { id: 3, nama: 'Muh Fahrul Fahrezi', startDate: '16/07/2025', endDate: '19/07/2025', status: 'Sakit', lampiran: 'surat_sakit_3.pdf' },
  { id: 4, nama: 'Muh Fahrul Fahrezi', startDate: '16/07/2025', endDate: '19/07/2025', status: 'Cuti', lampiran: 'surat_cuti_4.pdf' },
  { id: 5, nama: 'Ramzy Atchallah Putra', startDate: '16/07/2025', endDate: '19/07/2025', status: 'Cuti', lampiran: 'surat_cuti_5.pdf' },
])

// Notification Dummy Data
const notifications = ref([
  { id: 1, name: 'Muh Fahrul', action: 'Mengajukan Cuti', time: '0 min', unread: true },
  { id: 2, name: 'Ramzy', action: 'Terlambat Presensi', time: '6 min', unread: true },
  { id: 3, name: 'Atchallah', action: 'Mengajukan Cuti', time: '15 min', unread: false },
  { id: 4, name: 'Putra', action: 'Mengajukan Cuti', time: '16 min', unread: false },
  { id: 5, name: 'thejoeswanson', action: 'High fived your workout', time: '18 min', unread: true },
])

// Actions
const handleInspect = (item) => {
  selectedCuti.value = {
    nip: '',
    nama: '',
    status: '',
    startDate: '',
    endDate: '',
    alasan: '',
    lampiran: item.lampiran || 'surat_keterangan.pdf'
  }
  isInspectOpen.value = true
}

const handleReject = (id) => {
  cutiList.value = cutiList.value.filter(c => c.id !== id)
}

const handleApprove = () => {
  alert('Pengajuan Cuti Disetujui!')
  isInspectOpen.value = false
}

const clearAllNotif = () => {
  notifications.value = []
}

const filteredCuti = computed(() => {
  return cutiList.value.filter(item => 
    item.nama.toLowerCase().includes(searchQuery.value.toLowerCase())
  )
})

const totalPages = computed(() => Math.max(1, Math.ceil(filteredCuti.value.length / pageSize.value)))
const paginatedCuti = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  return filteredCuti.value.slice(start, start + pageSize.value)
})
const displayFrom = computed(() => filteredCuti.value.length === 0 ? 0 : (currentPage.value - 1) * pageSize.value + 1)
const displayTo = computed(() => Math.min(filteredCuti.value.length, currentPage.value * pageSize.value))

watch(searchQuery, () => {
  currentPage.value = 1
})
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
          <h1 class="text-2xl font-bold text-gray-950">Welcome to Pengajuan Cuti !</h1>
        </div>

        <!-- SEARCH & EXPORT -->
        <div class="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4">
          <div class="relative w-full sm:w-80">
            <input v-model="searchQuery" type="text" placeholder="Search..." class="w-full bg-white border border-gray-200 rounded-xl pl-4 pr-10 py-2.5 text-sm text-gray-700 focus:outline-none" />
            <Search class="w-4 h-4 text-gray-400 absolute right-3.5 top-1/2 -translate-y-1/2" />
          </div>
          <button class="bg-blue-600 hover:bg-blue-700 text-white font-semibold text-sm px-6 py-2.5 rounded-xl transition">Export</button>
        </div>

        <!-- TABLE DATA CUTI -->
        <div class="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="border-b border-gray-100 text-xs font-bold text-gray-800">
                  <th class="py-4 px-6 text-center w-16">No</th>
                  <th class="py-4 px-6">
                    <div class="flex items-center space-x-1.5 cursor-pointer">
                      <span>Nama</span>
                      <ArrowUpDown class="w-3.5 h-3.5 text-gray-400" />
                    </div>
                  </th>
                  <th class="py-4 px-6">Start Date</th>
                  <th class="py-4 px-6">End Date</th>
                  <th class="py-4 px-6">Status</th>
                  <th class="py-4 px-6 text-center">Aksi</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100 text-sm font-semibold text-gray-900">
                <tr v-for="(item, index) in paginatedCuti" :key="item.id" class="hover:bg-gray-50/80 transition">
                  <td class="py-4 px-6 text-center">{{ displayFrom + index }}</td>
                  <td class="py-4 px-6">{{ item.nama }}</td>
                  <td class="py-4 px-6">{{ item.startDate }}</td>
                  <td class="py-4 px-6">{{ item.endDate }}</td>
                  <td class="py-4 px-6">{{ item.status }}</td>
                  <td class="py-4 px-6">
                    <div class="flex items-center justify-center space-x-2">
                      <button @click="handleInspect(item)" class="bg-blue-600 hover:bg-blue-700 text-white text-xs font-semibold px-4 py-1.5 rounded-md transition">Inspect</button>
                      <button @click="handleReject(item.id)" class="bg-red-600 hover:bg-red-700 text-white text-xs font-semibold px-4 py-1.5 rounded-md transition">Reject</button>
                    </div>
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
          <span>{{ displayFrom }} - {{ displayTo }} dari {{ filteredCuti.length }}</span>
          <div class="flex items-center space-x-1">
            <button @click="currentPage = Math.max(1, currentPage - 1)" :disabled="currentPage === 1" class="p-1 text-gray-400 hover:text-gray-600 disabled:opacity-30"><ChevronLeft class="w-4 h-4" /></button>
            <button @click="currentPage = Math.min(totalPages, currentPage + 1)" :disabled="currentPage === totalPages" class="p-1 text-gray-600 hover:text-gray-900 disabled:opacity-30"><ChevronRight class="w-4 h-4" /></button>
          </div>
        </div>
      </main>
    </div>

    <!-- DRAWER NOTIFIKASI -->
    <div v-if="isNotifOpen" class="absolute top-16 right-0 w-80 bg-white border-l border-b border-gray-200 shadow-2xl z-50 p-4 transition-all">
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

    <!-- MODAL INSPECT CUTI -->
    <div v-if="isInspectOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-xs transition-opacity overflow-y-auto">
      <div class="bg-white rounded-2xl w-full max-w-lg p-6 sm:p-8 shadow-2xl relative my-8 border border-gray-100">
        <div class="text-center mb-6">
          <h2 class="text-xl sm:text-2xl font-bold text-gray-900">Cuti Pegawai</h2>
          <p class="text-xs text-gray-500 mt-1">Detail Pengajuan Cuti Pegawai</p>
        </div>
        <div class="space-y-4">
          <div>
            <label class="block text-xs font-semibold text-gray-700 mb-1">NIP</label>
            <input :value="selectedCuti.nip" type="text" readonly class="w-full bg-gray-200/80 border-none rounded-lg px-3.5 py-2 text-xs text-gray-800 focus:outline-none" />
          </div>
          <div>
            <label class="block text-xs font-semibold text-gray-700 mb-1">Nama Pegawai</label>
            <input :value="selectedCuti.nama" type="text" readonly class="w-full bg-gray-200/80 border-none rounded-lg px-3.5 py-2 text-xs text-gray-800 focus:outline-none" />
          </div>
          <div>
            <label class="block text-xs font-semibold text-gray-700 mb-1">Status</label>
            <input :value="selectedCuti.status" type="text" readonly class="w-full bg-gray-200/80 border-none rounded-lg px-3.5 py-2 text-xs text-gray-800 focus:outline-none" />
          </div>
          <div>
            <label class="block text-xs font-semibold text-gray-700 mb-1">Durasi</label>
            <div class="grid grid-cols-2 gap-3">
              <input :value="selectedCuti.startDate" type="text" readonly placeholder="mm/dd/yyyy" class="w-full bg-gray-200/80 border-none rounded-lg px-3.5 py-2 text-xs text-gray-800 text-center focus:outline-none" />
              <input :value="selectedCuti.endDate" type="text" readonly placeholder="mm/dd/yyyy" class="w-full bg-gray-200/80 border-none rounded-lg px-3.5 py-2 text-xs text-gray-800 text-center focus:outline-none" />
            </div>
          </div>
          <div>
            <label class="block text-xs font-semibold text-gray-700 mb-1">Alasan</label>
            <textarea :value="selectedCuti.alasan" rows="2" readonly class="w-full bg-gray-200/80 border-none rounded-lg px-3.5 py-2 text-xs text-gray-800 focus:outline-none resize-none"></textarea>
          </div>
          <div>
            <label class="block text-xs font-semibold text-gray-700 mb-1">Lampiran</label>
            <div class="bg-gray-500 rounded-2xl h-44 flex items-center justify-center relative overflow-hidden">
              <div class="text-center text-white text-xs font-semibold px-4 py-2">
                {{ selectedCuti.lampiran || 'No file attached' }}
              </div>
            </div>
          </div>
        </div>
        <div class="flex items-center space-x-3 pt-4">
          <button type="button" @click="handleApprove" class="flex-1 bg-blue-600 hover:bg-blue-700 text-white text-xs font-semibold py-3 rounded-lg shadow-md transition duration-150">Approve</button>
          <button type="button" @click="isInspectOpen = false" class="flex-1 bg-white hover:bg-gray-50 text-blue-600 border border-blue-600 text-xs font-semibold py-3 rounded-lg transition duration-150">Batal</button>
        </div>
      </div>
    </div>

  </div>
</template>
