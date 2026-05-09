import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { 
  CheckCircle2, 
  Clock, 
  XCircle, 
  ArrowRightLeft, 
  User, 
  Box,
  Calendar,
  Search,
  Filter
} from 'lucide-react'
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
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from '@/components/ui/tabs'
import Link from 'next/link'
import { cn } from '@/lib/utils'

export default async function LoanManagementPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; status?: string }>
}) {
  const { q = '', status = 'Pending_GSO' } = await searchParams
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) redirect('/login')

  // Check user role (only GSO or Admin)
  const { data: profile } = await supabase
    .from('profiles')
    .select('*, user_roles(roles(name))')
    .eq('id', user.id)
    .single()
  
  const roles = profile?.user_roles?.map((ur: any) => ur.roles.name) || []
  const isGSO = roles.includes('gso_staff') || roles.includes('super_admin')

  if (!isGSO) redirect('/dashboard')

  // Build query
  let query = supabase
    .from('equipment_loans')
    .select(`
      *,
      item:inventory_items(name, item_code, image_url),
      borrower:profiles!equipment_loans_borrower_id_fkey(full_name, avatar_url)
    `)
    .order('created_at', { ascending: false })

  if (q) query = query.or(`item.name.ilike.%${q}%,borrower.full_name.ilike.%${q}%`)
  
  const { data: loans } = await query

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Pending_HOD': return 'bg-orange-500/10 text-orange-500 border-orange-500/20'
      case 'Pending_GSO': return 'bg-blue-500/10 text-blue-500 border-blue-500/20'
      case 'Approved': return 'bg-emerald-500/10 text-emerald-500 border-emerald-500/20'
      case 'Active': return 'bg-purple-500/10 text-purple-500 border-purple-500/20'
      case 'Returned': return 'bg-gray-500/10 text-gray-500 border-gray-500/20'
      case 'Overdue': return 'bg-red-500/10 text-red-500 border-red-500/20'
      default: return 'bg-gray-500/10 text-gray-500 border-gray-500/20'
    }
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Loan Management</h1>
        <p className="text-muted-foreground">
          Manage equipment releases, returns, and inter-departmental approvals.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-xs font-medium uppercase text-muted-foreground">Pending GSO</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{loans?.filter(l => l.status === 'Pending_GSO').length}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-xs font-medium uppercase text-muted-foreground">Currently Out</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{loans?.filter(l => l.status === 'Active').length}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-xs font-medium uppercase text-muted-foreground">Overdue</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-red-500">{loans?.filter(l => l.status === 'Overdue').length}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-xs font-medium uppercase text-muted-foreground">Total Requests</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{loans?.length}</div>
          </CardContent>
        </Card>
      </div>

      <Tabs defaultValue="all" className="w-full">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <TabsList>
            <TabsTrigger value="all">All Requests</TabsTrigger>
            <TabsTrigger value="pending">Needs Approval</TabsTrigger>
            <TabsTrigger value="active">Active Loans</TabsTrigger>
            <TabsTrigger value="returned">Returned</TabsTrigger>
          </TabsList>
          <div className="relative w-full md:w-64">
            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
            <Input placeholder="Search borrower or item..." className="pl-9" />
          </div>
        </div>

        <TabsContent value="all" className="pt-4">
          <Card>
            <CardContent className="p-0">
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead className="bg-muted/50 border-b">
                    <tr>
                      <th className="px-4 py-3 text-left font-medium">Borrower</th>
                      <th className="px-4 py-3 text-left font-medium">Item</th>
                      <th className="px-4 py-3 text-left font-medium">Date Range</th>
                      <th className="px-4 py-3 text-left font-medium">Status</th>
                      <th className="px-4 py-3 text-right font-medium">Action</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y">
                    {loans?.map((loan) => (
                      <tr key={loan.id} className="hover:bg-muted/50 transition-colors">
                        <td className="px-4 py-4">
                          <div className="flex items-center gap-3">
                            <div className="w-8 h-8 rounded-full bg-muted flex items-center justify-center shrink-0">
                              {loan.borrower?.avatar_url ? (
                                <img src={loan.borrower.avatar_url} className="w-full h-full object-cover rounded-full" />
                              ) : (
                                <User size={14} className="text-muted-foreground" />
                              )}
                            </div>
                            <div>
                              <p className="font-medium leading-none">{loan.borrower?.full_name}</p>
                              <p className="text-[10px] text-muted-foreground mt-1">Student / Faculty</p>
                            </div>
                          </div>
                        </td>
                        <td className="px-4 py-4">
                          <div className="flex items-center gap-3">
                            <div className="w-8 h-8 rounded bg-muted flex items-center justify-center shrink-0">
                              {loan.item?.image_url ? (
                                <img src={loan.item.image_url} className="w-full h-full object-cover rounded" />
                              ) : (
                                <Box size={14} className="text-muted-foreground" />
                              )}
                            </div>
                            <div>
                              <p className="font-medium leading-none">{loan.item?.name}</p>
                              <p className="text-[10px] font-mono text-muted-foreground mt-1">{loan.item?.item_code}</p>
                            </div>
                          </div>
                        </td>
                        <td className="px-4 py-4">
                          <div className="space-y-1">
                            <p className="text-[10px] flex items-center gap-1">
                              <Clock size={10} className="text-muted-foreground" />
                              Out: {new Date(loan.expected_pickup_date).toLocaleDateString()}
                            </p>
                            <p className="text-[10px] flex items-center gap-1">
                              <Calendar size={10} className="text-muted-foreground" />
                              Due: {new Date(loan.expected_return_date).toLocaleDateString()}
                            </p>
                          </div>
                        </td>
                        <td className="px-4 py-4">
                          <Badge variant="outline" className={cn("text-[10px]", getStatusColor(loan.status))}>
                            {loan.status.replace('_', ' ')}
                          </Badge>
                        </td>
                        <td className="px-4 py-4 text-right">
                          <Button variant="ghost" size="sm" asChild>
                            <Link href={`/dashboard/borrowing/management/${loan.id}`}>
                              Manage
                            </Link>
                          </Button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}
