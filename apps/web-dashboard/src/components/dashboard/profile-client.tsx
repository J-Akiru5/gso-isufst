"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { Camera, Loader2 } from "lucide-react"
import { createClient } from "@/lib/supabase/client"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from "@/components/ui/card"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { toast } from "sonner"
import { Badge } from "@/components/ui/badge"
import { cn } from "@/lib/utils"

interface ProfileData {
  id: string
  full_name: string
  email: string
  phone: string | null
  department_id: string | null
  employee_student_id: string | null
  avatar_url: string | null
  departments?: { name: string } | null
  user_roles?: { roles?: { display_name: string, name: string } }[]
}

export function ProfileClient({ initialProfile }: { initialProfile: ProfileData }) {
  const supabase = createClient()
  const router = useRouter()
  const [isEditing, setIsEditing] = React.useState(false)
  const [isLoading, setIsLoading] = React.useState(false)
  const [isUploading, setIsUploading] = React.useState(false)
  const fileInputRef = React.useRef<HTMLInputElement>(null)
  
  const [formData, setFormData] = React.useState({
    full_name: initialProfile.full_name || "",
    phone: initialProfile.phone || "",
    employee_student_id: initialProfile.employee_student_id || "",
  })

  const handleAvatarUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (!file) return

    // Validate file type
    if (!file.type.startsWith('image/')) {
      toast.error('Please upload an image file')
      return
    }

    // Validate file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      toast.error('Image size must be less than 5MB')
      return
    }

    setIsUploading(true)
    try {
      const fileExt = file.name.split('.').pop()
      const filePath = `${initialProfile.id}/avatar-${Math.random().toString(36).substring(2)}.${fileExt}`

      // 1. Upload to Supabase Storage
      const { error: uploadError } = await supabase.storage
        .from('avatars')
        .upload(filePath, file, { upsert: true })

      if (uploadError) throw uploadError

      // 2. Get Public URL
      const { data: { publicUrl } } = supabase.storage
        .from('avatars')
        .getPublicUrl(filePath)

      // 3. Update Profile Table
      const { error: updateError } = await supabase
        .from('profiles')
        .update({ avatar_url: publicUrl })
        .eq('id', initialProfile.id)

      if (updateError) throw updateError

      toast.success('Profile picture updated')
      router.refresh()
    } catch (err: any) {
      console.error('Upload error:', err)
      toast.error(err.message || 'Failed to upload avatar')
    } finally {
      setIsUploading(false)
      // Reset input
      if (fileInputRef.current) fileInputRef.current.value = ''
    }
  }

  const handleSave = async () => {
    setIsLoading(true)
    try {
      const { error } = await supabase
        .from('profiles')
        .update({
          full_name: formData.full_name,
          phone: formData.phone,
          employee_student_id: formData.employee_student_id,
        })
        .eq('id', initialProfile.id)

      if (error) throw error
      
      toast.success("Profile updated successfully")
      setIsEditing(false)
      router.refresh()
    } catch (err: any) {
      toast.error(err.message || "Failed to update profile")
    } finally {
      setIsLoading(false)
    }
  }

  const initials = initialProfile.full_name
    ?.split(' ')
    .map((n: string) => n[0])
    .slice(0, 2)
    .join('')
    .toUpperCase()

  return (
    <div className="max-w-3xl mx-auto space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">My Profile</h1>
        <p className="text-muted-foreground">
          Manage your personal information and view your roles.
        </p>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center gap-4">
            <div className="relative group">
              <Avatar className={cn(
                "h-20 w-20 transition-all",
                !isUploading && "group-hover:opacity-80 cursor-pointer"
              )} onClick={() => !isUploading && fileInputRef.current?.click()}>
                <AvatarImage src={initialProfile.avatar_url || ""} />
                <AvatarFallback className="text-xl bg-primary text-primary-foreground">{initials}</AvatarFallback>
                
                {isUploading ? (
                  <div className="absolute inset-0 flex items-center justify-center bg-black/40 rounded-full">
                    <Loader2 className="h-6 w-6 animate-spin text-white" />
                  </div>
                ) : (
                  <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 bg-black/20 rounded-full transition-opacity">
                    <Camera className="h-6 w-6 text-white" />
                  </div>
                )}
              </Avatar>
              <input 
                type="file" 
                ref={fileInputRef} 
                className="hidden" 
                accept="image/*"
                onChange={handleAvatarUpload}
                disabled={isUploading}
              />
            </div>
            <div>
              <CardTitle className="text-2xl">{initialProfile.full_name}</CardTitle>
              <CardDescription className="text-base">{initialProfile.email}</CardDescription>
              <div className="flex flex-wrap gap-2 mt-2">
                {initialProfile.user_roles?.map((ur, idx) => (
                  <Badge key={idx} variant="secondary">
                    {ur.roles?.display_name || ur.roles?.name.replace("_", " ")}
                  </Badge>
                ))}
              </div>
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-2">
              <Label htmlFor="full_name">Full Name</Label>
              <Input 
                id="full_name" 
                value={isEditing ? formData.full_name : initialProfile.full_name} 
                onChange={(e) => setFormData({...formData, full_name: e.target.value})}
                disabled={!isEditing} 
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="email">Email Address</Label>
              <Input id="email" value={initialProfile.email} disabled />
              <p className="text-xs text-muted-foreground">Email address cannot be changed.</p>
            </div>
            <div className="space-y-2">
              <Label htmlFor="phone">Phone Number</Label>
              <Input 
                id="phone" 
                value={isEditing ? formData.phone : (initialProfile.phone || "Not provided")} 
                onChange={(e) => setFormData({...formData, phone: e.target.value})}
                disabled={!isEditing} 
                placeholder="e.g. 09123456789"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="id_number">Employee/Student ID</Label>
              <Input 
                id="id_number" 
                value={isEditing ? formData.employee_student_id : (initialProfile.employee_student_id || "Not provided")} 
                onChange={(e) => setFormData({...formData, employee_student_id: e.target.value})}
                disabled={!isEditing} 
              />
            </div>
            <div className="space-y-2">
              <Label>Department</Label>
              <Input value={initialProfile.departments?.name || "No department assigned"} disabled />
            </div>
          </div>
        </CardContent>
        <CardFooter className="flex justify-end gap-2 border-t pt-6">
          {isEditing ? (
            <>
              <Button variant="outline" onClick={() => {
                setIsEditing(false)
                setFormData({
                  full_name: initialProfile.full_name || "",
                  phone: initialProfile.phone || "",
                  employee_student_id: initialProfile.employee_student_id || "",
                })
              }} disabled={isLoading}>Cancel</Button>
              <Button onClick={handleSave} disabled={isLoading}>
                {isLoading ? "Saving..." : "Save Changes"}
              </Button>
            </>
          ) : (
            <Button onClick={() => setIsEditing(true)}>Edit Profile</Button>
          )}
        </CardFooter>
      </Card>
    </div>
  )
}
