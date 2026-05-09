'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { 
  CheckCircle2, 
  XCircle, 
  ArrowRightLeft, 
  Loader2,
  AlertCircle,
  PackageCheck,
  Package2
} from 'lucide-react'
import { toast } from 'sonner'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog"

interface BorrowingActionsProps {
  loan: any
  userProfile: any
}

export function BorrowingActions({ loan, userProfile }: BorrowingActionsProps) {
  const router = useRouter()
  const [isLoading, setIsLoading] = useState(false)
  const supabase = createClient()

  const roles = userProfile?.user_roles?.map((ur: any) => ur.roles.name) || []
  const isGSO = roles.includes('gso_staff') || roles.includes('super_admin')
  const isHOD = roles.includes('department_head')

  const updateStatus = async (newStatus: string, successMsg: string) => {
    setIsLoading(true)
    try {
      const { error } = await supabase
        .from('equipment_loans')
        .update({ 
          status: newStatus,
          ...(newStatus === 'Active' ? { actual_pickup_date: new Date().toISOString() } : {}),
          ...(newStatus === 'Returned' ? { actual_return_date: new Date().toISOString() } : {})
        })
        .eq('id', loan.id)

      if (error) throw error

      toast.success(successMsg)
      router.refresh()
    } catch (error: any) {
      toast.error(error.message || 'Operation failed')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="flex flex-wrap gap-3">
      {/* HOD Approval Section */}
      {isHOD && loan.status === 'Pending_HOD' && (
        <>
          <Button 
            className="bg-emerald-600 hover:bg-emerald-700" 
            onClick={() => updateStatus('Pending_GSO', 'Approved and forwarded to GSO')}
            disabled={isLoading}
          >
            <CheckCircle2 className="mr-2 h-4 w-4" /> Approve Request
          </Button>
          <Button 
            variant="destructive"
            onClick={() => updateStatus('Rejected', 'Request rejected')}
            disabled={isLoading}
          >
            <XCircle className="mr-2 h-4 w-4" /> Reject
          </Button>
        </>
      )}

      {/* GSO Release Section */}
      {isGSO && loan.status === 'Approved' && (
        <AlertDialog>
          <AlertDialogTrigger asChild>
            <Button className="bg-institutional hover:bg-institutional/90">
              <PackageCheck className="mr-2 h-4 w-4" /> Release Equipment
            </Button>
          </AlertDialogTrigger>
          <AlertDialogContent>
            <AlertDialogHeader>
              <AlertDialogTitle>Confirm Release</AlertDialogTitle>
              <AlertDialogDescription>
                Are you sure the items have been physically picked up by {loan.borrower?.full_name}? 
                This will mark the loan as **Active**.
              </AlertDialogDescription>
            </AlertDialogHeader>
            <AlertDialogFooter>
              <AlertDialogCancel>Cancel</AlertDialogCancel>
              <AlertDialogAction 
                onClick={() => updateStatus('Active', 'Equipment released successfully')}
                className="bg-institutional"
              >
                Confirm Release
              </AlertDialogAction>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialog>
      )}

      {/* GSO Return Section */}
      {isGSO && (loan.status === 'Active' || loan.status === 'Overdue') && (
        <AlertDialog>
          <AlertDialogTrigger asChild>
            <Button variant="outline" className="border-emerald-500 text-emerald-600 hover:bg-emerald-50">
              <ArrowRightLeft className="mr-2 h-4 w-4" /> Process Return
            </Button>
          </AlertDialogTrigger>
          <AlertDialogContent>
            <AlertDialogHeader>
              <AlertDialogTitle>Confirm Return</AlertDialogTitle>
              <AlertDialogDescription>
                Confirm that all {loan.quantity_borrowed} units of **{loan.item?.name}** have been returned in good condition.
              </AlertDialogDescription>
            </AlertDialogHeader>
            <AlertDialogFooter>
              <AlertDialogCancel>Cancel</AlertDialogCancel>
              <AlertDialogAction 
                onClick={() => updateStatus('Returned', 'Equipment marked as returned')}
                className="bg-emerald-600 hover:bg-emerald-700"
              >
                Confirm Return
              </AlertDialogAction>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialog>
      )}

      {loan.status === 'Pending_GSO' && isGSO && (
        <Button 
          className="bg-emerald-600 hover:bg-emerald-700" 
          onClick={() => updateStatus('Approved', 'Request verified and ready for pickup')}
          disabled={isLoading}
        >
          <CheckCircle2 className="mr-2 h-4 w-4" /> Verify & Ready
        </Button>
      )}

      {isLoading && <Loader2 className="animate-spin h-5 w-5 text-muted-foreground self-center" />}
    </div>
  )
}
