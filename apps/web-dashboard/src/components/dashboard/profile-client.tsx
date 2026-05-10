"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { Camera, Loader2, KeyRound, Eye, EyeOff } from "lucide-react"
import { createClient } from "@/lib/supabase/client"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
  CardFooter,
} from "@/components/ui/card"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Separator } from "@/components/ui/separator"
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
  user_roles?: { roles?: { display_name: string; name: string } }[]
}

export function ProfileClient({ initialProfile }: { initialProfile: ProfileData }) {
  // ── Fix for React hydration error #418 ──────────────────────────────────
  // createClient() must not be called at module/render top-level during SSR.
  // Wrapping in useMemo ensures it is only evaluated on the client.
  const supabase = React.useMemo(() => createClient(), [])
  // ────────────────────────────────────────────────────────────────────────

  const router = useRouter()

  // ── Profile edit state ───────────────────────────────────────────────────
  const [isEditing, setIsEditing] = React.useState(false)
  const [isLoading, setIsLoading] = React.useState(false)
  const [isUploading, setIsUploading] = React.useState(false)
  const fileInputRef = React.useRef<HTMLInputElement>(null)

  const [formData, setFormData] = React.useState({
    full_name: initialProfile.full_name || "",
    phone: initialProfile.phone || "",
    employee_student_id: initialProfile.employee_student_id || "",
  })

  // ── Change password state ────────────────────────────────────────────────
  const [pwData, setPwData] = React.useState({
    current_password: "",
    new_password: "",
    confirm_password: "",
  })
  const [pwLoading, setPwLoading] = React.useState(false)
  const [showCurrent, setShowCurrent] = React.useState(false)
  const [showNew, setShowNew] = React.useState(false)
  const [showConfirm, setShowConfirm] = React.useState(false)

  // ── Avatar upload ────────────────────────────────────────────────────────
  const handleAvatarUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (!file) return

    if (!file.type.startsWith("image/")) {
      toast.error("Please upload an image file")
      return
    }

    if (file.size > 5 * 1024 * 1024) {
      toast.error("Image size must be less than 5MB")
      return
    }

    setIsUploading(true)
    try {
      const fileExt = file.name.split(".").pop()
      const filePath = `${initialProfile.id}/avatar-${Math.random()
        .toString(36)
        .substring(2)}.${fileExt}`

      const { error: uploadError } = await supabase.storage
        .from("avatars")
        .upload(filePath, file, { upsert: true })

      if (uploadError) throw uploadError

      const {
        data: { publicUrl },
      } = supabase.storage.from("avatars").getPublicUrl(filePath)

      const { error: updateError } = await supabase
        .from("profiles")
        .update({ avatar_url: publicUrl })
        .eq("id", initialProfile.id)

      if (updateError) throw updateError

      toast.success("Profile picture updated")
      router.refresh()
    } catch (err: any) {
      console.error("Upload error:", err)
      toast.error(err.message || "Failed to upload avatar")
    } finally {
      setIsUploading(false)
      if (fileInputRef.current) fileInputRef.current.value = ""
    }
  }

  // ── Profile save ─────────────────────────────────────────────────────────
  const handleSave = async () => {
    setIsLoading(true)
    try {
      const { error } = await supabase
        .from("profiles")
        .update({
          full_name: formData.full_name,
          phone: formData.phone,
          employee_student_id: formData.employee_student_id,
        })
        .eq("id", initialProfile.id)

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

  // ── Change password ──────────────────────────────────────────────────────
  const handleChangePassword = async () => {
    const { current_password, new_password, confirm_password } = pwData

    if (!current_password || !new_password || !confirm_password) {
      toast.error("Please fill in all password fields")
      return
    }

    if (new_password.length < 8) {
      toast.error("New password must be at least 8 characters")
      return
    }

    if (new_password !== confirm_password) {
      toast.error("New passwords do not match")
      return
    }

    if (current_password === new_password) {
      toast.error("New password must be different from the current one")
      return
    }

    setPwLoading(true)
    try {
      // Step 1: Verify current password by re-authenticating
      const { error: signInError } = await supabase.auth.signInWithPassword({
        email: initialProfile.email,
        password: current_password,
      })

      if (signInError) {
        toast.error("Current password is incorrect")
        return
      }

      // Step 2: Update password
      const { error: updateError } = await supabase.auth.updateUser({
        password: new_password,
      })

      if (updateError) throw updateError

      toast.success("Password changed successfully")
      setPwData({ current_password: "", new_password: "", confirm_password: "" })
    } catch (err: any) {
      toast.error(err.message || "Failed to change password")
    } finally {
      setPwLoading(false)
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  const initials = initialProfile.full_name
    ?.split(" ")
    .map((n: string) => n[0])
    .slice(0, 2)
    .join("")
    .toUpperCase()

  const PasswordInput = ({
    id,
    value,
    onChange,
    show,
    onToggle,
    placeholder,
    disabled,
  }: {
    id: string
    value: string
    onChange: (v: string) => void
    show: boolean
    onToggle: () => void
    placeholder?: string
    disabled?: boolean
  }) => (
    <div className="relative">
      <Input
        id={id}
        type={show ? "text" : "password"}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        disabled={disabled}
        className="pr-10"
      />
      <button
        type="button"
        tabIndex={-1}
        onClick={onToggle}
        className="absolute right-2.5 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground transition-colors"
        aria-label={show ? "Hide password" : "Show password"}
      >
        {show ? <EyeOff size={15} /> : <Eye size={15} />}
      </button>
    </div>
  )

  // ── Render ───────────────────────────────────────────────────────────────
  return (
    <div className="max-w-3xl mx-auto space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">My Profile</h1>
        <p className="text-muted-foreground">
          Manage your personal information and view your roles.
        </p>
      </div>

      {/* ── Personal Information Card ─────────────────────────────────────── */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-4">
            {/* Avatar with upload */}
            <div className="relative group">
              <Avatar
                className={cn(
                  "h-20 w-20 transition-all",
                  !isUploading && "group-hover:opacity-80 cursor-pointer"
                )}
                onClick={() => !isUploading && fileInputRef.current?.click()}
              >
                <AvatarImage src={initialProfile.avatar_url || ""} />
                <AvatarFallback className="text-xl bg-primary text-primary-foreground">
                  {initials}
                </AvatarFallback>

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
                onChange={(e) => setFormData({ ...formData, full_name: e.target.value })}
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
                value={isEditing ? formData.phone : initialProfile.phone || "Not provided"}
                onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                disabled={!isEditing}
                placeholder="e.g. 09123456789"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="id_number">Employee / Student ID</Label>
              <Input
                id="id_number"
                value={
                  isEditing
                    ? formData.employee_student_id
                    : initialProfile.employee_student_id || "Not provided"
                }
                onChange={(e) =>
                  setFormData({ ...formData, employee_student_id: e.target.value })
                }
                disabled={!isEditing}
              />
            </div>
            <div className="space-y-2">
              <Label>Department</Label>
              <Input
                value={initialProfile.departments?.name || "No department assigned"}
                disabled
              />
            </div>
          </div>
        </CardContent>

        <CardFooter className="flex justify-end gap-2 border-t pt-6">
          {isEditing ? (
            <>
              <Button
                variant="outline"
                onClick={() => {
                  setIsEditing(false)
                  setFormData({
                    full_name: initialProfile.full_name || "",
                    phone: initialProfile.phone || "",
                    employee_student_id: initialProfile.employee_student_id || "",
                  })
                }}
                disabled={isLoading}
              >
                Cancel
              </Button>
              <Button onClick={handleSave} disabled={isLoading}>
                {isLoading ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" /> Saving…
                  </>
                ) : (
                  "Save Changes"
                )}
              </Button>
            </>
          ) : (
            <Button onClick={() => setIsEditing(true)}>Edit Profile</Button>
          )}
        </CardFooter>
      </Card>

      {/* ── Change Password Card ──────────────────────────────────────────── */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-lg bg-primary/10 flex items-center justify-center shrink-0">
              <KeyRound className="w-4 h-4 text-primary" />
            </div>
            <div>
              <CardTitle className="text-lg">Change Password</CardTitle>
              <CardDescription>
                You must enter your current password to set a new one.
              </CardDescription>
            </div>
          </div>
        </CardHeader>

        <Separator />

        <CardContent className="pt-6 space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* Current password — full width */}
            <div className="space-y-2 md:col-span-2">
              <Label htmlFor="current_password">Current Password</Label>
              <PasswordInput
                id="current_password"
                value={pwData.current_password}
                onChange={(v) => setPwData({ ...pwData, current_password: v })}
                show={showCurrent}
                onToggle={() => setShowCurrent((p) => !p)}
                placeholder="Enter your current password"
                disabled={pwLoading}
              />
            </div>

            {/* New password */}
            <div className="space-y-2">
              <Label htmlFor="new_password">New Password</Label>
              <PasswordInput
                id="new_password"
                value={pwData.new_password}
                onChange={(v) => setPwData({ ...pwData, new_password: v })}
                show={showNew}
                onToggle={() => setShowNew((p) => !p)}
                placeholder="Min. 8 characters"
                disabled={pwLoading}
              />
            </div>

            {/* Confirm new password */}
            <div className="space-y-2">
              <Label htmlFor="confirm_password">Confirm New Password</Label>
              <PasswordInput
                id="confirm_password"
                value={pwData.confirm_password}
                onChange={(v) => setPwData({ ...pwData, confirm_password: v })}
                show={showConfirm}
                onToggle={() => setShowConfirm((p) => !p)}
                placeholder="Re-enter new password"
                disabled={pwLoading}
              />
              {/* Inline mismatch hint */}
              {pwData.confirm_password &&
                pwData.new_password !== pwData.confirm_password && (
                  <p className="text-xs text-destructive">Passwords do not match.</p>
                )}
            </div>
          </div>
        </CardContent>

        <CardFooter className="flex justify-end border-t pt-6">
          <Button
            onClick={handleChangePassword}
            disabled={pwLoading}
            variant="default"
          >
            {pwLoading ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" /> Updating…
              </>
            ) : (
              "Update Password"
            )}
          </Button>
        </CardFooter>
      </Card>
    </div>
  )
}
