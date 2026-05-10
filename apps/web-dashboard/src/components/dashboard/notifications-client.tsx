"use client"

import * as React from "react"
import useSWR from "swr"
import { createClient } from "@/lib/supabase/client"
import { formatDistanceToNow } from "date-fns"
import { Bell, Wrench, Package, CheckCircle2, Info, Check } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { toast } from "sonner"
import Link from "next/link"

export function NotificationsClient() {
  const supabase = createClient()

  const fetchNotifications = async () => {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return []

    const { data, error } = await supabase
      .from("notifications")
      .select("*")
      .eq("user_id", user.id)
      .order("created_at", { ascending: false })

    if (error) throw error
    return data
  }

  const { data: notifications, error, isLoading, mutate } = useSWR("user-notifications", fetchNotifications)

  const markAsRead = async (id?: string) => {
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) return

      let query = supabase.from("notifications").update({ is_read: true, read_at: new Date().toISOString() })
      
      if (id) {
        query = query.eq("id", id)
      } else {
        query = query.eq("user_id", user.id).eq("is_read", false)
      }

      const { error } = await query

      if (error) throw error
      
      toast.success(id ? "Notification marked as read" : "All marked as read")
      mutate()
    } catch (err: any) {
      toast.error("Failed to update notifications")
    }
  }

  const getIcon = (type: string) => {
    switch (type) {
      case 'maintenance': return <Wrench className="h-4 w-4 text-orange-500" />
      case 'loan': return <Package className="h-4 w-4 text-blue-500" />
      case 'approval': return <CheckCircle2 className="h-4 w-4 text-emerald-500" />
      default: return <Info className="h-4 w-4 text-gray-500" />
    }
  }

  if (error) return <div className="text-red-500 p-4">Failed to load notifications</div>

  const unreadCount = notifications?.filter(n => !n.is_read).length || 0

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Notifications</h1>
          <p className="text-muted-foreground">
            View your system alerts and updates.
          </p>
        </div>
        {unreadCount > 0 && (
          <Button variant="outline" size="sm" onClick={() => markAsRead()}>
            <Check className="mr-2 h-4 w-4" /> Mark all as read
          </Button>
        )}
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Bell className="h-5 w-5" />
            <CardTitle>Recent Activity</CardTitle>
            {unreadCount > 0 && (
              <Badge variant="secondary" className="ml-2 bg-blue-500/10 text-blue-500 hover:bg-blue-500/20">
                {unreadCount} new
              </Badge>
            )}
          </div>
          <CardDescription>Your latest notifications across the GSO portal.</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {isLoading ? (
              <p className="text-sm text-muted-foreground text-center py-8">Loading...</p>
            ) : notifications?.length === 0 ? (
              <div className="text-center py-12">
                <Bell className="h-12 w-12 text-muted-foreground/50 mx-auto mb-4" />
                <h3 className="text-lg font-medium">No notifications</h3>
                <p className="text-sm text-muted-foreground">You're all caught up!</p>
              </div>
            ) : (
              <div className="grid gap-4">
                {notifications?.map((notification: any) => (
                  <div
                    key={notification.id}
                    className={`flex items-start gap-4 p-4 rounded-lg border transition-colors ${
                      notification.is_read ? 'bg-card' : 'bg-muted/50 border-blue-200 dark:border-blue-800'
                    }`}
                  >
                    <div className="mt-1 shrink-0 p-2 bg-background rounded-full border">
                      {getIcon(notification.type)}
                    </div>
                    <div className="flex-1 space-y-1">
                      <div className="flex items-center justify-between">
                        <p className={`text-sm font-medium ${!notification.is_read && 'text-blue-600 dark:text-blue-400'}`}>
                          {notification.title}
                        </p>
                        <span className="text-xs text-muted-foreground whitespace-nowrap ml-4">
                          {formatDistanceToNow(new Date(notification.created_at), { addSuffix: true })}
                        </span>
                      </div>
                      <p className="text-sm text-muted-foreground">
                        {notification.body}
                      </p>
                      
                      <div className="flex items-center gap-4 mt-2">
                        {notification.action_url && (
                          <Button variant="link" className="h-auto p-0 text-xs" asChild>
                            <Link href={notification.action_url}>View Details</Link>
                          </Button>
                        )}
                        {!notification.is_read && (
                          <Button 
                            variant="ghost" 
                            className="h-auto p-0 text-xs text-muted-foreground hover:text-foreground" 
                            onClick={() => markAsRead(notification.id)}
                          >
                            Mark as read
                          </Button>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
