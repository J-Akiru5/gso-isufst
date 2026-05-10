'use client'

import { useRouter } from 'next/navigation'
import { Moon, Sun, Bell, LogOut, User, Settings, Monitor, Smartphone, Users } from 'lucide-react'
import { useTheme } from 'next-themes'
import { toast } from 'sonner'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'


interface DashboardHeaderProps {
  profile: any
  roles: string[]
}

export function DashboardHeader({ profile, roles }: DashboardHeaderProps) {
  const router = useRouter()
  const { theme, setTheme } = useTheme()

  const handleSignOut = async () => {
    const supabase = createClient()
    await supabase.auth.signOut()
    toast.success('Signed out successfully')
    router.push('/login')
    router.refresh()
  }

  const primaryRole = roles[0] ?? 'user'
  const initials = profile?.full_name
    ?.split(' ')
    .map((n: string) => n[0])
    .slice(0, 2)
    .join('')
    .toUpperCase()

  return (
    <header className="h-14 border-b border-border bg-card/80 backdrop-blur-sm flex items-center justify-between px-6 shrink-0">
      {/* Left — breadcrumb placeholder */}
      <div className="flex items-center gap-2 text-sm text-muted-foreground">
        <span className="font-medium text-foreground">GSO Portal</span>
      </div>

      {/* Right — actions */}
      <div className="flex items-center gap-2">
        {/* Mobile App Download */}
        <Button 
          variant="ghost" 
          size="icon" 
          className="h-8 w-8"
          asChild
          title="Download Mobile App"
        >
          <a href="/distribution/isufst_gso.apk" download aria-label="Download mobile app APK" title="Download mobile app APK">
            <Smartphone size={16} />
          </a>
        </Button>

        {/* Theme toggle */}
        <DropdownMenu>
          <DropdownMenuTrigger>
            <Button variant="ghost" size="icon" className="h-8 w-8">
              {theme === 'dark' ? (
                <Moon size={16} />
              ) : theme === 'light' ? (
                <Sun size={16} />
              ) : (
                <Monitor size={16} />
              )}
              <span className="sr-only">Toggle theme</span>
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuItem onClick={() => setTheme('light')}>
              <Sun size={14} className="mr-2" /> Light
            </DropdownMenuItem>
            <DropdownMenuItem onClick={() => setTheme('dark')}>
              <Moon size={14} className="mr-2" /> Dark
            </DropdownMenuItem>
            <DropdownMenuItem onClick={() => setTheme('system')}>
              <Monitor size={14} className="mr-2" /> System
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>

        {/* Notifications */}
        <Button variant="ghost" size="icon" className="h-8 w-8 relative" onClick={() => router.push('/dashboard/notifications')}>
            <Bell size={16} />
            {/* Unread badge — wired up in Phase 4 */}
            <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full" />
            <span className="sr-only">Notifications</span>
        </Button>

        {/* User Panel (Quick Access) */}
        {(roles.includes('super_admin') || roles.includes('gso_staff')) && (
          <Button 
            variant="ghost" 
            size="icon" 
            className="h-8 w-8" 
            onClick={() => router.push('/dashboard/settings/users')}
            title="User Management"
          >
            <Users size={16} />
          </Button>
        )}

        {/* User menu */}
        <DropdownMenu>
          <DropdownMenuTrigger className="flex items-center gap-2 hover:bg-muted rounded-lg px-2 py-1 transition-colors">
              <Avatar className="h-7 w-7">
                <AvatarImage src={profile?.avatar_url ?? ''} />
                <AvatarFallback className="bg-primary text-primary-foreground text-xs">
                  {initials}
                </AvatarFallback>
              </Avatar>
              <div className="hidden sm:block text-left">
                <p className="text-sm font-medium leading-none">
                  {profile?.full_name}
                </p>
                <p className="text-xs text-muted-foreground capitalize mt-0.5">
                  {primaryRole.replace('_', ' ')}
                </p>
              </div>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-52">
            <DropdownMenuLabel className="font-normal">
              <div className="flex flex-col space-y-1">
                <p className="text-sm font-medium">{profile?.full_name}</p>
                <p className="text-xs text-muted-foreground">{profile?.email}</p>
              </div>
            </DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuItem onClick={() => router.push('/dashboard/profile')}>
                <User size={14} className="mr-2" /> Profile
            </DropdownMenuItem>
            {roles.includes('super_admin') && (
              <DropdownMenuItem onClick={() => router.push('/dashboard/profile')}>
                  <Settings size={14} className="mr-2" /> Settings
              </DropdownMenuItem>
            )}
            <DropdownMenuSeparator />
            <DropdownMenuItem
              onClick={handleSignOut}
              className="text-destructive focus:text-destructive"
            >
              <LogOut size={14} className="mr-2" /> Sign Out
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </header>
  )
}
