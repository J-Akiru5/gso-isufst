import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { Plus, Search, Filter, Box, MoreVertical, Pencil, Trash, History } from 'lucide-react'
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
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import Link from 'next/link'
import { cn } from '@/lib/utils'

export default async function InventoryPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; category?: string; building?: string }>
}) {
  const { q = '', category = 'all', building = 'all' } = await searchParams
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) redirect('/login')

  // Fetch categories and buildings for filters
  const [categoriesRes, buildingsRes] = await Promise.all([
    supabase.from('inventory_categories').select('*').eq('is_active', true).order('name'),
    supabase.from('buildings').select('*').order('name'),
  ])

  // Build query
  let query = supabase
    .from('inventory_items')
    .select(`
      *,
      category:inventory_categories(name),
      building:buildings(name),
      room:rooms(name)
    `)
    .eq('is_active', true)
    .order('name')

  if (q) query = query.ilike('name', `%${q}%`)
  if (category !== 'all') query = query.eq('category_id', category)
  if (building !== 'all') query = query.eq('building_id', building)

  const { data: items } = await query

  const getConditionColor = (condition: string) => {
    switch (condition) {
      case 'New': return 'bg-emerald-500/10 text-emerald-500 border-emerald-500/20'
      case 'Good': return 'bg-blue-500/10 text-blue-500 border-blue-500/20'
      case 'Fair': return 'bg-yellow-500/10 text-yellow-500 border-yellow-500/20'
      case 'Poor': return 'bg-orange-500/10 text-orange-500 border-orange-500/20'
      case 'For_Disposal': return 'bg-red-500/10 text-red-500 border-red-500/20'
      default: return 'bg-gray-500/10 text-gray-500 border-gray-500/20'
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Inventory Management</h1>
          <p className="text-muted-foreground">
            Track and manage institutional assets and borrowable equipment.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button asChild className="bg-institutional hover:bg-institutional/90">
            <Link href="/dashboard/inventory/new">
              <Plus className="mr-2 h-4 w-4" /> Add Item
            </Link>
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card className="md:col-span-1">
          <CardHeader>
            <CardTitle className="text-sm font-semibold uppercase tracking-wider text-muted-foreground">
              Filters
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <label className="text-xs font-medium">Category</label>
              <Select defaultValue={category}>
                <SelectTrigger>
                  <SelectValue placeholder="All Categories" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Categories</SelectItem>
                  {categoriesRes.data?.map(cat => (
                    <SelectItem key={cat.id} value={cat.id}>{cat.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <label className="text-xs font-medium">Building</label>
              <Select defaultValue={building}>
                <SelectTrigger>
                  <SelectValue placeholder="All Buildings" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Buildings</SelectItem>
                  {buildingsRes.data?.map(b => (
                    <SelectItem key={b.id} value={b.id}>{b.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <Button variant="outline" className="w-full" asChild>
              <Link href="/dashboard/inventory">Reset Filters</Link>
            </Button>
          </CardContent>
        </Card>

        <Card className="md:col-span-3">
          <CardHeader className="pb-3">
            <div className="relative">
              <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search by item name or serial number..."
                className="pl-9"
              />
            </div>
          </CardHeader>
          <CardContent>
            <div className="rounded-md border overflow-hidden">
              <table className="w-full text-sm">
                <thead className="bg-muted/50 border-b">
                  <tr>
                    <th className="px-4 py-3 text-left font-medium">Item Code</th>
                    <th className="px-4 py-3 text-left font-medium">Name</th>
                    <th className="px-4 py-3 text-left font-medium">Category</th>
                    <th className="px-4 py-3 text-left font-medium text-center">Qty</th>
                    <th className="px-4 py-3 text-left font-medium">Condition</th>
                    <th className="px-4 py-3 text-left font-medium">Status</th>
                    <th className="px-4 py-3 text-right font-medium"></th>
                  </tr>
                </thead>
                <tbody className="divide-y">
                  {items?.map((item) => (
                    <tr key={item.id} className="hover:bg-muted/50 transition-colors group">
                      <td className="px-4 py-4 font-mono text-[10px] text-muted-foreground group-hover:text-foreground">
                        {item.item_code}
                      </td>
                      <td className="px-4 py-4">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded bg-muted flex items-center justify-center shrink-0">
                            {item.image_url ? (
                              <img src={item.image_url} className="w-full h-full object-cover rounded" />
                            ) : (
                              <Box size={14} className="text-muted-foreground" />
                            )}
                          </div>
                          <div>
                            <p className="font-medium leading-none">{item.name}</p>
                            <p className="text-[10px] text-muted-foreground mt-1">
                              {item.building?.name} {item.room?.name && `- ${item.room.name}`}
                            </p>
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-4">
                        <Badge variant="secondary" className="text-[10px] font-normal">
                          {item.category?.name || 'Uncategorized'}
                        </Badge>
                      </td>
                      <td className="px-4 py-4 text-center font-medium">
                        {item.quantity}
                      </td>
                      <td className="px-4 py-4">
                        <Badge variant="outline" className={cn("text-[10px]", getConditionColor(item.condition))}>
                          {item.condition}
                        </Badge>
                      </td>
                      <td className="px-4 py-4">
                        {item.is_borrowable ? (
                          <div className="flex items-center gap-2">
                            <div className={cn(
                              "w-2 h-2 rounded-full",
                              item.available_quantity > 0 ? "bg-emerald-500" : "bg-red-500"
                            )} />
                            <span className="text-[10px] font-medium">
                              {item.available_quantity} Available
                            </span>
                          </div>
                        ) : (
                          <span className="text-[10px] text-muted-foreground italic">Fixed Asset</span>
                        )}
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
                              <Link href={`/dashboard/inventory/${item.id}`}>
                                <Pencil className="mr-2 h-3.5 w-3.5" /> Edit Details
                              </Link>
                            </DropdownMenuItem>
                            <DropdownMenuItem asChild>
                              <Link href={`/dashboard/inventory/${item.id}/history`}>
                                <History className="mr-2 h-3.5 w-3.5" /> View History
                              </Link>
                            </DropdownMenuItem>
                            <DropdownMenuSeparator />
                            <DropdownMenuItem className="text-red-500">
                              <Trash className="mr-2 h-3.5 w-3.5" /> Delete Item
                            </DropdownMenuItem>
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </td>
                    </tr>
                  ))}
                  {(!items || items.length === 0) && (
                    <tr>
                      <td colSpan={7} className="px-4 py-12 text-center text-muted-foreground">
                        No inventory items found.
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
