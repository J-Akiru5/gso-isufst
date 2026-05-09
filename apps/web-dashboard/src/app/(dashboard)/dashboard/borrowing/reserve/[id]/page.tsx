import { createClient } from '@/lib/supabase/server'
import { notFound, redirect } from 'next/navigation'
import { BorrowingForm } from '@/components/borrowing/borrowing-form'
import { ChevronLeft, Package, MapPin, BadgeInfo } from 'lucide-react'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'

export default async function ReserveItemPage({
  params,
}: {
  params: { id: string }
}) {
  const { id } = await params
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) redirect('/login')

  // Fetch item details
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

  if (error || !item || !item.is_borrowable) {
    notFound()
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" asChild>
          <Link href="/dashboard/borrowing">
            <ChevronLeft className="h-5 w-5" />
          </Link>
        </Button>
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Reserve Equipment</h1>
          <p className="text-muted-foreground">
            Complete the form below to request this item.
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Item Preview Card */}
        <div className="md:col-span-1">
          <Card className="sticky top-6">
            <div className="aspect-square bg-muted">
              {item.image_url ? (
                <img src={item.image_url} className="w-full h-full object-cover" />
              ) : (
                <div className="w-full h-full flex items-center justify-center text-muted-foreground/20">
                  <Package size={64} />
                </div>
              )}
            </div>
            <CardContent className="p-4 space-y-4">
              <div>
                <p className="text-[10px] uppercase font-bold text-muted-foreground">{item.category?.name}</p>
                <h2 className="text-lg font-bold">{item.name}</h2>
              </div>
              
              <div className="space-y-2">
                <div className="flex items-center gap-2 text-xs text-muted-foreground">
                  <MapPin size={12} />
                  <span>{item.building?.name} {item.room?.name && `- ${item.room.name}`}</span>
                </div>
                <div className="flex items-center gap-2 text-xs text-muted-foreground">
                  <BadgeInfo size={12} />
                  <span>Available: {item.available_quantity}</span>
                </div>
              </div>

              {item.description && (
                <p className="text-xs text-muted-foreground leading-relaxed border-t pt-3">
                  {item.description}
                </p>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Form Column */}
        <div className="md:col-span-2">
          <div className="bg-card rounded-xl border shadow-sm p-6">
            <BorrowingForm 
              item={item}
              userId={user.id}
            />
          </div>
        </div>
      </div>
    </div>
  )
}
