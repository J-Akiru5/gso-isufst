"use client"

import * as React from "react"
import { createClient } from "@/lib/supabase/client"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Checkbox } from "@/components/ui/checkbox"
import { Label } from "@/components/ui/label"
import { toast } from "sonner"
import { Loader2 } from "lucide-react"
import useSWR from "swr"

interface Role {
  id: string
  name: string
  display_name: string
}

interface RoleManagementDialogProps {
  user: any
  isOpen: boolean
  onClose: () => void
  onUpdate: () => void
}

export function RoleManagementDialog({ 
  user, 
  isOpen, 
  onClose, 
  onUpdate 
}: RoleManagementDialogProps) {
  const supabase = createClient()
  const [selectedRoleIds, setSelectedRoleIds] = React.useState<string[]>([])
  const [isSaving, setIsSaving] = React.useState(false)

  // Fetch all available roles
  const fetchAllRoles = async () => {
    const { data, error } = await supabase
      .from("roles")
      .select("id, name, display_name")
      .order("name")
    if (error) throw error
    return data as Role[]
  }

  const { data: allRoles, isLoading: rolesLoading } = useSWR("all-system-roles", fetchAllRoles)

  // Initialize selected roles when user or dialog opens
  React.useEffect(() => {
    if (user?.user_roles) {
      const ids = user.user_roles.map((ur: any) => ur.roles?.id).filter(Boolean)
      setSelectedRoleIds(ids)
    } else {
      setSelectedRoleIds([])
    }
  }, [user, isOpen])

  const handleToggleRole = (roleId: string) => {
    setSelectedRoleIds(prev => 
      prev.includes(roleId) 
        ? prev.filter(id => id !== roleId) 
        : [...prev, roleId]
    )
  }

  const handleSave = async () => {
    if (!user) return
    setIsSaving(true)
    try {
      // 1. Get current roles to find differences
      const currentRoleIds = user.user_roles?.map((ur: any) => ur.roles?.id).filter(Boolean) || []
      
      const toAdd = selectedRoleIds.filter(id => !currentRoleIds.includes(id))
      const toRemove = currentRoleIds.filter(id => !selectedRoleIds.includes(id))

      // 2. Perform deletions
      if (toRemove.length > 0) {
        const { error: removeError } = await supabase
          .from("user_roles")
          .delete()
          .eq("user_id", user.id)
          .in("role_id", toRemove)
        
        if (removeError) throw removeError
      }

      // 3. Perform insertions
      if (toAdd.length > 0) {
        const { data: { user: currentUser } } = await supabase.auth.getUser()
        const insertions = toAdd.map(roleId => ({
          user_id: user.id,
          role_id: roleId,
          assigned_by: currentUser?.id
        }))

        const { error: addError } = await supabase
          .from("user_roles")
          .insert(insertions)
        
        if (addError) throw addError
      }

      toast.success("User roles updated successfully")
      onUpdate()
      onClose()
    } catch (err: any) {
      toast.error(err.message || "Failed to update roles")
    } finally {
      setIsSaving(false)
    }
  }

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Manage Roles</DialogTitle>
          <DialogDescription>
            Assign or remove roles for <strong>{user?.full_name}</strong>.
          </DialogDescription>
        </DialogHeader>
        
        <div className="grid gap-4 py-4">
          {rolesLoading ? (
            <div className="flex items-center justify-center py-8">
              <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
            </div>
          ) : (
            <div className="grid gap-3">
              {allRoles?.map((role) => (
                <div key={role.id} className="flex items-center space-x-3 rounded-lg border p-3 hover:bg-muted/50 transition-colors">
                  <Checkbox 
                    id={`role-${role.id}`} 
                    checked={selectedRoleIds.includes(role.id)}
                    onCheckedChange={() => handleToggleRole(role.id)}
                  />
                  <div className="grid gap-1.5 leading-none">
                    <Label 
                      htmlFor={`role-${role.id}`}
                      className="text-sm font-medium leading-none cursor-pointer"
                    >
                      {role.display_name || role.name.replace("_", " ")}
                    </Label>
                    <p className="text-xs text-muted-foreground capitalize">
                      {role.name}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={onClose} disabled={isSaving}>
            Cancel
          </Button>
          <Button onClick={handleSave} disabled={isSaving || rolesLoading}>
            {isSaving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
            Save Changes
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
