'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'
import { toast } from 'sonner'
import { Check, X, UserPlus, Play, CheckCircle2, Archive, Loader2 } from 'lucide-react'

interface MaintenanceActionsProps {
  request: any
  userRole: string[]
  userId: string
  technicians?: any[]
}

export function MaintenanceActions({ 
  request, 
  userRole, 
  userId,
  technicians = []
}: MaintenanceActionsProps) {
  const router = useRouter()
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [reason, setReason] = useState('')
  const [selectedTech, setSelectedTech] = useState<string | null>(null)
  const supabase = createClient()

  const isGSO = userRole.includes('gso_staff') || userRole.includes('super_admin')
  const isHOD = userRole.includes('department_head')
  const isTechnician = userRole.includes('technician')

  const updateStatus = async (newStatus: string, title: string, description?: string) => {
    setIsSubmitting(true)
    try {
      // 1. Update the request
      const updateData: any = { status: newStatus }
      if (newStatus === 'Assigned' && selectedTech) {
        updateData.assigned_to = selectedTech
        updateData.assigned_by = userId
      }
      if (newStatus === 'HOD_Rejected' || newStatus === 'Cancelled') {
        updateData.rejection_reason = reason
      }

      const { error: updateError } = await supabase
        .from('maintenance_requests')
        .update(updateData)
        .eq('id', request.id)

      if (updateError) throw updateError

      // 2. Add to timeline
      const { error: timelineError } = await supabase
        .from('maintenance_timeline')
        .insert({
          request_id: request.id,
          status: newStatus,
          title: title,
          description: description || reason || null,
          performed_by: userId
        })

      if (timelineError) throw timelineError

      toast.success(`Request ${title.toLowerCase()}`)
      router.refresh()
    } catch (error: any) {
      toast.error(error.message || 'Action failed')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="flex flex-wrap items-center gap-2">
      {/* HOD Actions */}
      {isHOD && request.status === 'Pending_HOD' && (
        <>
          <Button 
            variant="outline" 
            className="border-green-500 text-green-500 hover:bg-green-500/10"
            onClick={() => updateStatus('HOD_Approved', 'HOD Approved', 'Approved by Department Head')}
            disabled={isSubmitting}
          >
            <Check className="mr-2 h-4 w-4" /> Approve
          </Button>

          <Dialog>
            <DialogTrigger asChild>
              <Button variant="outline" className="border-red-500 text-red-500 hover:bg-red-500/10">
                <X className="mr-2 h-4 w-4" /> Reject
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Reject Request</DialogTitle>
                <DialogDescription>
                  Please provide a reason for rejecting this maintenance request.
                </DialogDescription>
              </DialogHeader>
              <div className="py-4">
                <Label htmlFor="reason">Rejection Reason</Label>
                <Textarea 
                  id="reason" 
                  placeholder="Reason..." 
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                />
              </div>
              <DialogFooter>
                <Button 
                  variant="destructive" 
                  onClick={() => updateStatus('HOD_Rejected', 'HOD Rejected')}
                  disabled={!reason || isSubmitting}
                >
                  Confirm Rejection
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </>
      )}

      {/* GSO Actions */}
      {isGSO && request.status === 'HOD_Approved' && (
        <Button 
          className="bg-institutional hover:bg-institutional/90"
          onClick={() => updateStatus('Received_GSO', 'Received by GSO', 'Request received and logged by GSO')}
          disabled={isSubmitting}
        >
          <Archive className="mr-2 h-4 w-4" /> Receive Request
        </Button>
      )}

      {isGSO && (request.status === 'Received_GSO' || request.status === 'Assigned') && (
        <Dialog>
          <DialogTrigger asChild>
            <Button className="bg-institutional hover:bg-institutional/90">
              <UserPlus className="mr-2 h-4 w-4" /> 
              {request.assigned_to ? 'Reassign Technician' : 'Assign Technician'}
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Assign Technician</DialogTitle>
              <DialogDescription>
                Select a technician to handle this maintenance request.
              </DialogDescription>
            </DialogHeader>
            <div className="py-4 space-y-4">
              <div className="space-y-2">
                <Label>Technician</Label>
                <Select onValueChange={setSelectedTech}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select technician" />
                  </SelectTrigger>
                  <SelectContent>
                    {technicians.map((tech) => (
                      <SelectItem key={tech.id} value={tech.id}>
                        {tech.full_name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Assignment Notes (Optional)</Label>
                <Textarea 
                  placeholder="Instructions for the technician..." 
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                />
              </div>
            </div>
            <DialogFooter>
              <Button 
                onClick={() => updateStatus('Assigned', 'Technician Assigned', reason)}
                disabled={!selectedTech || isSubmitting}
              >
                Confirm Assignment
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}

      {/* Technician Actions */}
      {isTechnician && request.status === 'Assigned' && (
        <Button 
          className="bg-orange-500 hover:bg-orange-600 text-white"
          onClick={() => updateStatus('In_Progress', 'Started Work', 'Technician has started working on the issue')}
          disabled={isSubmitting}
        >
          <Play className="mr-2 h-4 w-4" /> Start Work
        </Button>
      )}

      {(isTechnician || isGSO) && request.status === 'In_Progress' && (
        <Dialog>
          <DialogTrigger asChild>
            <Button className="bg-emerald-500 hover:bg-emerald-600 text-white">
              <CheckCircle2 className="mr-2 h-4 w-4" /> Mark Completed
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Complete Request</DialogTitle>
              <DialogDescription>
                Describe the work done and any findings.
              </DialogDescription>
            </DialogHeader>
            <div className="py-4">
              <Label>Completion Notes</Label>
              <Textarea 
                placeholder="Resolution details..." 
                value={reason}
                onChange={(e) => setReason(e.target.value)}
              />
            </div>
            <DialogFooter>
              <Button 
                className="bg-emerald-500 hover:bg-emerald-600"
                onClick={() => updateStatus('Completed', 'Work Completed', reason)}
                disabled={!reason || isSubmitting}
              >
                Submit Completion
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}

      {isGSO && request.status === 'Completed' && (
        <Button 
          className="bg-slate-700 hover:bg-slate-800 text-white"
          onClick={() => updateStatus('Closed', 'Closed', 'Verified and closed by GSO staff')}
          disabled={isSubmitting}
        >
          <Archive className="mr-2 h-4 w-4" /> Close Request
        </Button>
      )}

      {isSubmitting && (
        <div className="flex items-center gap-2 text-xs text-muted-foreground animate-pulse">
          <Loader2 className="h-3 w-3 animate-spin" />
          Processing...
        </div>
      )}
    </div>
  )
}
