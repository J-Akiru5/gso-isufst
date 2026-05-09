import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { Plus, Filter, Search } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { 
  Card, 
  CardContent, 
  CardDescription, 
  CardHeader, 
  CardTitle 
} from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import Link from 'next/link'
import { MaintenanceKanban } from '@/components/maintenance/maintenance-kanban'
import { LayoutGrid, List as ListIcon } from 'lucide-react'

export default async function MaintenancePage({
  searchParams,
}: {
  searchParams: Promise<{ view?: string; status?: string }>
}) {
  const { view = 'list', status = 'all' } = await searchParams
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) redirect('/login')

  // Fetch profile to check role and department
  const { data: profile } = await supabase
    .from('profiles')
    .select('*, user_roles(roles(name))')
    .eq('id', user.id)
    .single()

  const roles = (profile?.user_roles as any)?.map((ur: any) => ur.roles?.name) ?? []
  const isGSO = roles.includes('gso_staff') || roles.includes('super_admin')
  const isHOD = roles.includes('department_head')
  const isTechnician = roles.includes('technician')

  // Build query
  let query = supabase
    .from('maintenance_requests')
    .select(`
      *,
      requester:profiles!maintenance_requests_requester_id_fkey(full_name, avatar_url),
      category:maintenance_categories(name),
      building:buildings(name),
      room:rooms(name)
    `)
    .order('created_at', { ascending: false })

  // Role-based filtering
  if (isGSO) {
    // See all
  } else if (isHOD) {
    // See own + department (department logic might need adjustment if multiple departments)
    // For now, see own + anyone in same department
  } else if (isTechnician) {
    query = query.eq('assigned_to', user.id)
  } else {
    query = query.eq('requester_id', user.id)
  }

  const { data: requests, error } = await query

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Submitted': return 'bg-blue-500/10 text-blue-500 border-blue-500/20'
      case 'Pending_HOD': return 'bg-yellow-500/10 text-yellow-500 border-yellow-500/20'
      case 'HOD_Approved': return 'bg-green-500/10 text-green-500 border-green-500/20'
      case 'Received_GSO': return 'bg-purple-500/10 text-purple-500 border-purple-500/20'
      case 'In_Progress': return 'bg-orange-500/10 text-orange-500 border-orange-500/20'
      case 'Completed': return 'bg-emerald-500/10 text-emerald-500 border-emerald-500/20'
      case 'Closed': return 'bg-slate-500/10 text-slate-500 border-slate-500/20'
      case 'Cancelled': case 'HOD_Rejected': return 'bg-red-500/10 text-red-500 border-red-500/20'
      default: return 'bg-gray-500/10 text-gray-500 border-gray-500/20'
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Maintenance Requests</h1>
          <p className="text-muted-foreground">
            {isGSO ? 'Manage and track all institutional maintenance tasks.' : 'Track and manage your maintenance requests.'}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <div className="flex items-center border rounded-lg p-1 bg-muted/30 mr-2">
            <Button 
              variant={view === 'list' ? 'secondary' : 'ghost'} 
              size="sm" 
              className="h-8 px-2" 
              asChild
            >
              <Link href={`/dashboard/maintenance?view=list&status=${status}`}>
                <ListIcon className="h-4 w-4 mr-2" /> List
              </Link>
            </Button>
            <Button 
              variant={view === 'kanban' ? 'secondary' : 'ghost'} 
              size="sm" 
              className="h-8 px-2"
              asChild
            >
              <Link href={`/dashboard/maintenance?view=kanban&status=${status}`}>
                <LayoutGrid className="h-4 w-4 mr-2" /> Kanban
              </Link>
            </Button>
          </div>
          <Button asChild className="bg-institutional hover:bg-institutional/90">
            <Link href="/dashboard/maintenance/new">
              <Plus className="mr-2 h-4 w-4" /> New Request
            </Link>
          </Button>
        </div>
      </div>

      <Card>
        <CardHeader className="pb-3">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div className="relative flex-1 max-w-sm">
              <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search requests..."
                className="pl-9"
              />
            </div>
            <div className="flex items-center gap-2">
              <Select defaultValue="all">
                <SelectTrigger className="w-[150px]">
                  <SelectValue placeholder="Status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Statuses</SelectItem>
                  <SelectItem value="Submitted">Submitted</SelectItem>
                  <SelectItem value="In_Progress">In Progress</SelectItem>
                  <SelectItem value="Completed">Completed</SelectItem>
                </SelectContent>
              </Select>
              <Button variant="outline" size="icon">
                <Filter className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {view === 'kanban' ? (
            <MaintenanceKanban requests={requests || []} />
          ) : (
            <div className="rounded-md border overflow-hidden">
              <table className="w-full text-sm">
                <thead className="bg-muted/50 border-b">
                  <tr>
                    <th className="px-4 py-3 text-left font-medium">Request #</th>
                    <th className="px-4 py-3 text-left font-medium">Title</th>
                    <th className="px-4 py-3 text-left font-medium">Category</th>
                    <th className="px-4 py-3 text-left font-medium">Location</th>
                    <th className="px-4 py-3 text-left font-medium">Priority</th>
                    <th className="px-4 py-3 text-left font-medium">Status</th>
                    <th className="px-4 py-3 text-left font-medium text-right">Date</th>
                  </tr>
                </thead>
                <tbody className="divide-y">
                  {requests?.map((request) => (
                    <tr key={request.id} className="hover:bg-muted/50 transition-colors cursor-pointer group">
                      <td className="px-4 py-3 font-mono text-[10px] text-muted-foreground group-hover:text-foreground">
                        {request.request_number}
                      </td>
                      <td className="px-4 py-3 font-medium">
                        <Link href={`/dashboard/maintenance/${request.id}`} className="hover:underline">
                          {request.title}
                        </Link>
                      </td>
                      <td className="px-4 py-3">
                        <Badge variant="secondary" className="text-[10px] font-normal">
                          {request.category?.name || 'Uncategorized'}
                        </Badge>
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">
                        {request.building?.name} {request.room?.name ? `- ${request.room.name}` : ''}
                      </td>
                      <td className="px-4 py-3">
                        <Badge variant="outline" className={cn(
                          "text-[10px]",
                          request.priority_level === 'Urgent' ? 'border-urgent text-urgent' :
                          request.priority_level === 'High' ? 'border-danger text-danger' :
                          'text-muted-foreground'
                        )}>
                          {request.priority_level}
                        </Badge>
                      </td>
                      <td className="px-4 py-3">
                        <Badge className={cn("text-[10px]", getStatusColor(request.status))}>
                          {request.status.replace('_', ' ')}
                        </Badge>
                      </td>
                      <td className="px-4 py-3 text-muted-foreground text-xs text-right">
                        {new Date(request.created_at).toLocaleDateString()}
                      </td>
                    </tr>
                  ))}
                  {(!requests || requests.length === 0) && (
                    <tr>
                      <td colSpan={7} className="px-4 py-12 text-center text-muted-foreground">
                        No maintenance requests found.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
