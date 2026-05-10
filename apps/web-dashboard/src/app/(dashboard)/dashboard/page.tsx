import type { Metadata } from 'next'
import { createClient } from '@/lib/supabase/server'
import { LayoutDashboard } from 'lucide-react'
import { OverviewCharts } from '@/components/dashboard/overview-charts'
import { RecentActivity, ActivityItem } from '@/components/dashboard/recent-activity'
import { format, subMonths } from 'date-fns'

export const metadata: Metadata = { title: 'Overview' }

export default async function DashboardPage() {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  const { data: profileData } = await supabase
    .from('profiles')
    .select('full_name, id')
    .eq('id', user!.id)
    .single()
  const profile = profileData as any

  const greeting = (() => {
    const hour = new Date().getHours()
    if (hour < 12) return 'Good morning'
    if (hour < 18) return 'Good afternoon'
    return 'Good evening'
  })()

  // --- Fetch KPIs ---
  // Open Requests (Not completed/closed/cancelled)
  const { count: openRequests } = await supabase
    .from('maintenance_requests')
    .select('*', { count: 'exact', head: true })
    .not('status', 'in', '("Completed","Verified","Closed","Cancelled")')

  // Active Loans (Released or In_Use)
  const { count: activeLoans } = await supabase
    .from('equipment_loans')
    .select('*', { count: 'exact', head: true })
    .in('status', ['Released', 'In_Use'])

  // Overdue Items
  const { count: overdueItems } = await supabase
    .from('equipment_loans')
    .select('*', { count: 'exact', head: true })
    .eq('status', 'Overdue')

  // Pending Approvals (For simplicity, checking Pending_HOD or Pending_GSO)
  const { count: pendingLoans } = await supabase
    .from('equipment_loans')
    .select('*', { count: 'exact', head: true })
    .in('status', ['Pending_HOD', 'Pending_GSO'])

  const { count: pendingMaintenance } = await supabase
    .from('maintenance_requests')
    .select('*', { count: 'exact', head: true })
    .in('status', ['Pending_HOD', 'Received_GSO'])

  const totalPending = (pendingLoans || 0) + (pendingMaintenance || 0)

  // --- Fetch Chart Data ---
  // 1. Monthly Maintenance Requests (Last 6 months)
  const { data: maintenanceData } = await supabase
    .from('maintenance_requests')
    .select('created_at')
    .gte('created_at', subMonths(new Date(), 6).toISOString())

  const monthlyCounts: Record<string, number> = {}
  // Initialize last 6 months to 0
  for (let i = 5; i >= 0; i--) {
    const month = format(subMonths(new Date(), i), 'MMM yyyy')
    monthlyCounts[month] = 0
  }
  
  if (maintenanceData) {
    maintenanceData.forEach((req) => {
      const month = format(new Date(req.created_at), 'MMM yyyy')
      if (monthlyCounts[month] !== undefined) {
        monthlyCounts[month]++
      }
    })
  }
  const monthlyChartData = Object.entries(monthlyCounts).map(([month, requests]) => ({ month, requests }))

  // 2. Equipment Utilization
  const { count: totalItems } = await supabase
    .from('inventory_items')
    .select('*', { count: 'exact', head: true })
    .eq('is_borrowable', true)

  const { data: borrowedLoans } = await supabase
    .from('equipment_loans')
    .select('quantity_borrowed')
    .in('status', ['Released', 'In_Use'])

  const currentlyBorrowed = borrowedLoans?.reduce((acc, curr) => acc + (curr.quantity_borrowed || 0), 0) || 0
  const available = Math.max((totalItems || 0) - currentlyBorrowed, 0)

  const utilizationData = [
    { name: 'Borrowed', value: currentlyBorrowed, color: '#f59e0b' },
    { name: 'Available', value: available, color: '#10b981' },
  ]

  // --- Fetch Recent Activity ---
  const { data: maintTimeline } = await supabase
    .from('maintenance_timeline')
    .select('id, title, description, created_at, status')
    .order('created_at', { ascending: false })
    .limit(5)

  const { data: loanTimeline } = await supabase
    .from('loan_timeline')
    .select('id, title, description, created_at, status')
    .order('created_at', { ascending: false })
    .limit(5)

  let combinedActivity: ActivityItem[] = []
  if (maintTimeline) {
    combinedActivity = [...combinedActivity, ...maintTimeline.map(t => ({ ...t, type: 'maintenance' as const }))]
  }
  if (loanTimeline) {
    combinedActivity = [...combinedActivity, ...loanTimeline.map(t => ({ ...t, type: 'loan' as const }))]
  }

  // Sort by newest first and take top 5
  combinedActivity.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
  const recentActivities = combinedActivity.slice(0, 5)

  return (
    <div className="space-y-6 animate-slide-up pb-10">
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

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: 'Open Requests', value: openRequests || 0, color: 'text-amber-500', bg: 'bg-amber-500/10' },
          { label: 'Active Loans', value: activeLoans || 0, color: 'text-blue-500', bg: 'bg-blue-500/10' },
          { label: 'Overdue Items', value: overdueItems || 0, color: 'text-red-500', bg: 'bg-red-500/10' },
          { label: 'Pending Approvals', value: totalPending || 0, color: 'text-purple-500', bg: 'bg-purple-500/10' },
        ].map((kpi) => (
          <div key={kpi.label} className="bg-card rounded-xl border border-border p-5 space-y-2 shadow-sm">
            <p className="text-sm text-muted-foreground">{kpi.label}</p>
            <div className={`text-3xl font-bold ${kpi.color}`}>{kpi.value}</div>
            <div className={`h-1 rounded-full ${kpi.bg} w-full`} />
          </div>
        ))}
      </div>

      {/* Charts Section */}
      <OverviewCharts monthlyData={monthlyChartData} utilizationData={utilizationData} />

      {/* Activity Feed Section */}
      <RecentActivity activities={recentActivities} />
    </div>
  )
}
