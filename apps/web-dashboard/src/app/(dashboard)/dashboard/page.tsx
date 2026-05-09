import type { Metadata } from 'next'
import { createClient } from '@/lib/supabase/server'
import { LayoutDashboard } from 'lucide-react'

export const metadata: Metadata = { title: 'Overview' }

export default async function DashboardPage() {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  const { data: profileData } = await supabase
    .from('profiles')
    .select('full_name')
    .eq('id', user!.id)
    .single()
  const profile = profileData as any

  const greeting = (() => {
    const hour = new Date().getHours()
    if (hour < 12) return 'Good morning'
    if (hour < 18) return 'Good afternoon'
    return 'Good evening'
  })()

  return (
    <div className="space-y-6 animate-slide-up">
      {/* Page header */}
      <div className="flex items-center gap-3">
        <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center">
          <LayoutDashboard className="w-5 h-5 text-primary" />
        </div>
        <div>
          <h1 className="text-xl font-bold">
            {greeting}, {profile?.full_name?.split(' ')[0]}!
          </h1>
          <p className="text-sm text-muted-foreground">
            Here&apos;s what&apos;s happening at the GSO today.
          </p>
        </div>
      </div>

      {/* KPI Cards — placeholder (wired in Phase 5) */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: 'Open Requests', value: '—', color: 'text-amber-500', bg: 'bg-amber-500/10' },
          { label: 'Active Loans', value: '—', color: 'text-blue-500', bg: 'bg-blue-500/10' },
          { label: 'Overdue Items', value: '—', color: 'text-red-500', bg: 'bg-red-500/10' },
          { label: 'Pending Approvals', value: '—', color: 'text-purple-500', bg: 'bg-purple-500/10' },
        ].map((kpi) => (
          <div key={kpi.label} className="bg-card rounded-xl border border-border p-5 space-y-2">
            <p className="text-sm text-muted-foreground">{kpi.label}</p>
            <div className={`text-3xl font-bold ${kpi.color}`}>{kpi.value}</div>
            <div className={`h-1 rounded-full ${kpi.bg} w-full`} />
          </div>
        ))}
      </div>

      {/* Coming soon placeholder */}
      <div className="bg-card rounded-xl border border-border p-8 text-center text-muted-foreground">
        <p className="text-sm">
          Charts and activity feed will be available in Phase 5 (Reporting &amp; Analytics).
        </p>
      </div>
    </div>
  )
}
