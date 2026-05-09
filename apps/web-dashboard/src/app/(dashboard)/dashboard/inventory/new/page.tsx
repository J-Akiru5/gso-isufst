import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { InventoryItemForm } from '@/components/inventory/inventory-item-form'
import { ChevronLeft } from 'lucide-react'
import Link from 'next/link'
import { Button } from '@/components/ui/button'

export default async function NewInventoryPage() {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) redirect('/login')

  // Fetch categories and buildings
  const [categoriesRes, buildingsRes] = await Promise.all([
    supabase.from('inventory_categories').select('*').eq('is_active', true).order('name'),
    supabase.from('buildings').select('*').order('name'),
  ])

  return (
    <div className="max-w-5xl mx-auto space-y-6">
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" asChild>
          <Link href="/dashboard/inventory">
            <ChevronLeft className="h-5 w-5" />
          </Link>
        </Button>
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Add New Item</h1>
          <p className="text-muted-foreground">
            Register a new institutional asset or borrowable equipment in the inventory.
          </p>
        </div>
      </div>

      <div className="bg-card rounded-xl border shadow-sm p-6">
        <InventoryItemForm 
          categories={categoriesRes.data || []}
          buildings={buildingsRes.data || []}
        />
      </div>
    </div>
  )
}
