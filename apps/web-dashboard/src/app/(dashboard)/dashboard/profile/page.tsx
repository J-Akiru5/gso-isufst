import { Metadata } from "next"
import { createClient } from "@/lib/supabase/server"
import { redirect } from "next/navigation"
import { ProfileClient } from "@/components/dashboard/profile-client"

export const metadata: Metadata = {
  title: "Profile | GSO Portal",
  description: "Manage your personal information and view your roles.",
}

export default async function ProfilePage() {
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    redirect('/login')
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select(`
      *,
      departments ( name )
    `)
    .eq('id', user.id)
    .single()

  if (!profile) {
    redirect('/login')
  }

  const { data: userRoles } = await supabase
    .from('user_roles')
    .select('roles(display_name, name)')
    .eq('user_id', user.id)

  const profileWithRoles = {
    ...profile,
    user_roles: userRoles || []
  }

  return <ProfileClient initialProfile={profileWithRoles as any} />
}
