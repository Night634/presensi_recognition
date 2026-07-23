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
  {
    path: '/lokasi',
    name: 'Lokasi',
    component: () => import('../views/lokasi.vue'),
    meta: { requiresAuth: true }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// Navigation Guard menggunakan sessionStorage
router.beforeEach((to, from, next) => {
  const token = sessionStorage.getItem('admin_token')

  if (to.meta.requiresAuth && !token) {
    next({ name: 'Login' })
  } else if (to.name === 'Login' && token) {
    next({ name: 'Dashboard' })
  } else {
    next()
  }
})

export default router