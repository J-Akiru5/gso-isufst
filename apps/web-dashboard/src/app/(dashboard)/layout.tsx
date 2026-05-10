import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { DashboardShell } from '@/components/dashboard/dashboard-shell'

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) redirect('/login')

  const { data: profileData } = await supabase
    .from('profiles')
    .select('*, departments(name)')
    .eq('id', user.id)
    .single()
  const profile = profileData as any

  const { data: userRoles } = await supabase
    .from('user_roles')
    .select('roles(name, display_name)')
    .eq('user_id', user.id)

  const roles = userRoles?.map((ur: any) => ur.roles?.name).filter(Boolean) ?? []
  const isSuperAdmin = roles.includes('super_admin')

  if (!profile?.is_approved && !isSuperAdmin) redirect('/pending-approval')

  return (
    <DashboardShell profile={profile} roles={roles}>
      {children}
    </DashboardShell>
  )
}
