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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Card, CardContent } from '@/components/ui/card'
import { toast } from 'sonner'
import { Camera, Upload, X, Loader2 } from 'lucide-react'

const formSchema = z.z.object({
  title: z.z.string().min(5, 'Title must be at least 5 characters'),
  description: z.z.string().min(10, 'Description must be at least 10 characters'),
  category_id: z.z.string().uuid('Please select a category'),
  priority_level: z.z.enum(['Low', 'Medium', 'High', 'Urgent']),
  building_id: z.z.string().uuid('Please select a building'),
  room_id: z.z.string().uuid().optional().nullable(),
  location_detail: z.z.string().optional(),
})

interface MaintenanceRequestFormProps {
  categories: any[]
  buildings: any[]
  userId: string
}

export function MaintenanceRequestForm({
  categories,
  buildings,
  userId,
}: MaintenanceRequestFormProps) {
  const router = useRouter()
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [rooms, setRooms] = useState<any[]>([])
  const [selectedBuilding, setSelectedBuilding] = useState<string | null>(null)
  const [attachments, setAttachments] = useState<File[]>([])
  const supabase = createClient()

  const form = useForm<z.z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      title: '',
      description: '',
      priority_level: 'Medium',
      location_detail: '',
    },
  })

  // Fetch rooms when building changes
  const onBuildingChange = async (buildingId: string) => {
    setSelectedBuilding(buildingId)
    form.setValue('room_id', null)
    
    const { data } = await supabase
      .from('rooms')
      .select('*')
      .eq('building_id', buildingId)
      .order('name')
    
    setRooms(data || [])
  }

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      const newFiles = Array.from(e.target.files)
      setAttachments((prev) => [...prev, ...newFiles])
    }
  }

  const removeAttachment = (index: number) => {
    setAttachments((prev) => prev.filter((_, i) => i !== index))
  }

  async function onSubmit(values: z.z.infer<typeof formSchema>) {
    setIsSubmitting(true)
    try {
      // 1. Create the request
      const { data: request, error: requestError } = await supabase
        .from('maintenance_requests')
        .insert({
          ...values,
          requester_id: userId,
          status: 'Submitted',
        })
        .select()
        .single()

      if (requestError) throw requestError

      // 2. Upload attachments if any
      if (attachments.length > 0) {
        for (const file of attachments) {
          const fileExt = file.name.split('.').pop()
          const fileName = `${request.id}/${Math.random()}.${fileExt}`
          const filePath = `maintenance-photos/${fileName}`

          const { error: uploadError } = await supabase.storage
            .from('maintenance-photos')
            .upload(filePath, file)

          if (uploadError) {
            console.error('Upload error:', uploadError)
            continue
          }

          const { data: { publicUrl } } = supabase.storage
            .from('maintenance-photos')
            .getPublicUrl(filePath)

          await supabase.from('maintenance_attachments').insert({
            request_id: request.id,
            uploaded_by: userId,
            file_url: publicUrl,
            attachment_type: 'issue',
          })
        }
      }

      toast.success('Maintenance request submitted successfully!')
      router.push('/dashboard/maintenance')
      router.refresh()
    } catch (error: any) {
      toast.error(error.message || 'Something went wrong')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-8">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Left Column: Details */}
          <div className="space-y-6">
            <FormField
              control={form.control}
              name="title"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Request Title</FormLabel>
                  <FormControl>
                    <Input placeholder="e.g. Broken AC Unit" {...field} />
                  </FormControl>
                  <FormDescription>
                    Provide a brief, descriptive title for the issue.
                  </FormDescription>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="category_id"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Category</FormLabel>
                  <Select onValueChange={field.onChange} defaultValue={field.value}>
                    <FormControl>
                      <SelectTrigger>
                        <SelectValue placeholder="Select category" />
                      </SelectTrigger>
                    </FormControl>
                    <SelectContent>
                      {categories.map((cat) => (
                        <SelectItem key={cat.id} value={cat.id}>
                          {cat.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="priority_level"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Priority</FormLabel>
                  <Select onValueChange={field.onChange} defaultValue={field.value}>
                    <FormControl>
                      <SelectTrigger>
                        <SelectValue placeholder="Select priority" />
                      </SelectTrigger>
                    </FormControl>
                    <SelectContent>
                      <SelectItem value="Low">Low</SelectItem>
                      <SelectItem value="Medium">Medium</SelectItem>
                      <SelectItem value="High">High</SelectItem>
                      <SelectItem value="Urgent">Urgent</SelectItem>
                    </SelectContent>
                  </Select>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="description"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Description</FormLabel>
                  <FormControl>
                    <Textarea 
                      placeholder="Please describe the issue in detail..." 
                      className="min-h-[120px]"
                      {...field} 
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
          </div>

          {/* Right Column: Location & Photos */}
          <div className="space-y-6">
            <div className="grid grid-cols-2 gap-4">
              <FormField
                control={form.control}
                name="building_id"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Building</FormLabel>
                    <Select 
                      onValueChange={(val) => {
                        field.onChange(val)
                        onBuildingChange(val)
                      }} 
                      defaultValue={field.value}
                    >
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue placeholder="Select building" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {buildings.map((b) => (
                          <SelectItem key={b.id} value={b.id}>
                            {b.name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="room_id"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Room (Optional)</FormLabel>
                    <Select 
                      onValueChange={field.onChange} 
                      value={field.value || undefined}
                      disabled={!selectedBuilding}
                    >
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue placeholder={selectedBuilding ? "Select room" : "Select building first"} />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {rooms.map((r) => (
                          <SelectItem key={r.id} value={r.id}>
                            {r.name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>

            <FormField
              control={form.control}
              name="location_detail"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Specific Location Detail</FormLabel>
                  <FormControl>
                    <Input placeholder="e.g. Near the window, Left side of hallway" {...field} />
                  </FormControl>
                  <FormDescription>
                    Help the technician find the exact spot.
                  </FormDescription>
                  <FormMessage />
                </FormItem>
              )}
            />

            <div className="space-y-4">
              <FormLabel>Photos (Issue Evidence)</FormLabel>
              <div className="grid grid-cols-3 gap-4">
                {attachments.map((file, index) => (
                  <div key={index} className="relative aspect-square rounded-lg border bg-muted overflow-hidden group">
                    <img 
                      src={URL.createObjectURL(file)} 
                      alt="Attachment preview" 
                      className="w-full h-full object-cover"
                    />
                    <button
                      type="button"
                      onClick={() => removeAttachment(index)}
                      className="absolute top-1 right-1 bg-red-500 text-white rounded-full p-1 opacity-0 group-hover:opacity-100 transition-opacity"
                    >
                      <X size={12} />
                    </button>
                  </div>
                ))}
                {attachments.length < 3 && (
                  <label className="aspect-square rounded-lg border-2 border-dashed border-muted-foreground/25 flex flex-col items-center justify-center cursor-pointer hover:bg-muted/50 transition-colors">
                    <Upload className="h-6 w-6 text-muted-foreground mb-2" />
                    <span className="text-xs text-muted-foreground font-medium text-center px-2">
                      Upload Photo
                    </span>
                    <input 
                      type="file" 
                      accept="image/*" 
                      multiple 
                      className="hidden" 
                      onChange={handleFileChange}
                    />
                  </label>
                )}
              </div>
              <p className="text-[0.8rem] text-muted-foreground">
                Up to 3 photos. Max 5MB each.
              </p>
            </div>
          </div>
        </div>

        <div className="flex justify-end gap-4 pt-4 border-t">
          <Button
            type="button"
            variant="outline"
            onClick={() => router.back()}
            disabled={isSubmitting}
          >
            Cancel
          </Button>
          <Button 
            type="submit" 
            className="bg-institutional hover:bg-institutional/90 min-w-[150px]"
            disabled={isSubmitting}
          >
            {isSubmitting ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                Submitting...
              </>
            ) : (
              'Submit Request'
            )}
          </Button>
        </div>
      </form>
    </Form>
  )
}
