import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { Search, Filter, Calendar, Info, CheckCircle2, AlertCircle } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { 
  Card, 
  CardContent, 
  CardFooter,
  CardHeader, 
  CardTitle 
} from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import Link from 'next/link'
import { cn } from '@/lib/utils'

export default async function BorrowingPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; category?: string }>
}) {
  const { q = '', category = 'all' } = await searchParams
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) redirect('/login')

  // Fetch categories
  const { data: categories } = await supabase
    .from('inventory_categories')
    .select('*')
    .eq('is_active', true)
    .order('name')

  // Fetch borrowable items
  let query = supabase
    .from('inventory_items')
    .select(`
      *,
      category:inventory_categories(name),
      building:buildings(name)
    `)
    .eq('is_borrowable', true)
    .eq('is_active', true)
    .order('name')

  if (q) query = query.ilike('name', `%${q}%`)
  if (category !== 'all') query = query.eq('category_id', category)

  const { data: items } = await query

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Equipment Borrowing</h1>
          <p className="text-muted-foreground">
            Browse and reserve available equipment for institutional use.
          </p>
        </div>
        <Button asChild variant="outline">
          <Link href="/dashboard/borrowing/my-loans">
            <History className="mr-2 h-4 w-4" /> My Loan Requests
          </Link>
        </Button>
      </div>

      <div className="flex flex-col md:flex-row gap-4 items-center">
        <div className="relative flex-1">
          <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="Search equipment..."
            className="pl-9 bg-background"
          />
        </div>
        <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-none">
          <Button 
            variant={category === 'all' ? 'secondary' : 'outline'} 
            size="sm"
            asChild
          >
            <Link href="/dashboard/borrowing?category=all">All</Link>
          </Button>
          {categories?.map(cat => (
            <Button 
              key={cat.id}
              variant={category === cat.id ? 'secondary' : 'outline'} 
              size="sm"
              asChild
            >
              <Link href={`/dashboard/borrowing?category=${cat.id}`}>{cat.name}</Link>
            </Button>
          ))}
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        {items?.map((item) => (
          <Card key={item.id} className="group overflow-hidden hover:shadow-lg transition-all border-muted/60">
            <div className="aspect-video relative overflow-hidden bg-muted">
              {item.image_url ? (
                <img 
                  src={item.image_url} 
                  className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" 
                />
              ) : (
                <div className="w-full h-full flex items-center justify-center text-muted-foreground/20">
                  <Box size={48} />
                </div>
              )}
              <div className="absolute top-2 right-2">
                <Badge className={cn(
                  item.available_quantity > 0 ? "bg-emerald-500" : "bg-red-500",
                  "shadow-lg"
                )}>
                  {item.available_quantity > 0 ? 'Available' : 'Out of Stock'}
                </Badge>
              </div>
            </div>
            <CardHeader className="p-4 pb-0">
              <p className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">
                {item.category?.name}
              </p>
              <CardTitle className="text-lg line-clamp-1">{item.name}</CardTitle>
            </CardHeader>
            <CardContent className="p-4 pt-2">
              <div className="flex items-center gap-2 text-xs text-muted-foreground mb-4">
                <MapPin size={12} />
                <span>{item.building?.name}</span>
                <span className="mx-1">•</span>
                <span>Qty: {item.available_quantity}/{item.quantity}</span>
              </div>
              <p className="text-xs text-muted-foreground line-clamp-2 h-8">
                {item.description || 'No description available.'}
              </p>
            </CardContent>
            <CardFooter className="p-4 pt-0">
              <Button 
                className="w-full bg-institutional hover:bg-institutional/90" 
                disabled={item.available_quantity <= 0}
                asChild
              >
                <Link href={`/dashboard/borrowing/reserve/${item.id}`}>
                  {item.available_quantity > 0 ? 'Reserve Now' : 'Currently Unavailable'}
                </Link>
              </Button>
            </CardFooter>
          </Card>
        ))}
      </div>
    </div>
  )
}

function History({ className }: { className?: string }) {
  return <path className={className} d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8m0 0V3m0 5h5" />
}

function MapPin({ size, className }: { size?: number, className?: string }) {
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={className}><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/></svg>
}

function Box({ size, className }: { size?: number, className?: string }) {
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={className}><path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"/><path d="m3.3 7 8.7 5 8.7-5"/><path d="M12 22V12"/></svg>
}
