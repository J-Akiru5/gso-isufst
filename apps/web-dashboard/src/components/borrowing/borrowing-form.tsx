'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { zodResolver } from '@hookform/resolvers/zod'
import { useForm } from 'react-hook-form'
import * as z from 'zod'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { toast } from 'sonner'
import { Calendar as CalendarIcon, Loader2, CheckCircle2 } from 'lucide-react'
import { format, addDays, isBefore, startOfToday } from 'date-fns'

const formSchema = z.z.object({
  purpose: z.z.string().min(5, 'Please provide a purpose for borrowing'),
  quantity_borrowed: z.z.number().min(1, 'Quantity must be at least 1'),
  expected_pickup_date: z.z.string().refine((val) => !isBefore(new Date(val), startOfToday()), {
    message: "Pickup date cannot be in the past",
  }),
  expected_return_date: z.z.string().refine((val) => true, {
    message: "Return date must be after pickup date",
  }),
}).refine((data) => !isBefore(new Date(data.expected_return_date), new Date(data.expected_pickup_date)), {
  message: "Return date must be after pickup date",
  path: ["expected_return_date"],
})

interface BorrowingFormProps {
  item: any
  userId: string
}

export function BorrowingForm({ item, userId }: BorrowingFormProps) {
  const router = useRouter()
  const [isSubmitting, setIsSubmitting] = useState(false)
  const supabase = createClient()

  const form = useForm<z.z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      purpose: '',
      quantity_borrowed: 1,
      expected_pickup_date: format(new Date(), 'yyyy-MM-dd'),
      expected_return_date: format(addDays(new Date(), 1), 'yyyy-MM-dd'),
    },
  })

  async function onSubmit(values: z.z.infer<typeof formSchema>) {
    if (values.quantity_borrowed > item.available_quantity) {
      toast.error(`Only ${item.available_quantity} items available`)
      return
    }

    setIsSubmitting(true)
    try {
      // Create loan request
      const { error } = await supabase.from('equipment_loans').insert({
        item_id: item.id,
        borrower_id: userId,
        purpose: values.purpose,
        quantity_borrowed: values.quantity_borrowed,
        expected_pickup_date: values.expected_pickup_date,
        expected_return_date: values.expected_return_date,
        status: 'Pending_HOD', // Initially needs HOD approval
        loan_type: 'reservation',
      })

      if (error) throw error

      toast.success('Reservation request submitted!')
      router.push('/dashboard/borrowing')
      router.refresh()
    } catch (error: any) {
      toast.error(error.message || 'Failed to submit reservation')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
        <div className="bg-muted/30 p-4 rounded-lg border border-dashed flex items-start gap-4 mb-6">
          <Info size={18} className="text-institutional mt-0.5 shrink-0" />
          <div className="text-xs space-y-1">
            <p className="font-semibold text-institutional uppercase">Approval Workflow</p>
            <p className="text-muted-foreground leading-relaxed">
              This request requires approval from your **Department Head** first, then final verification by the **GSO Office** before pickup.
            </p>
          </div>
        </div>

        <FormField
          control={form.control}
          name="quantity_borrowed"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Quantity to Borrow</FormLabel>
              <FormControl>
                <Input 
                  type="number" 
                  max={item.available_quantity} 
                  {...field} 
                  onChange={e => field.onChange(parseInt(e.target.value))}
                />
              </FormControl>
              <FormDescription>
                Max available: {item.available_quantity}
              </FormDescription>
              <FormMessage />
            </FormItem>
          )}
        />

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <FormField
            control={form.control}
            name="expected_pickup_date"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Expected Pickup Date</FormLabel>
                <FormControl>
                  <div className="relative">
                    <CalendarIcon size={16} className="absolute left-3 top-3 text-muted-foreground pointer-events-none" />
                    <Input type="date" className="pl-9" {...field} />
                  </div>
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />
          <FormField
            control={form.control}
            name="expected_return_date"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Expected Return Date</FormLabel>
                <FormControl>
                  <div className="relative">
                    <CalendarIcon size={16} className="absolute left-3 top-3 text-muted-foreground pointer-events-none" />
                    <Input type="date" className="pl-9" {...field} />
                  </div>
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />
        </div>

        <FormField
          control={form.control}
          name="purpose"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Purpose of Borrowing</FormLabel>
              <FormControl>
                <Textarea 
                  placeholder="e.g. For research presentation in Room 201..." 
                  className="min-h-[100px]"
                  {...field} 
                />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <div className="flex justify-end gap-4 pt-4 border-t">
          <Button variant="outline" type="button" onClick={() => router.back()} disabled={isSubmitting}>
            Cancel
          </Button>
          <Button type="submit" className="bg-institutional hover:bg-institutional/90 min-w-[150px]" disabled={isSubmitting}>
            {isSubmitting ? <Loader2 className="animate-spin h-4 w-4 mr-2" /> : <CheckCircle2 size={16} className="mr-2" />}
            Submit Reservation
          </Button>
        </div>
      </form>
    </Form>
  )
}

function Info({ size, className }: { size?: number, className?: string }) {
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={className}><circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/></svg>
}
