import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  {
    path: '/',
    name: 'Login',
    component: () => import('../views/login.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/dashboard',
    name: 'Dashboard',
    component: () => import('../views/dashboard.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/pegawai',
    name: 'Pegawai',
    component: () => import('../views/pegawai.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/presensi',
    name: 'Presensi',
    component: () => import('../views/presensi.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/cuti',
    name: 'Cuti',
    component: () => import('../views/cuti.vue'),
    meta: { requiresAuth: true }
  },
  // Tambahkan ini: Redirect URL yang tidak dikenal kembali ke Login / Dashboard
  {
    path: '/:pathMatch(.*)*',
    redirect: { name: 'Login' }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// Navigation Guard
router.beforeEach((to, from, next) => {
  const isAuthenticated = localStorage.getItem('isAuthenticated') === 'true'
  
  if (to.meta.requiresAuth && !isAuthenticated) {
    // Redirect ke login jika mencoba akses halaman terproteksi tapi belum login
    next({ name: 'Login' })
  } else if (to.name === 'Login' && isAuthenticated) {
    // Redirect ke dashboard jika sudah terautentikasi tapi membuka / login
    next({ name: 'Dashboard' })
  } else {
    next()
  }
})

export default router