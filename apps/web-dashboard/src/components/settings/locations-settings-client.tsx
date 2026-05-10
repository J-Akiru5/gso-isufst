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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Plus, Edit2, Trash2 } from "lucide-react"
import { toast } from "sonner"

export function LocationsSettingsClient() {
  const supabase = createClient()
  
  // Building State
  const [bldgOpen, setBldgOpen] = React.useState(false)
  const [editingBldgId, setEditingBldgId] = React.useState<string | null>(null)
  const [bldgCode, setBldgCode] = React.useState("")
  const [bldgName, setBldgName] = React.useState("")
  
  // Room State
  const [roomOpen, setRoomOpen] = React.useState(false)
  const [editingRoomId, setEditingRoomId] = React.useState<string | null>(null)
  const [roomCode, setRoomCode] = React.useState("")
  const [roomName, setRoomName] = React.useState("")
  const [roomBldgId, setRoomBldgId] = React.useState("")
  const [roomFloor, setRoomFloor] = React.useState("")
  const [roomCapacity, setRoomCapacity] = React.useState("")
  const [roomType, setRoomType] = React.useState("")

  const fetchBuildings = async () => {
    const { data, error } = await supabase.from("buildings").select("*").order("name")
    if (error) throw error
    return data
  }

  const fetchRooms = async () => {
    const { data, error } = await supabase.from("rooms").select("*, buildings(name)").order("name")
    if (error) throw error
    return data
  }

  const { data: buildings, isLoading: bldgLoading, mutate: mutateBldg } = useSWR("admin-buildings", fetchBuildings)
  const { data: rooms, isLoading: roomLoading, mutate: mutateRoom } = useSWR("admin-rooms", fetchRooms)

  // Building Actions
  const openBldg = (bldg?: any) => {
    if (bldg) {
      setEditingBldgId(bldg.id)
      setBldgCode(bldg.code)
      setBldgName(bldg.name)
    } else {
      setEditingBldgId(null)
      setBldgCode("")
      setBldgName("")
    }
    setBldgOpen(true)
  }

  const saveBldg = async () => {
    if (!bldgName || !bldgCode) return toast.error("Code and Name required")
    try {
      if (editingBldgId) {
        await supabase.from("buildings").update({ code: bldgCode, name: bldgName }).eq("id", editingBldgId)
        toast.success("Building updated")
      } else {
        await supabase.from("buildings").insert({ code: bldgCode, name: bldgName })
        toast.success("Building added")
      }
      setBldgOpen(false)
      mutateBldg()
    } catch (err: any) {
      toast.error(err.message)
    }
  }

  const deleteBldg = async (id: string) => {
    if (!window.confirm("Delete this building? Rooms inside will prevent deletion.")) return
    try {
      await supabase.from("buildings").delete().eq("id", id)
      toast.success("Building deleted")
      mutateBldg()
    } catch (err: any) {
      toast.error("Failed. Ensure no rooms are attached.")
    }
  }

  // Room Actions
  const openRoom = (room?: any) => {
    if (room) {
      setEditingRoomId(room.id)
      setRoomCode(room.code)
      setRoomName(room.name)
      setRoomBldgId(room.building_id)
      setRoomFloor(room.floor_level || "")
      setRoomCapacity(room.capacity?.toString() || "")
      setRoomType(room.type || "")
    } else {
      setEditingRoomId(null)
      setRoomCode("")
      setRoomName("")
      setRoomBldgId("")
      setRoomFloor("")
      setRoomCapacity("")
      setRoomType("")
    }
    setRoomOpen(true)
  }

  const saveRoom = async () => {
    if (!roomName || !roomCode || !roomBldgId) return toast.error("Code, Name, and Building required")
    try {
      const payload = {
        code: roomCode,
        name: roomName,
        building_id: roomBldgId,
        floor_level: roomFloor || null,
        capacity: roomCapacity ? parseInt(roomCapacity) : null,
        type: roomType || null
      }
      if (editingRoomId) {
        await supabase.from("rooms").update(payload).eq("id", editingRoomId)
        toast.success("Room updated")
      } else {
        await supabase.from("rooms").insert(payload)
        toast.success("Room added")
      }
      setRoomOpen(false)
      mutateRoom()
    } catch (err: any) {
      toast.error(err.message)
    }
  }

  const deleteRoom = async (id: string) => {
    if (!window.confirm("Delete this room?")) return
    try {
      await supabase.from("rooms").delete().eq("id", id)
      toast.success("Room deleted")
      mutateRoom()
    } catch (err: any) {
      toast.error("Failed to delete room.")
    }
  }

  return (
    <Tabs defaultValue="buildings" className="space-y-4">
      <TabsList>
        <TabsTrigger value="buildings">Buildings</TabsTrigger>
        <TabsTrigger value="rooms">Rooms</TabsTrigger>
      </TabsList>

      {/* Buildings Tab */}
      <TabsContent value="buildings" className="space-y-4">
        <div className="flex justify-end">
          <Dialog open={bldgOpen} onOpenChange={setBldgOpen}>
            <DialogTrigger asChild>
              <Button onClick={() => openBldg()}><Plus className="mr-2 h-4 w-4" /> Add Building</Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader><DialogTitle>{editingBldgId ? "Edit" : "Add"} Building</DialogTitle></DialogHeader>
              <div className="space-y-4 py-4">
                <div className="space-y-2">
                  <Label>Building Code</Label>
                  <Input value={bldgCode} onChange={(e) => setBldgCode(e.target.value)} placeholder="e.g. MAIN" />
                </div>
                <div className="space-y-2">
                  <Label>Building Name</Label>
                  <Input value={bldgName} onChange={(e) => setBldgName(e.target.value)} placeholder="e.g. Main Administration Building" />
                </div>
              </div>
              <DialogFooter>
                <Button variant="outline" onClick={() => setBldgOpen(false)}>Cancel</Button>
                <Button onClick={saveBldg}>Save</Button>
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
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {bldgLoading ? <TableRow><TableCell colSpan={3}>Loading...</TableCell></TableRow> :
                buildings?.map((b) => (
                  <TableRow key={b.id}>
                    <TableCell>{b.code}</TableCell>
                    <TableCell>{b.name}</TableCell>
                    <TableCell className="text-right">
                      <Button variant="ghost" size="icon" onClick={() => openBldg(b)}><Edit2 className="h-4 w-4" /></Button>
                      <Button variant="ghost" size="icon" className="text-destructive" onClick={() => deleteBldg(b.id)}><Trash2 className="h-4 w-4" /></Button>
                    </TableCell>
                  </TableRow>
                ))
              }
            </TableBody>
          </Table>
        </div>
      </TabsContent>

      {/* Rooms Tab */}
      <TabsContent value="rooms" className="space-y-4">
        <div className="flex justify-end">
          <Dialog open={roomOpen} onOpenChange={setRoomOpen}>
            <DialogTrigger asChild>
              <Button onClick={() => openRoom()}><Plus className="mr-2 h-4 w-4" /> Add Room</Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader><DialogTitle>{editingRoomId ? "Edit" : "Add"} Room</DialogTitle></DialogHeader>
              <div className="space-y-4 py-4 grid grid-cols-2 gap-4">
                <div className="space-y-2 col-span-2">
                  <Label>Building</Label>
                  <Select value={roomBldgId} onValueChange={setRoomBldgId}>
                    <SelectTrigger><SelectValue placeholder="Select building" /></SelectTrigger>
                    <SelectContent>
                      {buildings?.map(b => (
                        <SelectItem key={b.id} value={b.id}>{b.name}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label>Room Code</Label>
                  <Input value={roomCode} onChange={(e) => setRoomCode(e.target.value)} placeholder="e.g. 101" />
                </div>
                <div className="space-y-2">
                  <Label>Room Name</Label>
                  <Input value={roomName} onChange={(e) => setRoomName(e.target.value)} placeholder="e.g. Computer Lab A" />
                </div>
                <div className="space-y-2">
                  <Label>Floor Level</Label>
                  <Input value={roomFloor} onChange={(e) => setRoomFloor(e.target.value)} placeholder="e.g. 1st Floor" />
                </div>
                <div className="space-y-2">
                  <Label>Capacity</Label>
                  <Input type="number" value={roomCapacity} onChange={(e) => setRoomCapacity(e.target.value)} placeholder="e.g. 40" />
                </div>
              </div>
              <DialogFooter>
                <Button variant="outline" onClick={() => setRoomOpen(false)}>Cancel</Button>
                <Button onClick={saveRoom}>Save</Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </div>
        <div className="rounded-md border bg-card">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Building</TableHead>
                <TableHead>Code</TableHead>
                <TableHead>Name</TableHead>
                <TableHead>Floor</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {roomLoading ? <TableRow><TableCell colSpan={5}>Loading...</TableCell></TableRow> :
                rooms?.map((r) => (
                  <TableRow key={r.id}>
                    <TableCell>{r.buildings?.name}</TableCell>
                    <TableCell>{r.code}</TableCell>
                    <TableCell>{r.name}</TableCell>
                    <TableCell>{r.floor_level || "-"}</TableCell>
                    <TableCell className="text-right">
                      <Button variant="ghost" size="icon" onClick={() => openRoom(r)}><Edit2 className="h-4 w-4" /></Button>
                      <Button variant="ghost" size="icon" className="text-destructive" onClick={() => deleteRoom(r.id)}><Trash2 className="h-4 w-4" /></Button>
                    </TableCell>
                  </TableRow>
                ))
              }
            </TableBody>
          </Table>
        </div>
      </TabsContent>
    </Tabs>
  )
}
