"use client"

import * as React from "react"
import { Clock } from "lucide-react"

export function RealtimeClock({ collapsed }: { collapsed?: boolean }) {
  const [time, setTime] = React.useState<Date | null>(null)

  React.useEffect(() => {
    // Set initial time
    setTime(new Date())
    
    // Update time every second
    const interval = setInterval(() => {
      setTime(new Date())
    }, 1000)

    return () => clearInterval(interval)
  }, [])

  if (!time) {
    return (
      <div className="flex items-center gap-3 p-3 text-blue-300">
        <Clock size={16} className="shrink-0" />
        {!collapsed && <span className="text-xs">Loading...</span>}
      </div>
    )
  }

  // Format options for Philippine Standard Time
  const dateOptions: Intl.DateTimeFormatOptions = { 
    weekday: 'short', 
    year: 'numeric', 
    month: 'short', 
    day: 'numeric',
    timeZone: 'Asia/Manila' 
  }
  
  const timeOptions: Intl.DateTimeFormatOptions = { 
    hour: '2-digit', 
    minute: '2-digit', 
    second: '2-digit',
    hour12: true,
    timeZone: 'Asia/Manila' 
  }

  const dateStr = time.toLocaleDateString('en-US', dateOptions)
  const timeStr = time.toLocaleTimeString('en-US', timeOptions)

  return (
    <div className={`p-3 transition-all duration-300 ease-in-out ${collapsed ? 'flex justify-center' : 'border-t border-white/10'}`}>
      <div className={`flex items-center ${collapsed ? 'justify-center' : 'gap-3'}`}>
        <div className="w-8 h-8 rounded-lg bg-blue-500/10 flex items-center justify-center shrink-0">
          <Clock size={16} className="text-blue-300" />
        </div>
        {!collapsed && (
          <div className="flex-1 min-w-0 animate-fade-in">
            <p className="text-white text-sm font-medium tabular-nums tracking-tight">
              {timeStr}
            </p>
            <p className="text-blue-300 text-xs truncate">
              {dateStr}
            </p>
          </div>
        )}
      </div>
    </div>
  )
}
