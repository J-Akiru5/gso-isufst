import { createClient } from '@/lib/supabase/server'
import { notFound, redirect } from 'next/navigation'
import { 
  ChevronLeft, 
  Calendar, 
  MapPin, 
  Tag, 
  AlertTriangle, 
  User, 
  Clipboard,
  ExternalLink,
  MessageSquare
} from 'lucide-react'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Separator } from '@/components/ui/separator'
import { MaintenanceTimeline } from '@/components/maintenance/maintenance-timeline'
import { MaintenanceActions } from '@/components/maintenance/maintenance-actions'
import { format } from 'date-fns'

export default async function MaintenanceDetailPage({
  params,
}: {
  params: { id: string }
}) {
  const { id } = await params
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) redirect('/login')

  // Fetch request details with relations
  const { data: request, error } = await supabase
    .from('maintenance_requests')
    .select(`
      *,
      requester:profiles!maintenance_requests_requester_id_fkey(full_name, avatar_url, email, phone, department:departments(name)),
      category:maintenance_categories(name),
      building:buildings(name),
      room:rooms(name),
      technician:profiles!maintenance_requests_assigned_to_fkey(full_name, avatar_url),
      attachments:maintenance_attachments(*),
      timeline:maintenance_timeline(*, performed_by:profiles(full_name))
    `)
    .eq('id', id)
    .single()

  if (error || !request) {
    notFound()
  }

  // Check permissions
  const { data: profile } = await supabase
    .from('profiles')
    .select('*, user_roles(roles(name))')
    .eq('id', user.id)
    .single()

  const roles = (profile?.user_roles as any)?.map((ur: any) => ur.roles?.name) ?? []
  const isGSO = roles.includes('gso_staff') || roles.includes('super_admin')
  const isRequester = request.requester_id === user.id
  const isTechnician = request.assigned_to === user.id

  // Fetch technicians if user is GSO
  let technicians: any[] = []
  if (isGSO) {
    const { data: techData } = await supabase
      .from('profiles')
      .select('id, full_name, user_roles!inner(roles!inner(name))')
      .eq('user_roles.roles.name', 'technician')
    
    technicians = techData || []
  }

  // Sort timeline by date
  const sortedTimeline = [...(request.timeline || [])].sort(
    (a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
  )

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Submitted': return 'bg-blue-500 text-white'
      case 'Pending_HOD': return 'bg-yellow-500 text-white'
      case 'HOD_Approved': return 'bg-green-500 text-white'
      case 'Received_GSO': return 'bg-purple-500 text-white'
      case 'In_Progress': return 'bg-orange-500 text-white'
      case 'Completed': return 'bg-emerald-500 text-white'
      case 'Closed': return 'bg-slate-500 text-white'
      case 'Cancelled': case 'HOD_Rejected': return 'bg-red-500 text-white'
      default: return 'bg-gray-500 text-white'
    }
  }

  return (
    <div className="max-w-6xl mx-auto space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="icon" asChild>
            <Link href="/dashboard/maintenance">
              <ChevronLeft className="h-5 w-5" />
            </Link>
          </Button>
          <div>
            <div className="flex items-center gap-2 mb-1">
              <span className="text-xs font-mono text-muted-foreground uppercase tracking-wider">
                {request.request_number}
              </span>
              <Badge className={getStatusColor(request.status)}>
                {request.status.replace('_', ' ')}
              </Badge>
            </div>
            <h1 className="text-2xl font-bold tracking-tight">{request.title}</h1>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <MaintenanceActions 
            request={request}
            userRole={roles}
            userId={user.id}
            technicians={technicians}
          />
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Side: Details & Photos */}
        <div className="lg:col-span-2 space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg flex items-center gap-2">
                <Clipboard className="h-5 w-5 text-institutional" />
                Request Details
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-1">
                  <span className="text-xs text-muted-foreground font-medium uppercase">Category</span>
                  <div className="flex items-center gap-2">
                    <Tag className="h-4 w-4 text-muted-foreground" />
                    <span>{request.category?.name || 'Uncategorized'}</span>
                  </div>
                </div>
                <div className="space-y-1">
                  <span className="text-xs text-muted-foreground font-medium uppercase">Priority</span>
                  <div className="flex items-center gap-2">
                    <AlertTriangle className={cn(
                      "h-4 w-4",
                      request.priority_level === 'Urgent' ? 'text-urgent' :
                      request.priority_level === 'High' ? 'text-danger' :
                      'text-muted-foreground'
                    )} />
                    <span className={cn(
                      "font-semibold",
                      request.priority_level === 'Urgent' ? 'text-urgent' :
                      request.priority_level === 'High' ? 'text-danger' :
                      ''
                    )}>{request.priority_level}</span>
                  </div>
                </div>
                <div className="space-y-1">
                  <span className="text-xs text-muted-foreground font-medium uppercase">Location</span>
                  <div className="flex items-center gap-2">
                    <MapPin className="h-4 w-4 text-muted-foreground" />
                    <span>
                      {request.building?.name} {request.room?.name ? `- ${request.room.name}` : ''}
                    </span>
                  </div>
                </div>
                <div className="space-y-1">
                  <span className="text-xs text-muted-foreground font-medium uppercase">Submitted On</span>
                  <div className="flex items-center gap-2">
                    <Calendar className="h-4 w-4 text-muted-foreground" />
                    <span>{format(new Date(request.created_at), 'MMMM d, yyyy')}</span>
                  </div>
                </div>
              </div>

              {request.location_detail && (
                <div className="bg-muted/50 p-3 rounded-lg border">
                  <span className="text-xs text-muted-foreground font-medium uppercase block mb-1">Specific Location</span>
                  <p className="text-sm">{request.location_detail}</p>
                </div>
              )}

              <Separator />

              <div className="space-y-2">
                <span className="text-xs text-muted-foreground font-medium uppercase">Description</span>
                <p className="text-sm leading-relaxed whitespace-pre-wrap">
                  {request.description}
                </p>
              </div>

              {request.attachments && request.attachments.length > 0 && (
                <div className="space-y-3">
                  <span className="text-xs text-muted-foreground font-medium uppercase">Attachments</span>
                  <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
                    {request.attachments.map((file: any) => (
                      <div key={file.id} className="group relative aspect-video rounded-lg border bg-muted overflow-hidden">
                        <img 
                          src={file.file_url} 
                          alt="Attachment" 
                          className="w-full h-full object-cover transition-transform group-hover:scale-105"
                        />
                        <a 
                          href={file.file_url} 
                          target="_blank" 
                          rel="noopener noreferrer"
                          className="absolute inset-0 bg-black/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
                        >
                          <ExternalLink className="text-white h-5 w-5" />
                        </a>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-lg flex items-center gap-2">
                <MessageSquare className="h-5 w-5 text-institutional" />
                Comments & Notes
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-center py-8 text-muted-foreground">
                <p className="text-sm italic">Communication feature coming soon...</p>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Right Side: Requester, Technician & Timeline */}
        <div className="space-y-6">
          <Card>
            <CardHeader className="pb-3">
              <CardTitle className="text-sm font-semibold uppercase tracking-wider text-muted-foreground">
                Stakeholders
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-3">
                <span className="text-xs text-muted-foreground font-medium">Requester</span>
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-institutional/10 flex items-center justify-center border text-institutional font-bold">
                    {request.requester?.avatar_url ? (
                      <img src={request.requester.avatar_url} className="w-full h-full rounded-full object-cover" />
                    ) : (
                      request.requester?.full_name?.[0]
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-semibold truncate">{request.requester?.full_name}</p>
                    <p className="text-xs text-muted-foreground truncate">{request.requester?.department?.name || 'No Department'}</p>
                  </div>
                </div>
              </div>

              {request.assigned_to && (
                <div className="space-y-3">
                  <span className="text-xs text-muted-foreground font-medium">Assigned Technician</span>
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-vivid/10 flex items-center justify-center border border-vivid/20 text-vivid font-bold">
                      {request.technician?.avatar_url ? (
                        <img src={request.technician.avatar_url} className="w-full h-full rounded-full object-cover" />
                      ) : (
                        request.technician?.full_name?.[0]
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-semibold truncate">{request.technician?.full_name}</p>
                      <p className="text-xs text-muted-foreground">Assigned to task</p>
                    </div>
                  </div>
                </div>
              )}

              {!request.assigned_to && isGSO && (
                <div className="pt-2">
                  <Button variant="outline" className="w-full text-xs" size="sm">
                    Assign Technician
                  </Button>
                </div>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-3">
              <CardTitle className="text-sm font-semibold uppercase tracking-wider text-muted-foreground">
                Progress Timeline
              </CardTitle>
            </CardHeader>
            <CardContent>
              <MaintenanceTimeline entries={sortedTimeline} />
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}
