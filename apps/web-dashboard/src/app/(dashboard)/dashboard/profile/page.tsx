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
      departments ( name ),
      user_roles ( roles ( display_name, name ) )
    `)
    .eq('id', user.id)
    .single()

  if (!profile) {
    redirect('/login')
  }

  return <ProfileClient initialProfile={profile as any} />
}
