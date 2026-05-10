"use client"

import * as React from "react"
import useSWR from "swr"
import { createClient } from "@/lib/supabase/client"
import { 
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow 
} from "@/components/ui/table"
import { Skeleton } from "@/components/ui/skeleton"
import { Button } from "@/components/ui/button"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
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
import { Plus, Edit2, Trash2 } from "lucide-react"
import { toast } from "sonner"
import { Badge } from "@/components/ui/badge"

export function CategoriesSettingsClient() {
  const supabase = createClient()
  
  const [activeTab, setActiveTab] = React.useState("maintenance")

  const [isOpen, setIsOpen] = React.useState(false)
  const [editingId, setEditingId] = React.useState<string | null>(null)
  
  // Form State
  const [name, setName] = React.useState("")
  const [description, setDescription] = React.useState("")
  const [isActive, setIsActive] = React.useState(true)

  const tableName = activeTab === "maintenance" ? "maintenance_categories" : "inventory_categories"

  const fetchCategories = async (tab: string) => {
    const table = tab === "maintenance" ? "maintenance_categories" : "inventory_categories"
    const { data, error } = await supabase.from(table).select("*").order("name")
    if (error) throw error
    return data
  }

  const { data: maintCats, isLoading: maintLoading, mutate: mutateMaint } = useSWR("admin-maint-cats", () => fetchCategories("maintenance"))
  const { data: invCats, isLoading: invLoading, mutate: mutateInv } = useSWR("admin-inv-cats", () => fetchCategories("inventory"))

  const handleOpen = (cat?: any) => {
    if (cat) {
      setEditingId(cat.id)
      setName(cat.name)
      setDescription(cat.description || "")
      setIsActive(cat.is_active !== false) // defaults true
    } else {
      setEditingId(null)
      setName("")
      setDescription("")
      setIsActive(true)
    }
    setIsOpen(true)
  }

  const handleSave = async () => {
    if (!name) return toast.error("Name is required")
    try {
      const payload = { name, description, is_active: isActive }
      if (editingId) {
        await supabase.from(tableName).update(payload).eq("id", editingId)
        toast.success("Category updated")
      } else {
        await supabase.from(tableName).insert(payload)
        toast.success("Category added")
      }
      setIsOpen(false)
      if (activeTab === "maintenance") mutateMaint()
      else mutateInv()
    } catch (err: any) {
      toast.error(err.message)
    }
  }

  const handleDelete = async (id: string) => {
    if (!window.confirm("Delete this category? Items or requests linked to this might break.")) return
    try {
      await supabase.from(tableName).delete().eq("id", id)
      toast.success("Category deleted")
      if (activeTab === "maintenance") mutateMaint()
      else mutateInv()
    } catch (err: any) {
      toast.error("Failed to delete. It might be in use.")
    }
  }

  const renderTable = (items: any[], isLoading: boolean) => (
    <div className="rounded-md border bg-card">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Name</TableHead>
            <TableHead>Description</TableHead>
            <TableHead>Status</TableHead>
            <TableHead className="text-right">Actions</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {isLoading ? <TableRow><TableCell colSpan={4}>Loading...</TableCell></TableRow> :
            items?.map((c) => (
              <TableRow key={c.id}>
                <TableCell className="font-medium">{c.name}</TableCell>
                <TableCell className="text-muted-foreground">{c.description || "-"}</TableCell>
                <TableCell>
                  <Badge variant={c.is_active ? "default" : "secondary"}>
                    {c.is_active ? "Active" : "Inactive"}
                  </Badge>
                </TableCell>
                <TableCell className="text-right">
                  <Button variant="ghost" size="icon" onClick={() => handleOpen(c)}><Edit2 className="h-4 w-4" /></Button>
                  <Button variant="ghost" size="icon" className="text-destructive" onClick={() => handleDelete(c.id)}><Trash2 className="h-4 w-4" /></Button>
                </TableCell>
              </TableRow>
            ))
          }
        </TableBody>
      </Table>
    </div>
  )

  return (
    <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-4">
      <div className="flex items-center justify-between">
        <TabsList>
          <TabsTrigger value="maintenance">Maintenance</TabsTrigger>
          <TabsTrigger value="inventory">Inventory</TabsTrigger>
        </TabsList>
        <Dialog open={isOpen} onOpenChange={setIsOpen}>
          <DialogTrigger asChild>
            <Button onClick={() => handleOpen()}><Plus className="mr-2 h-4 w-4" /> Add Category</Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>{editingId ? "Edit" : "Add"} {activeTab === "maintenance" ? "Maintenance" : "Inventory"} Category</DialogTitle>
              <DialogDescription>Define categories for classifying items or requests.</DialogDescription>
            </DialogHeader>
            <div className="space-y-4 py-4">
              <div className="space-y-2">
                <Label>Name</Label>
                <Input value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Electrical" />
              </div>
              <div className="space-y-2">
                <Label>Description</Label>
                <Textarea value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Details..." />
              </div>
              <div className="flex items-center space-x-2 pt-2">
                <Switch checked={isActive} onCheckedChange={setIsActive} id="active" />
                <Label htmlFor="active">Is Active?</Label>
              </div>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={() => setIsOpen(false)}>Cancel</Button>
              <Button onClick={handleSave}>Save</Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>

      <TabsContent value="maintenance" className="space-y-4">
        {renderTable(maintCats || [], maintLoading)}
      </TabsContent>
      <TabsContent value="inventory" className="space-y-4">
        {renderTable(invCats || [], invLoading)}
      </TabsContent>
    </Tabs>
  )
}
