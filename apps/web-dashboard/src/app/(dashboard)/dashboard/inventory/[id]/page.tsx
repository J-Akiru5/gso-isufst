import { createClient } from '@/lib/supabase/server'
import { notFound, redirect } from 'next/navigation'
import { InventoryItemForm } from '@/components/inventory/inventory-item-form'
import { 
  ChevronLeft, 
  Box, 
  History, 
  Info, 
  MapPin, 
  Calendar,
  AlertTriangle,
  ArrowUpRight,
  Trash
} from 'lucide-react'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { 
  Tabs, 
  TabsContent, 
  TabsList, 
  TabsTrigger 
} from '@/components/ui/tabs'
import { 
  Card, 
  CardContent, 
  CardHeader, 
  CardTitle,
  CardDescription
} from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { cn } from '@/lib/utils'

export default async function ItemDetailPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) redirect('/login')

  // Fetch item details with relations
  const { data: item, error } = await supabase
    .from('inventory_items')
    .select(`
      *,
      category:inventory_categories(name),
      building:buildings(name),
      room:rooms(name)
    `)
    .eq('id', id)
    .single()

  if (error || !item) {
    notFound()
  }

  // Fetch borrowing history
  const { data: history } = await supabase
    .from('equipment_loans')
    .select(`
      *,
      borrower:profiles!equipment_loans_borrower_id_fkey(full_name, avatar_url)
    `)
    .eq('item_id', id)
    .order('created_at', { ascending: false })
    .limit(10)

  // Fetch categories and buildings for the edit form
  const [categoriesRes, buildingsRes] = await Promise.all([
    supabase.from('inventory_categories').select('*').eq('is_active', true).order('name'),
    supabase.from('buildings').select('*').order('name'),
  ])

  return (
    <div className="max-w-6xl mx-auto space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="icon" asChild>
            <Link href="/dashboard/inventory">
              <ChevronLeft className="h-5 w-5" />
            </Link>
          </Button>
          <div>
            <h1 className="text-2xl font-bold tracking-tight">{item.name}</h1>
            <p className="text-sm text-muted-foreground font-mono">{item.item_code}</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Badge variant={item.is_borrowable ? "outline" : "secondary"}>
            {item.is_borrowable ? "Borrowable Equipment" : "Fixed Asset"}
          </Badge>
          <Badge className={cn(
            item.available_quantity > 0 ? "bg-emerald-500" : "bg-red-500"
          )}>
            {item.available_quantity} / {item.quantity} Available
          </Badge>
        </div>
      </div>

      <Tabs defaultValue="overview" className="w-full">
        <TabsList className="grid w-full max-w-md grid-cols-3">
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="edit">Edit Item</TabsTrigger>
          <TabsTrigger value="history">History</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-6 pt-4">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <Card className="md:col-span-1 overflow-hidden">
              <div className="aspect-square bg-muted flex items-center justify-center relative">
                {item.image_url ? (
                  <img src={item.image_url} alt={item.name} className="w-full h-full object-cover" />
                ) : (
                  <Box size={80} className="text-muted-foreground/20" />
                )}
              </div>
              <CardContent className="p-4 space-y-4">
                <div className="grid grid-cols-2 gap-4 text-xs">
                  <div>
                    <p className="text-muted-foreground">Manufacturer</p>
                    <p className="font-medium">{item.manufacturer || 'N/A'}</p>
                  </div>
                  <div>
                    <p className="text-muted-foreground">Model</p>
                    <p className="font-medium">{item.model || 'N/A'}</p>
                  </div>
                  <div className="col-span-2">
                    <p className="text-muted-foreground">Serial Number</p>
                    <p className="font-mono font-medium">{item.serial_number || 'N/A'}</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <div className="md:col-span-2 space-y-6">
              <Card>
                <CardHeader className="flex flex-row items-center justify-between">
                  <CardTitle className="text-lg flex items-center gap-2">
                    <Info className="h-5 w-5 text-institutional" />
                    Asset Details
                  </CardTitle>
                  <Button variant="outline" className="text-red-500 border-red-200 hover:bg-red-50 hover:text-red-600 text-xs h-8">
                    <Trash className="mr-2 h-3 w-3" /> Dispose Asset
                  </Button>
                </CardHeader>
                <CardContent className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-4">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full bg-muted flex items-center justify-center">
                        <MapPin size={16} className="text-muted-foreground" />
                      </div>
                      <div>
                        <p className="text-[10px] uppercase font-bold text-muted-foreground">Location</p>
                        <p className="text-sm font-medium">
                          {item.building?.name} {item.room?.name && `- ${item.room.name}`}
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full bg-muted flex items-center justify-center">
                        <Calendar size={16} className="text-muted-foreground" />
                      </div>
                      <div>
                        <p className="text-[10px] uppercase font-bold text-muted-foreground">Acquired</p>
                        <p className="text-sm font-medium">
                          {item.acquisition_date ? new Date(item.acquisition_date).toLocaleDateString() : 'Unknown'}
                        </p>
                      </div>
                    </div>
                  </div>
                  <div className="space-y-4">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full bg-muted flex items-center justify-center">
                        <AlertTriangle size={16} className="text-muted-foreground" />
                      </div>
                      <div>
                        <p className="text-[10px] uppercase font-bold text-muted-foreground">Condition</p>
                        <p className="text-sm font-medium">{item.condition}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full bg-muted flex items-center justify-center">
                        <History size={16} className="text-muted-foreground" />
                      </div>
                      <div>
                        <p className="text-[10px] uppercase font-bold text-muted-foreground">Last Updated</p>
                        <p className="text-sm font-medium">
                          {new Date(item.updated_at).toLocaleDateString()}
                        </p>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="text-lg">Description</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-sm text-muted-foreground leading-relaxed">
                    {item.description || 'No description provided for this item.'}
                  </p>
                </CardContent>
              </Card>
            </div>
          </div>
        </TabsContent>

        <TabsContent value="edit" className="pt-4">
          <Card>
            <CardContent className="pt-6">
              <InventoryItemForm 
                categories={categoriesRes.data || []}
                buildings={buildingsRes.data || []}
                initialData={item}
              />
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="history" className="pt-4">
          <Card>
            <CardHeader>
              <CardTitle>Borrowing & Maintenance History</CardTitle>
              <CardDescription>Recent logs for this asset.</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {history && history.length > 0 ? (
                  history.map((log) => (
                    <div key={log.id} className="flex items-center justify-between p-4 rounded-lg border bg-muted/30">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-full bg-background border flex items-center justify-center overflow-hidden">
                          {log.borrower?.avatar_url ? (
                            <img src={log.borrower.avatar_url} className="w-full h-full object-cover" />
                          ) : (
                            <History className="h-5 w-5 text-muted-foreground" />
                          )}
                        </div>
                        <div>
                          <p className="text-sm font-medium">{log.borrower?.full_name}</p>
                          <p className="text-[10px] text-muted-foreground">
                            {new Date(log.created_at).toLocaleDateString()} • {log.status}
                          </p>
                        </div>
                      </div>
                      <Button variant="ghost" size="sm" asChild>
                        <Link href={`/dashboard/borrowing/${log.id}`}>
                          Details <ArrowUpRight className="ml-2 h-3 w-3" />
                        </Link>
                      </Button>
                    </div>
                  ))
                ) : (
                  <div className="py-12 text-center text-muted-foreground">
                    No history records found for this item.
                  </div>
                )}
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}
