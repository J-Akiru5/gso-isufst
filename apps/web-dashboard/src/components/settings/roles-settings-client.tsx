"use client"

import * as React from "react"
import useSWR from "swr"
import { createClient } from "@/lib/supabase/client"
import { 
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow 
} from "@/components/ui/table"
import { Skeleton } from "@/components/ui/skeleton"
import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { Switch } from "@/components/ui/switch"
import { Plus, Edit2, Trash2, ShieldCheck } from "lucide-react"
import { toast } from "sonner"

const AVAILABLE_PERMISSIONS = [
  { id: "maintenance.view", label: "View Maintenance Requests", description: "Can view and track maintenance jobs" },
  { id: "maintenance.create", label: "Create Maintenance", description: "Can submit new maintenance requests" },
  { id: "maintenance.approve", label: "Approve Maintenance", description: "Can approve or reject maintenance requests" },
  { id: "maintenance.manage", label: "Manage Maintenance", description: "Can assign technicians and update status" },
  { id: "inventory.view", label: "View Inventory", description: "Can view current stock and assets" },
  { id: "inventory.manage", label: "Manage Inventory", description: "Can add/edit items and stock levels" },
  { id: "inventory.request", label: "Request Items", description: "Can request items from inventory" },
  { id: "settings.manage", label: "Manage Settings", description: "Full access to system configuration" },
]

