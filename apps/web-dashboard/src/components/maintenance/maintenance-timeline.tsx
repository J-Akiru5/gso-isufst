import { cn } from '@/lib/utils'
import { CheckCircle2, Circle, Clock, User, AlertCircle } from 'lucide-react'
import { format } from 'date-fns'

interface TimelineEntry {
  id: string
  status: string
  title: string
  description: string | null
  created_at: string
  performed_by: {
    full_name: string
  } | null
}

interface MaintenanceTimelineProps {
  entries: TimelineEntry[]
}

export function MaintenanceTimeline({ entries }: MaintenanceTimelineProps) {
  if (!entries || entries.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-12 text-muted-foreground">
        <Clock className="h-8 w-8 mb-2 opacity-20" />
        <p>No timeline entries yet.</p>
      </div>
    )
  }

  return (
    <div className="relative space-y-0 pb-4">
      {/* Vertical line */}
      <div className="absolute left-[17px] top-2 bottom-0 w-0.5 bg-muted" />

      {entries.map((entry, index) => {
        const isLast = index === entries.length - 1
        const isRejected = entry.status.includes('Rejected')
        const isCompleted = entry.status === 'Completed' || entry.status === 'Closed'

        return (
          <div key={entry.id} className="relative pl-10 pb-8 last:pb-0">
            {/* Dot */}
            <div 
              className={cn(
                "absolute left-0 top-1 w-9 h-9 rounded-full flex items-center justify-center border-4 border-background z-10",
                isRejected ? "bg-red-500 text-white" : 
                isCompleted ? "bg-emerald-500 text-white" :
                "bg-blue-500 text-white"
              )}
            >
              {isRejected ? <AlertCircle size={14} /> : 
               isCompleted ? <CheckCircle2 size={14} /> : 
               <Clock size={14} />}
            </div>

            <div className="flex flex-col gap-1">
              <div className="flex items-center justify-between gap-4">
                <h4 className="font-semibold text-sm">{entry.title}</h4>
                <span className="text-[10px] text-muted-foreground bg-muted px-2 py-0.5 rounded-full font-medium">
                  {format(new Date(entry.created_at), 'MMM d, h:mm a')}
                </span>
              </div>
              
              {entry.description && (
                <p className="text-xs text-muted-foreground leading-relaxed">
                  {entry.description}
                </p>
              )}

              {entry.performed_by && (
                <div className="flex items-center gap-1.5 mt-1">
                  <div className="w-4 h-4 rounded-full bg-muted flex items-center justify-center overflow-hidden">
                    <User size={10} className="text-muted-foreground" />
                  </div>
                  <span className="text-[10px] text-muted-foreground">
                    by {entry.performed_by.full_name}
                  </span>
                </div>
              )}
            </div>
          </div>
        )
      })}
    </div>
  )
}
