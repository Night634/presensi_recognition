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
    // Redirect to login if not authenticated
    next({ name: 'Login' })
  } else if (to.name === 'Login' && isAuthenticated) {
    // Redirect to dashboard if already logged in
    next({ name: 'Dashboard' })
  } else {
    next()
  }
})

export default router