export function RolesSettingsClient() {
  const supabase = createClient()
  const [isOpen, setIsOpen] = React.useState(false)
  const [editingId, setEditingId] = React.useState<string | null>(null)
  
  // Form state
  const [name, setName] = React.useState("")
  const [displayName, setDisplayName] = React.useState("")
  const [description, setDescription] = React.useState("")
  const [permissions, setPermissions] = React.useState<Record<string, boolean>>({})

  const fetchRoles = async () => {
    const { data, error } = await supabase
      .from("roles")
      .select("*")
      .order("name", { ascending: true })
    if (error) throw error
    return data
  }

  const { data: roles, error, isLoading, mutate } = useSWR("admin-roles", fetchRoles)

  const handleOpenEdit = (role: any) => {
    setEditingId(role.id)
    setName(role.name)
    setDisplayName(role.display_name || "")
    setDescription(role.description || "")
    setPermissions(role.permissions || {})
    setIsOpen(true)
  }

  const handleOpenAdd = () => {
    setEditingId(null)
    setName("")
    setDisplayName("")
    setDescription("")
    setPermissions({})
    setIsOpen(true)
  }

  const togglePermission = (permId: string) => {
    setPermissions(prev => ({
      ...prev,
      [permId]: !prev[permId]
    }))
  }

  const handleSave = async () => {
    if (!name || !displayName) {
      toast.error("Name and Display Name are required")
      return
    }

    try {
      const payload = { 
        name: name.toLowerCase().replace(/\s+/g, '_'), 
        display_name: displayName,
        description,
        permissions 
      }

      if (editingId) {
        const { error } = await supabase
          .from("roles")
          .update(payload)
          .eq("id", editingId)
        if (error) throw error
        toast.success("Role updated successfully")
      } else {
        const { error } = await supabase
          .from("roles")
          .insert(payload)
        if (error) throw error
        toast.success("Role added successfully")
      }
      
      setIsOpen(false)
      mutate()
    } catch (err: any) {
      toast.error(err.message || "Failed to save role")
    }
  }

  const handleDelete = async (id: string) => {
    if (!window.confirm("Are you sure you want to delete this role? This might break permissions if users are assigned to it.")) return

    try {
      const { error } = await supabase
        .from("roles")
        .delete()
        .eq("id", id)
      
      if (error) throw error
      toast.success("Role deleted successfully")
      mutate()
    } catch (err: any) {
      toast.error("Failed to delete role. It may be in use.")
    }
  }

  if (error) return <div className="text-red-500 p-4">Failed to load roles</div>

  return (
    <div className="space-y-4">
      <div className="flex justify-end">
        <Dialog open={isOpen} onOpenChange={setIsOpen}>
          <DialogTrigger asChild>
            <Button onClick={handleOpenAdd}>
              <Plus className="mr-2 h-4 w-4" /> Add Role
            </Button>
          </DialogTrigger>
          <DialogContent className="sm:max-w-[550px]">
            <DialogHeader>
              <DialogTitle>{editingId ? "Edit Role" : "Add New Role"}</DialogTitle>
              <DialogDescription>
                Define the roles and their corresponding permissions.
              </DialogDescription>
            </DialogHeader>
            <div className="grid gap-4 py-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="display_name">Display Name</Label>
                  <Input 
                    id="display_name" 
                    placeholder="e.g., Technician" 
                    value={displayName} 
                    onChange={(e) => setDisplayName(e.target.value)} 
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="name">Role Code (unique)</Label>
                  <Input 
                    id="name" 
                    placeholder="e.g., technician" 
                    value={name} 
                    onChange={(e) => setName(e.target.value)} 
                  />
                </div>
              </div>
              <div className="space-y-2">
                <Label htmlFor="description">Description</Label>
                <Textarea 
                  id="description" 
                  placeholder="What can this role do?" 
                  value={description} 
                  onChange={(e) => setDescription(e.target.value)} 
                />
              </div>
              
              <div className="space-y-3">
                <Label className="text-base">Permissions</Label>
                <div className="rounded-md border p-4 bg-muted/30">
                  <div className="grid gap-4">
                    {AVAILABLE_PERMISSIONS.map((perm) => (
                      <div key={perm.id} className="flex items-center justify-between space-x-4">
                        <div className="flex flex-col space-y-1">
                          <Label htmlFor={perm.id} className="cursor-pointer">{perm.label}</Label>
                          <span className="text-xs text-muted-foreground">{perm.description}</span>
                        </div>
                        <Switch 
                          id={perm.id} 
                          checked={!!permissions[perm.id]} 
                          onCheckedChange={() => togglePermission(perm.id)}
                        />
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={() => setIsOpen(false)}>Cancel</Button>
              <Button onClick={handleSave}>Save Role</Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>

      <div className="rounded-md border bg-card">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Role Name</TableHead>
              <TableHead>Code</TableHead>
              <TableHead>Permissions</TableHead>
              <TableHead>Description</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              Array.from({ length: 3 }).map((_, i) => (
                <TableRow key={i}>
                  <TableCell><Skeleton className="h-5 w-[150px]" /></TableCell>
                  <TableCell><Skeleton className="h-5 w-[100px]" /></TableCell>
                  <TableCell><Skeleton className="h-5 w-[80px]" /></TableCell>
                  <TableCell><Skeleton className="h-5 w-[200px]" /></TableCell>
                  <TableCell className="text-right"><Skeleton className="h-8 w-16 ml-auto" /></TableCell>
                </TableRow>
              ))
            ) : roles?.length === 0 ? (
              <TableRow>
                <TableCell colSpan={5} className="text-center py-10 text-muted-foreground">
                  No roles defined
                </TableCell>
              </TableRow>
            ) : (
              roles?.map((role: any) => {
                const activePermsCount = Object.values(role.permissions || {}).filter(Boolean).length
                return (
                  <TableRow key={role.id}>
                    <TableCell className="font-medium">{role.display_name || role.name.replace("_", " ")}</TableCell>
                    <TableCell className="font-mono text-xs">{role.name}</TableCell>
                    <TableCell>
                      <div className="flex items-center gap-1.5">
                        <ShieldCheck className="h-3.5 w-3.5 text-brand-secondary" />
                        <span className="text-sm">{activePermsCount} active</span>
                      </div>
                    </TableCell>
                    <TableCell className="text-muted-foreground max-w-[250px] truncate">{role.description || "-"}</TableCell>
                    <TableCell className="text-right">
                      <Button variant="ghost" size="icon" onClick={() => handleOpenEdit(role)}>
                        <Edit2 className="h-4 w-4" />
                        <span className="sr-only">Edit</span>
                      </Button>
                      <Button variant="ghost" size="icon" className="text-destructive" onClick={() => handleDelete(role.id)}>
                        <Trash2 className="h-4 w-4" />
                        <span className="sr-only">Delete</span>
                      </Button>
                    </TableCell>
                  </TableRow>
                )
              })
            )}
          </TableBody>
        </Table>
      </div>
    </div>
  )
}
