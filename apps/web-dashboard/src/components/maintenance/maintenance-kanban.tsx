'use client'

import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { format } from 'date-fns'
import { AlertTriangle, Clock, MapPin, User } from 'lucide-react'
import Link from 'next/link'
import { cn } from '@/lib/utils'

interface MaintenanceKanbanProps {
  requests: any[]
}

const COLUMNS = [
  { id: 'Submitted', title: 'New' },
  { id: 'Pending_HOD', title: 'HOD Review' },
  { id: 'Received_GSO', title: 'GSO Queue' },
  { id: 'Assigned', title: 'Assigned' },
  { id: 'In_Progress', title: 'In Progress' },
  { id: 'Completed', title: 'Completed' },
]

export function MaintenanceKanban({ requests }: MaintenanceKanbanProps) {
  return (
    <div className="flex gap-4 overflow-x-auto pb-4 scrollbar-thin h-[calc(100vh-280px)]">
      {COLUMNS.map((column) => {
        const columnRequests = requests.filter(r => r.status === column.id)
        
        return (
          <div key={column.id} className="flex flex-col gap-4 min-w-[300px] w-[300px]">
            <div className="flex items-center justify-between px-2">
              <h3 className="font-semibold text-sm flex items-center gap-2">
                {column.title}
                <Badge variant="secondary" className="text-[10px] h-5 px-1.5 min-w-[20px] justify-center">
                  {columnRequests.length}
                </Badge>
              </h3>
            </div>

            <div className="flex-1 bg-muted/30 rounded-xl p-2 space-y-3 overflow-y-auto scrollbar-none border-2 border-dashed border-transparent hover:border-muted-foreground/10 transition-colors">
              {columnRequests.map((request) => (
                <Link key={request.id} href={`/dashboard/maintenance/${request.id}`}>
                  <Card className="hover:shadow-md transition-all cursor-pointer border-l-4 group" style={{ borderLeftColor: getPriorityColor(request.priority_level) }}>
                    <CardHeader className="p-3 pb-1">
                      <div className="flex items-start justify-between gap-2">
                        <span className="text-[10px] font-mono text-muted-foreground group-hover:text-foreground">
                          {request.request_number}
                        </span>
                        {request.priority_level === 'Urgent' && (
                          <AlertTriangle className="h-3 w-3 text-urgent animate-pulse" />
                        )}
                      </div>
                      <CardTitle className="text-sm line-clamp-2 leading-tight group-hover:text-institutional transition-colors">
                        {request.title}
                      </CardTitle>
                    </CardHeader>
                    <CardContent className="p-3 pt-2 space-y-3">
                      <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
                        <MapPin size={12} />
                        <span className="truncate">{request.building?.name} {request.room?.name && `- ${request.room.name}`}</span>
                      </div>
                      
                      <div className="flex items-center justify-between gap-2 pt-1 border-t border-muted/50 mt-1">
                        <div className="flex items-center gap-1.5">
                          <div className="w-5 h-5 rounded-full bg-institutional/10 flex items-center justify-center text-[10px] font-bold text-institutional border border-institutional/20">
                            {request.requester?.full_name?.[0]}
                          </div>
                          <span className="text-[10px] text-muted-foreground truncate max-w-[80px]">
                            {request.requester?.full_name.split(' ')[0]}
                          </span>
                        </div>
                        <div className="flex items-center gap-1 text-[10px] text-muted-foreground">
                          <Clock size={10} />
                          {format(new Date(request.created_at), 'MMM d')}
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                </Link>
              ))}
              {columnRequests.length === 0 && (
                <div className="h-24 flex items-center justify-center text-muted-foreground/30 border-2 border-dashed rounded-lg">
                  <span className="text-xs">No requests</span>
                </div>
              )}
            </div>
          </div>
        )
      })}
    </div>
  )
}

function getPriorityColor(priority: string) {
  switch (priority) {
    case 'Urgent': return '#9333ea'
    case 'High': return '#dc2626'
    case 'Medium': return '#f59e0b'
    case 'Low': return '#16a34a'
    default: return '#cbd5e1'
  }
}
