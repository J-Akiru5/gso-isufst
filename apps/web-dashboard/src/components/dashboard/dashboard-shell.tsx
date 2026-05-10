'use client'

import { useState } from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { cn } from '@/lib/utils'
import { DashboardHeader } from './dashboard-header'
import {
  LayoutDashboard,
  Wrench,
  Package,
  ClipboardList,
  Users,
  Settings,
  BarChart3,
  Bell,
  ChevronLeft,
  ChevronRight,
  CheckCircle2,
} from 'lucide-react'
import { RealtimeClock } from './realtime-clock'

interface NavItem {
  title: string
  href: string
  icon: React.ElementType
  roles?: string[]   // undefined = all roles
  badge?: number
}

const NAV_ITEMS: NavItem[] = [
  {
    title: 'Overview',
    href: '/dashboard',
    icon: LayoutDashboard,
  },
  {
    title: 'Maintenance',
    href: '/dashboard/maintenance',
    icon: Wrench,
  },
  {
    title: 'Inventory',
    href: '/dashboard/inventory',
    icon: Package,
    roles: ['super_admin', 'gso_staff'],
  },
  {
    title: 'Marketplace',
    href: '/dashboard/borrowing',
    icon: ClipboardList,
  },
  {
    title: 'Borrow Management',
    href: '/dashboard/borrowing/management',
    icon: CheckCircle2,
    roles: ['super_admin', 'gso_staff', 'department_head'],
  },
  {
    title: 'Reports',
    href: '/dashboard/reports',
    icon: BarChart3,
    roles: ['super_admin', 'gso_staff'],
  },
  {
    title: 'Users',
    href: '/dashboard/settings/users',
    icon: Users,
    roles: ['super_admin', 'gso_staff'],
  },
  {
    title: 'My Profile',
    href: '/dashboard/profile',
    icon: User,
    roles: ['super_admin'],
  },
]

interface DashboardShellProps {
  profile: any
  roles: string[]
  children: React.ReactNode
}

export function DashboardShell({ profile, roles, children }: DashboardShellProps) {
  const pathname = usePathname()
  const [collapsed, setCollapsed] = useState(false)

  const visibleItems = NAV_ITEMS.filter(
    (item) => !item.roles || item.roles.some((r) => roles.includes(r))
  )

  return (
    <div className="flex h-screen overflow-hidden bg-background">
      {/* ── Sidebar ──────────────────────────────────────── */}
      <aside
        className={cn(
          'flex flex-col sidebar-gradient transition-all duration-300 ease-in-out shrink-0 relative',
          collapsed ? 'w-16' : 'w-64'
        )}
      >
        {/* Logo */}
        <div
          className={cn(
            'flex items-center gap-3 px-4 py-5 border-b border-white/10',
            collapsed && 'justify-center px-2'
          )}
        >
          <div className="w-8 h-8 bg-white/20 rounded-lg flex items-center justify-center shrink-0">
            <span className="text-white font-bold text-sm">G</span>
          </div>
          {!collapsed && (
            <div className="animate-fade-in overflow-hidden">
              <p className="text-white font-bold text-sm leading-tight">ISUFST</p>
              <p className="text-blue-300 text-xs">Management Portal</p>
            </div>
          )}
        </div>

        {/* Navigation */}
        <nav className="flex-1 px-2 py-4 space-y-1 overflow-y-auto scrollbar-thin">
          {visibleItems.map((item) => {
            const isActive =
              item.href === '/dashboard'
                ? pathname === '/dashboard'
                : pathname.startsWith(item.href)

            return (
              <Link
                key={item.href}
                href={item.href}
                title={collapsed ? item.title : undefined}
                className={cn(
                  'flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-all duration-150 group',
                  collapsed && 'justify-center px-0',
                  isActive
                    ? 'bg-white/20 text-white shadow-sm'
                    : 'text-blue-200 hover:bg-white/10 hover:text-white'
                )}
              >
                <item.icon
                  size={18}
                  className={cn(
                    'shrink-0 transition-transform duration-150',
                    'group-hover:scale-110',
                    isActive ? 'text-white' : 'text-blue-300'
                  )}
                />
                {!collapsed && (
                  <span className="animate-fade-in">{item.title}</span>
                )}
                {!collapsed && item.badge && (
                  <span className="ml-auto bg-red-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center">
                    {item.badge}
                  </span>
                )}
              </Link>
            )
          })}
        </nav>

        {/* Collapse toggle */}
        <button
          onClick={() => setCollapsed(!collapsed)}
          className="absolute -right-3 top-20 w-6 h-6 bg-sidebar-border border border-white/20 rounded-full flex items-center justify-center text-blue-200 hover:text-white hover:bg-white/20 transition-all z-10"
          title={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
        >
          {collapsed ? <ChevronRight size={12} /> : <ChevronLeft size={12} />}
        </button>

        <RealtimeClock collapsed={collapsed} />

        {/* User info at bottom */}
        {!collapsed && (
          <div className="p-3 border-t border-white/10 animate-fade-in">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-full bg-white/20 flex items-center justify-center shrink-0">
                <span className="text-white text-xs font-bold">
                  {profile?.full_name?.[0]?.toUpperCase() ?? 'U'}
                </span>
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-white text-xs font-medium truncate">
                  {profile?.full_name}
                </p>
                <p className="text-blue-300 text-xs truncate">{profile?.email}</p>
              </div>
            </div>
          </div>
        )}
      </aside>

      {/* ── Main Content ─────────────────────────────────── */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        <DashboardHeader profile={profile} roles={roles} />
        <main className="flex-1 overflow-y-auto p-6 animate-fade-in scrollbar-thin">
          {children}
        </main>
      </div>
    </div>
  )
}
