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
import { Plus, Edit2, Trash2 } from "lucide-react"
import { toast } from "sonner"

export function RolesSettingsClient() {
  const supabase = createClient()
  const [isOpen, setIsOpen] = React.useState(false)
  const [editingId, setEditingId] = React.useState<string | null>(null)
  
  // Form state
  const [name, setName] = React.useState("")
  const [description, setDescription] = React.useState("")

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
    setDescription(role.description || "")
    setIsOpen(true)
  }

  const handleOpenAdd = () => {
    setEditingId(null)
    setName("")
    setDescription("")
    setIsOpen(true)
  }

  const handleSave = async () => {
    if (!name) {
      toast.error("Name is required")
      return
    }

    try {
      if (editingId) {
        const { error } = await supabase
          .from("roles")
          .update({ name, description })
          .eq("id", editingId)
        if (error) throw error
        toast.success("Role updated successfully")
      } else {
        const { error } = await supabase
          .from("roles")
          .insert({ name, description })
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

  if (error) return <div className="text-red-500">Failed to load roles</div>

  return (
    <div className="space-y-4">
      <div className="flex justify-end">
        <Dialog open={isOpen} onOpenChange={setIsOpen}>
          <DialogTrigger asChild>
            <Button onClick={handleOpenAdd}>
              <Plus className="mr-2 h-4 w-4" /> Add Role
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>{editingId ? "Edit Role" : "Add New Role"}</DialogTitle>
              <DialogDescription>
                Define the roles used in the system for permission management.
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4 py-4">
              <div className="space-y-2">
                <Label htmlFor="name">Role Name (lowercase, no spaces)</Label>
                <Input 
                  id="name" 
                  placeholder="e.g., technician" 
                  value={name} 
                  onChange={(e) => setName(e.target.value)} 
                />
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
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={() => setIsOpen(false)}>Cancel</Button>
              <Button onClick={handleSave}>Save</Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>

      <div className="rounded-md border bg-card">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Role Name</TableHead>
              <TableHead>Description</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              Array.from({ length: 3 }).map((_, i) => (
                <TableRow key={i}>
                  <TableCell><Skeleton className="h-5 w-[150px]" /></TableCell>
                  <TableCell><Skeleton className="h-5 w-[250px]" /></TableCell>
                  <TableCell className="text-right"><Skeleton className="h-8 w-16 ml-auto" /></TableCell>
                </TableRow>
              ))
            ) : roles?.length === 0 ? (
              <TableRow>
                <TableCell colSpan={3} className="text-center py-10 text-muted-foreground">
                  No roles defined
                </TableCell>
              </TableRow>
            ) : (
              roles?.map((role: any) => (
                <TableRow key={role.id}>
                  <TableCell className="font-medium capitalize">{role.name.replace("_", " ")}</TableCell>
                  <TableCell className="text-muted-foreground">{role.description || "-"}</TableCell>
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
              ))
            )}
          </TableBody>
        </Table>
      </div>
    </div>
  )
}
