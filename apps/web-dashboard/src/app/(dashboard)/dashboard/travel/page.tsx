import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { Plus, Search, CalendarDays, MoreVertical, Pencil, CheckCircle2, XCircle } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { 
  Card, 
  CardContent, 
  CardHeader, 
  CardTitle 
} from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import Link from 'next/link'
import { cn } from '@/lib/utils'
import { format } from 'date-fns'

export default async function TravelPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string }>
}) {
  const { q = '' } = await searchParams
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) redirect('/login')

  // Build query
  let query = supabase
    .from('travel_bookings')
    .select(`
      *,
      requester:requester_id(full_name),
      driver:driver_id(full_name),
      vehicle:vehicle_id(plate_number, brand, model)
    `)
    .order('created_at', { ascending: false })

  if (q) query = query.ilike('booking_number', `%${q}%`)

  const { data: bookings } = await query

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Approved':
      case 'Scheduled':
        return 'bg-emerald-500/10 text-emerald-500 border-emerald-500/20'
      case 'Ongoing': 
        return 'bg-blue-500/10 text-blue-500 border-blue-500/20'
      case 'Pending': 
        return 'bg-yellow-500/10 text-yellow-500 border-yellow-500/20'
      case 'Rejected':
      case 'Cancelled': 
        return 'bg-red-500/10 text-red-500 border-red-500/20'
      case 'Completed': 
        return 'bg-gray-500/10 text-gray-500 border-gray-500/20'
      default: return 'bg-gray-500/10 text-gray-500 border-gray-500/20'
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Travel Bookings</h1>
          <p className="text-muted-foreground">
            Manage university travel requests and schedule fleet vehicles.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button asChild className="bg-institutional hover:bg-institutional/90">
            <Link href="/dashboard/travel/new">
              <Plus className="mr-2 h-4 w-4" /> New Booking
            </Link>
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card className="md:col-span-4">
          <CardHeader className="pb-3 flex flex-row items-center justify-between">
            <div className="relative w-full max-w-sm">
              <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search by booking number..."
                className="pl-9"
              />
            </div>
          </CardHeader>
          <CardContent>
            <div className="rounded-md border overflow-hidden">
              <table className="w-full text-sm">
                <thead className="bg-muted/50 border-b">
                  <tr>
                    <th className="px-4 py-3 text-left font-medium">Booking No.</th>
                    <th className="px-4 py-3 text-left font-medium">Requester</th>
                    <th className="px-4 py-3 text-left font-medium">Destination</th>
                    <th className="px-4 py-3 text-left font-medium">Dates</th>
                    <th className="px-4 py-3 text-left font-medium">Vehicle / Driver</th>
                    <th className="px-4 py-3 text-left font-medium">Status</th>
                    <th className="px-4 py-3 text-right font-medium"></th>
                  </tr>
                </thead>
                <tbody className="divide-y">
                  {bookings?.map((booking) => (
                    <tr key={booking.id} className="hover:bg-muted/50 transition-colors group">
                      <td className="px-4 py-4 font-mono font-medium">
                        {booking.booking_number}
                      </td>
                      <td className="px-4 py-4">
                        {booking.requester?.full_name}
                      </td>
                      <td className="px-4 py-4">
                        <div className="flex flex-col">
                          <span className="font-medium">{booking.destination}</span>
                          <span className="text-xs text-muted-foreground line-clamp-1">{booking.purpose}</span>
                        </div>
                      </td>
                      <td className="px-4 py-4 text-[12px]">
                        <div className="flex flex-col text-muted-foreground">
                          <span>{format(new Date(booking.departure_time), 'MMM d, yyyy h:mm a')}</span>
                          <span>to {format(new Date(booking.return_time), 'MMM d, yyyy h:mm a')}</span>
                        </div>
                      </td>
                      <td className="px-4 py-4">
                        {booking.vehicle ? (
                          <div className="flex flex-col">
                            <span className="font-medium">{booking.vehicle.plate_number}</span>
                            <span className="text-[10px] text-muted-foreground">Driver: {booking.driver?.full_name || 'Unassigned'}</span>
                          </div>
                        ) : (
                          <span className="text-[10px] text-muted-foreground italic">Pending Assignment</span>
                        )}
                      </td>
                      <td className="px-4 py-4">
                        <Badge variant="outline" className={cn("text-[10px]", getStatusColor(booking.status))}>
                          {booking.status}
                        </Badge>
                      </td>
                      <td className="px-4 py-4 text-right">
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" size="icon" className="h-8 w-8">
                              <MoreVertical size={14} />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="end">
                            <DropdownMenuItem asChild>
                              <Link href={`/dashboard/travel/${booking.id}`}>
                                <Pencil className="mr-2 h-3.5 w-3.5" /> View / Edit Details
                              </Link>
                            </DropdownMenuItem>
                            {booking.status === 'Pending' && (
                              <>
                                <DropdownMenuSeparator />
                                <DropdownMenuItem className="text-emerald-500">
                                  <CheckCircle2 className="mr-2 h-3.5 w-3.5" /> Approve Request
                                </DropdownMenuItem>
                                <DropdownMenuItem className="text-red-500">
                                  <XCircle className="mr-2 h-3.5 w-3.5" /> Reject Request
                                </DropdownMenuItem>
                              </>
                            )}
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </td>
                    </tr>
                  ))}
                  {(!bookings || bookings.length === 0) && (
                    <tr>
                      <td colSpan={7} className="px-4 py-12 text-center text-muted-foreground">
                        No travel bookings found.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
