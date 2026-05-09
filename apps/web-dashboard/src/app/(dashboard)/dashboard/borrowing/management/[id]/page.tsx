import { createClient } from '@/lib/supabase/server'
import { notFound, redirect } from 'next/navigation'
import { BorrowingActions } from '@/components/borrowing/borrowing-actions'
import { 
  ChevronLeft, 
  User, 
  Package, 
  Calendar, 
  FileText,
  AlertCircle
} from 'lucide-react'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { 
  Card, 
  CardContent, 
  CardHeader, 
  CardTitle 
} from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { cn } from '@/lib/utils'

export default async function LoanDetailPage({
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

  // Fetch loan details
  const { data: loan, error } = await supabase
    .from('equipment_loans')
    .select(`
      *,
      item:inventory_items(*, category:inventory_categories(name)),
      borrower:profiles!equipment_loans_borrower_id_fkey(
        *,
        department:departments(name)
      )
    `)
    .eq('id', id)
    .single()

  if (error || !loan) {
    notFound()
  }

  // Fetch user profile for role-based actions
  const { data: profile } = await supabase
    .from('profiles')
    .select('*, user_roles(roles(name))')
    .eq('id', user.id)
    .single()

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" asChild>
          <Link href="/dashboard/borrowing/management">
            <ChevronLeft className="h-5 w-5" />
          </Link>
        </Button>
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Loan Request Details</h1>
          <p className="text-sm text-muted-foreground font-mono">ID: {loan.id.split('-')[0]}</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="md:col-span-2 space-y-6">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between">
              <CardTitle className="text-lg">Request Information</CardTitle>
              <Badge variant="outline" className={cn(
                loan.status === 'Active' ? 'bg-purple-500/10 text-purple-600' : 
                loan.status === 'Approved' ? 'bg-emerald-500/10 text-emerald-600' : ''
              )}>
                {loan.status.replace('_', ' ')}
              </Badge>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1">
                  <p className="text-[10px] uppercase font-bold text-muted-foreground">Purpose</p>
                  <p className="text-sm">{loan.purpose || 'No purpose stated.'}</p>
                </div>
                <div className="space-y-1 text-right">
                  <p className="text-[10px] uppercase font-bold text-muted-foreground">Quantity Borrowed</p>
                  <p className="text-lg font-bold">{loan.quantity_borrowed} Units</p>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4 pt-4 border-t">
                <div className="flex items-center gap-2">
                  <Calendar className="h-4 w-4 text-muted-foreground" />
                  <div>
                    <p className="text-[10px] uppercase font-bold text-muted-foreground">Pickup Date</p>
                    <p className="text-xs">{new Date(loan.expected_pickup_date).toLocaleDateString()}</p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <Calendar className="h-4 w-4 text-muted-foreground" />
                  <div>
                    <p className="text-[10px] uppercase font-bold text-muted-foreground">Due Return</p>
                    <p className="text-xs">{new Date(loan.expected_return_date).toLocaleDateString()}</p>
                  </div>
                </div>
              </div>

              {loan.status === 'Pending_HOD' && (
                <div className="p-4 bg-orange-50 border border-orange-200 rounded-lg flex gap-3 text-orange-800">
                  <AlertCircle className="h-5 w-5 shrink-0" />
                  <p className="text-xs">
                    This request is currently waiting for **Department Head** approval before it can be processed by GSO.
                  </p>
                </div>
              )}

              <div className="pt-4 border-t">
                <BorrowingActions loan={loan} userProfile={profile} />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Borrower Profile</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-full bg-muted flex items-center justify-center">
                  {loan.borrower?.avatar_url ? (
                    <img src={loan.borrower.avatar_url} className="w-full h-full object-cover rounded-full" />
                  ) : (
                    <User size={24} className="text-muted-foreground" />
                  )}
                </div>
                <div>
                  <p className="font-bold">{loan.borrower?.full_name}</p>
                  <p className="text-xs text-muted-foreground">{loan.borrower?.department?.name || 'Institutional Faculty'}</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        <div className="md:col-span-1 space-y-6">
          <Card className="overflow-hidden">
            <div className="aspect-video bg-muted flex items-center justify-center">
              {loan.item?.image_url ? (
                <img src={loan.item.image_url} alt={loan.item.name} className="w-full h-full object-cover" />
              ) : (
                <Package size={48} className="text-muted-foreground/20" />
              )}
            </div>
            <CardContent className="p-4 space-y-4">
              <div>
                <p className="text-[10px] uppercase font-bold text-muted-foreground">{loan.item?.category?.name}</p>
                <p className="font-bold">{loan.item?.name}</p>
                <p className="text-[10px] font-mono text-muted-foreground">{loan.item?.item_code}</p>
              </div>
              <Button variant="outline" className="w-full text-xs" asChild>
                <Link href={`/dashboard/inventory/${loan.item_id}`}>
                  View Asset Record
                </Link>
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}
