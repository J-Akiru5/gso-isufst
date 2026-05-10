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

export function DepartmentsSettingsClient() {
  const supabase = createClient()
  const [isOpen, setIsOpen] = React.useState(false)
  const [editingId, setEditingId] = React.useState<string | null>(null)
  
  // Form state
  const [code, setCode] = React.useState("")
  const [name, setName] = React.useState("")
  const [description, setDescription] = React.useState("")

  const fetchDepartments = async () => {
    const { data, error } = await supabase
      .from("departments")
      .select("*")
      .order("name", { ascending: true })
    if (error) throw error
    return data
  }

  const { data: departments, error, isLoading, mutate } = useSWR("admin-departments", fetchDepartments)

  const handleOpenEdit = (dept: any) => {
    setEditingId(dept.id)
    setCode(dept.code)
    setName(dept.name)
    setDescription(dept.description || "")
    setIsOpen(true)
  }

  const handleOpenAdd = () => {
    setEditingId(null)
    setCode("")
    setName("")
    setDescription("")
    setIsOpen(true)
  }

  const handleSave = async () => {
    if (!name || !code) {
      toast.error("Code and Name are required")
      return
    }

    try {
      if (editingId) {
        const { error } = await supabase
          .from("departments")
          .update({ code, name, description })
          .eq("id", editingId)
        if (error) throw error
        toast.success("Department updated successfully")
      } else {
        const { error } = await supabase
          .from("departments")
          .insert({ code, name, description })
        if (error) throw error
        toast.success("Department added successfully")
      }
      
      setIsOpen(false)
      mutate()
    } catch (err: any) {
      toast.error(err.message || "Failed to save department")
    }
  }

  const handleDelete = async (id: string) => {
    if (!window.confirm("Are you sure you want to delete this department?")) return

    try {
      const { error } = await supabase
        .from("departments")
        .delete()
        .eq("id", id)
      
      if (error) throw error
      toast.success("Department deleted successfully")
      mutate()
    } catch (err: any) {
      toast.error("Failed to delete department. It may be in use.")
    }
  }

  if (error) return <div className="text-red-500">Failed to load departments</div>

  return (
    <div className="space-y-4">
      <div className="flex justify-end">
        <Dialog open={isOpen} onOpenChange={setIsOpen}>
          <DialogTrigger asChild>
            <Button onClick={handleOpenAdd}>
              <Plus className="mr-2 h-4 w-4" /> Add Department
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>{editingId ? "Edit Department" : "Add New Department"}</DialogTitle>
              <DialogDescription>
                Define the departments that users and assets can belong to.
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4 py-4">
              <div className="space-y-2">
                <Label htmlFor="code">Department Code</Label>
                <Input 
                  id="code" 
                  placeholder="e.g., CAS" 
                  value={code} 
                  onChange={(e) => setCode(e.target.value)} 
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="name">Department Name</Label>
                <Input 
                  id="name" 
                  placeholder="e.g., College of Arts and Sciences" 
                  value={name} 
                  onChange={(e) => setName(e.target.value)} 
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="description">Description</Label>
                <Textarea 
                  id="description" 
                  placeholder="Additional details..." 
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
              <TableHead>Code</TableHead>
              <TableHead>Name</TableHead>
              <TableHead>Description</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              Array.from({ length: 3 }).map((_, i) => (
                <TableRow key={i}>
                  <TableCell><Skeleton className="h-5 w-[80px]" /></TableCell>
                  <TableCell><Skeleton className="h-5 w-[200px]" /></TableCell>
                  <TableCell><Skeleton className="h-5 w-[250px]" /></TableCell>
                  <TableCell className="text-right"><Skeleton className="h-8 w-16 ml-auto" /></TableCell>
                </TableRow>
              ))
            ) : departments?.length === 0 ? (
              <TableRow>
                <TableCell colSpan={4} className="text-center py-10 text-muted-foreground">
                  No departments defined
                </TableCell>
              </TableRow>
            ) : (
              departments?.map((dept: any) => (
                <TableRow key={dept.id}>
                  <TableCell className="font-medium">{dept.code}</TableCell>
                  <TableCell>{dept.name}</TableCell>
                  <TableCell className="text-muted-foreground">{dept.description || "-"}</TableCell>
                  <TableCell className="text-right">
                    <Button variant="ghost" size="icon" onClick={() => handleOpenEdit(dept)}>
                      <Edit2 className="h-4 w-4" />
                      <span className="sr-only">Edit</span>
                    </Button>
                    <Button variant="ghost" size="icon" className="text-destructive" onClick={() => handleDelete(dept.id)}>
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
