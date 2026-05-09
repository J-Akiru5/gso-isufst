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
import { Switch } from '@/components/ui/switch'
import { toast } from 'sonner'
import { Upload, X, Loader2, Box, Barcode } from 'lucide-react'

const formSchema = z.z.object({
  name: z.z.string().min(2, 'Name is required'),
  item_code: z.z.string().min(3, 'Item code is required'),
  description: z.z.string().optional(),
  category_id: z.z.string().uuid('Please select a category'),
  condition: z.z.enum(['New', 'Good', 'Fair', 'Poor', 'For_Disposal']),
  building_id: z.z.string().uuid('Please select a building'),
  room_id: z.z.string().uuid().optional().nullable(),
  quantity: z.z.number().min(1, 'Quantity must be at least 1'),
  is_borrowable: z.z.boolean().default(false),
  serial_number: z.z.string().optional(),
  manufacturer: z.z.string().optional(),
  model: z.z.string().optional(),
  funding_source: z.z.string().optional(),
})

interface InventoryItemFormProps {
  categories: any[]
  buildings: any[]
  initialData?: any
}

export function InventoryItemForm({
  categories,
  buildings,
  initialData,
}: InventoryItemFormProps) {
  const router = useRouter()
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [rooms, setRooms] = useState<any[]>([])
  const [imageFile, setImageFile] = useState<File | null>(null)
  const [imagePreview, setImagePreview] = useState<string | null>(initialData?.image_url || null)
  const supabase = createClient()

  const form = useForm<z.z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: initialData ? {
      ...initialData,
      quantity: Number(initialData.quantity),
    } : {
      name: '',
      item_code: '',
      condition: 'New',
      quantity: 1,
      is_borrowable: false,
    },
  })

  const onBuildingChange = async (buildingId: string) => {
    form.setValue('room_id', null)
    const { data } = await supabase
      .from('rooms')
      .select('*')
      .eq('building_id', buildingId)
      .order('name')
    setRooms(data || [])
  }

  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0]
      setImageFile(file)
      setImagePreview(URL.createObjectURL(file))
    }
  }

  async function onSubmit(values: z.z.infer<typeof formSchema>) {
    setIsSubmitting(true)
    try {
      let finalImageUrl = initialData?.image_url

      // 1. Upload image if changed
      if (imageFile) {
        const fileExt = imageFile.name.split('.').pop()
        const fileName = `${Date.now()}.${fileExt}`
        const filePath = `inventory-images/${fileName}`

        const { error: uploadError } = await supabase.storage
          .from('inventory-images')
          .upload(filePath, imageFile)

        if (uploadError) throw uploadError

        const { data: { publicUrl } } = supabase.storage
          .from('inventory-images')
          .getPublicUrl(filePath)
        
        finalImageUrl = publicUrl
      }

      // 2. Insert or update item
      const itemData = {
        ...values,
        available_quantity: values.quantity, // Initially same as quantity
        image_url: finalImageUrl,
      }

      if (initialData) {
        const { error } = await supabase
          .from('inventory_items')
          .update(itemData)
          .eq('id', initialData.id)
        if (error) throw error
      } else {
        const { error } = await supabase
          .from('inventory_items')
          .insert(itemData)
        if (error) throw error
      }

      toast.success(initialData ? 'Item updated' : 'Item added successfully')
      router.push('/dashboard/inventory')
      router.refresh()
    } catch (error: any) {
      toast.error(error.message || 'Action failed')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-8">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {/* Left: Image Upload */}
          <div className="space-y-4">
            <FormLabel>Item Image</FormLabel>
            <div className="aspect-square rounded-xl border-2 border-dashed flex flex-col items-center justify-center relative overflow-hidden bg-muted/50 group">
              {imagePreview ? (
                <>
                  <img src={imagePreview} className="w-full h-full object-cover" />
                  <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                    <Button 
                      type="button" 
                      variant="destructive" 
                      size="icon" 
                      onClick={() => {
                        setImageFile(null)
                        setImagePreview(null)
                      }}
                    >
                      <X size={16} />
                    </Button>
                  </div>
                </>
              ) : (
                <label className="cursor-pointer flex flex-col items-center gap-2">
                  <Upload size={24} className="text-muted-foreground" />
                  <span className="text-xs text-muted-foreground">Upload Image</span>
                  <input type="file" className="hidden" accept="image/*" onChange={handleImageChange} />
                </label>
              )}
            </div>
            <p className="text-[10px] text-muted-foreground text-center">
              Recommended: 800x800px. Max 2MB.
            </p>
          </div>

          {/* Right: Details */}
          <div className="md:col-span-2 space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <FormField
                control={form.control}
                name="name"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Item Name</FormLabel>
                    <FormControl>
                      <Input placeholder="e.g. Epson L3110 Printer" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="item_code"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Item Code / Property #</FormLabel>
                    <FormControl>
                      <div className="relative">
                        <Barcode size={16} className="absolute left-3 top-3 text-muted-foreground" />
                        <Input className="pl-9" placeholder="ISUFST-GSO-2024-001" {...field} />
                      </div>
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
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
                          <SelectItem key={cat.id} value={cat.id}>{cat.name}</SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="condition"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Current Condition</FormLabel>
                    <Select onValueChange={field.onChange} defaultValue={field.value}>
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue placeholder="Select condition" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        <SelectItem value="New">New</SelectItem>
                        <SelectItem value="Good">Good</SelectItem>
                        <SelectItem value="Fair">Fair</SelectItem>
                        <SelectItem value="Poor">Poor</SelectItem>
                        <SelectItem value="For_Disposal">For Disposal</SelectItem>
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>

            <Separator />

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <FormField
                control={form.control}
                name="quantity"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Total Quantity</FormLabel>
                    <FormControl>
                      <Input type="number" {...field} onChange={e => field.onChange(parseInt(e.target.value))} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="is_borrowable"
                render={({ field }) => (
                  <FormItem className="flex flex-row items-center justify-between rounded-lg border p-3 shadow-sm mt-8">
                    <div className="space-y-0.5">
                      <FormLabel>Borrowable</FormLabel>
                      <FormDescription className="text-[10px]">Allow users to reserve this item</FormDescription>
                    </div>
                    <FormControl>
                      <Switch
                        checked={field.value}
                        onCheckedChange={field.onChange}
                      />
                    </FormControl>
                  </FormItem>
                )}
              />
            </div>

            <Separator />

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <FormField
                control={form.control}
                name="building_id"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Location: Building</FormLabel>
                    <Select onValueChange={(val) => {
                      field.onChange(val)
                      onBuildingChange(val)
                    }} defaultValue={field.value}>
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue placeholder="Select building" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {buildings.map((b) => (
                          <SelectItem key={b.id} value={b.id}>{b.name}</SelectItem>
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
                    <FormLabel>Location: Room</FormLabel>
                    <Select onValueChange={field.onChange} value={field.value || undefined}>
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue placeholder="Select room" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {rooms.map((r) => (
                          <SelectItem key={r.id} value={r.id}>{r.name}</SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>
          </div>
        </div>

        <div className="flex justify-end gap-4 pt-6 border-t">
          <Button variant="outline" type="button" onClick={() => router.back()} disabled={isSubmitting}>
            Cancel
          </Button>
          <Button type="submit" className="bg-institutional hover:bg-institutional/90 min-w-[120px]" disabled={isSubmitting}>
            {isSubmitting ? <Loader2 className="animate-spin h-4 w-4 mr-2" /> : <Box size={16} className="mr-2" />}
            {initialData ? 'Update Item' : 'Add to Inventory'}
          </Button>
        </div>
      </form>
    </Form>
  )
}

function Separator() {
  return <div className="h-px bg-muted w-full my-2" />
}
