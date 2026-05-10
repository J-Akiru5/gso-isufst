import { formatDistanceToNow } from 'date-fns'
import { Activity, Clock, FileText, Wrench } from 'lucide-react'

export interface ActivityItem {
  id: string
  title: string
  description: string | null
  created_at: string
  type: 'maintenance' | 'loan'
  status: string
}

interface RecentActivityProps {
  activities: ActivityItem[]
}

export function RecentActivity({ activities }: RecentActivityProps) {
  if (activities.length === 0) {
    return (
      <div className="bg-card rounded-xl border border-border p-8 text-center mt-6">
        <Activity className="w-8 h-8 text-muted-foreground mx-auto mb-3 opacity-50" />
        <p className="text-sm text-muted-foreground">No recent activity found.</p>
      </div>
    )
  }

  return (
    <div className="bg-card rounded-xl border border-border overflow-hidden mt-6">
      <div className="p-6 border-b border-border bg-muted/20">
        <h2 className="text-lg font-bold flex items-center gap-2">
          <Activity className="w-5 h-5 text-primary" />
          Recent Activity Feed
        </h2>
        <p className="text-sm text-muted-foreground">Latest events across the campus</p>
      </div>
      <div className="p-0">
        <ul className="divide-y divide-border">
          {activities.map((activity) => (
            <li key={activity.id} className="p-4 hover:bg-muted/10 transition-colors flex gap-4">
              <div className="mt-1">
                {activity.type === 'maintenance' ? (
                  <div className="w-8 h-8 rounded-full bg-amber-500/10 flex items-center justify-center text-amber-500">
                    <Wrench className="w-4 h-4" />
                  </div>
                ) : (
                  <div className="w-8 h-8 rounded-full bg-blue-500/10 flex items-center justify-center text-blue-500">
                    <FileText className="w-4 h-4" />
                  </div>
                )}
              </div>
              <div className="flex-1 space-y-1">
                <div className="flex justify-between items-start">
                  <p className="font-medium text-sm text-foreground">{activity.title}</p>
                  <span className="text-xs text-muted-foreground whitespace-nowrap flex items-center gap-1">
                    <Clock className="w-3 h-3" />
                    {formatDistanceToNow(new Date(activity.created_at), { addSuffix: true })}
                  </span>
                </div>
                {activity.description && (
                  <p className="text-sm text-muted-foreground line-clamp-2">
                    {activity.description}
                  </p>
                )}
                <div className="mt-2">
                  <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-secondary/10 text-secondary border border-secondary/20">
                    {activity.status.replace(/_/g, ' ')}
                  </span>
                </div>
              </div>
            </li>
          ))}
        </ul>
      </div>
    </div>
  )
}
