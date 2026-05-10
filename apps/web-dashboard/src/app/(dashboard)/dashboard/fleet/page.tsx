import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { Plus, Search, Truck, MoreVertical, Pencil, Trash } from 'lucide-react'
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

export default async function FleetPage({
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
    .from('vehicles')
    .select('*')
    .eq('is_active', true)
    .order('plate_number')

  if (q) query = query.ilike('plate_number', `%${q}%`)

  const { data: vehicles } = await query

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Available': return 'bg-emerald-500/10 text-emerald-500 border-emerald-500/20'
      case 'On_Travel': return 'bg-blue-500/10 text-blue-500 border-blue-500/20'
      case 'Under_Maintenance': return 'bg-yellow-500/10 text-yellow-500 border-yellow-500/20'
      case 'Out_of_Service': return 'bg-red-500/10 text-red-500 border-red-500/20'
      default: return 'bg-gray-500/10 text-gray-500 border-gray-500/20'
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Fleet Management</h1>
          <p className="text-muted-foreground">
            Track and manage university vehicles.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button asChild className="bg-institutional hover:bg-institutional/90">
            <Link href="/dashboard/fleet/new">
              <Plus className="mr-2 h-4 w-4" /> Add Vehicle
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
                placeholder="Search by plate number..."
                className="pl-9"
              />
            </div>
          </CardHeader>
          <CardContent>
            <div className="rounded-md border overflow-hidden">
              <table className="w-full text-sm">
                <thead className="bg-muted/50 border-b">
                  <tr>
                    <th className="px-4 py-3 text-left font-medium">Plate Number</th>
                    <th className="px-4 py-3 text-left font-medium">Vehicle</th>
                    <th className="px-4 py-3 text-left font-medium">Type</th>
                    <th className="px-4 py-3 text-left font-medium text-center">Capacity</th>
                    <th className="px-4 py-3 text-left font-medium">Status</th>
                    <th className="px-4 py-3 text-right font-medium"></th>
                  </tr>
                </thead>
                <tbody className="divide-y">
                  {vehicles?.map((vehicle) => (
                    <tr key={vehicle.id} className="hover:bg-muted/50 transition-colors group">
                      <td className="px-4 py-4 font-mono font-medium">
                        {vehicle.plate_number}
                      </td>
                      <td className="px-4 py-4">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded bg-muted flex items-center justify-center shrink-0">
                            <Truck size={14} className="text-muted-foreground" />
                          </div>
                          <div>
                            <p className="font-medium leading-none">{vehicle.brand} {vehicle.model}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-4">
                        <Badge variant="secondary" className="text-[10px] font-normal">
                          {vehicle.vehicle_type}
                        </Badge>
                      </td>
                      <td className="px-4 py-4 text-center font-medium">
                        {vehicle.capacity} Pax
                      </td>
                      <td className="px-4 py-4">
                        <Badge variant="outline" className={cn("text-[10px]", getStatusColor(vehicle.status))}>
                          {vehicle.status.replace('_', ' ')}
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
                              <Link href={`/dashboard/fleet/${vehicle.id}`}>
                                <Pencil className="mr-2 h-3.5 w-3.5" /> Edit Details
                              </Link>
                            </DropdownMenuItem>
                            <DropdownMenuSeparator />
                            <DropdownMenuItem className="text-red-500">
                              <Trash className="mr-2 h-3.5 w-3.5" /> Delete Vehicle
                            </DropdownMenuItem>
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </td>
                    </tr>
                  ))}
                  {(!vehicles || vehicles.length === 0) && (
                    <tr>
                      <td colSpan={6} className="px-4 py-12 text-center text-muted-foreground">
                        No vehicles found.
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
