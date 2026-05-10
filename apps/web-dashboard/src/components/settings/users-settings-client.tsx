"use client"

import * as React from "react"
import useSWR from "swr"
import { createClient } from "@/lib/supabase/client"
import { 
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow 
} from "@/components/ui/table"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { toast } from "sonner"
import { MoreHorizontal, UserCheck, UserX, Shield } from "lucide-react"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { Skeleton } from "@/components/ui/skeleton"
import { RoleManagementDialog } from "./role-management-dialog"

export function UsersSettingsClient() {
  const supabase = createClient()
  const [selectedUser, setSelectedUser] = React.useState<any>(null)
  const [isRoleDialogOpen, setIsRoleDialogOpen] = React.useState(false)

  const fetchUsers = async () => {
    const { data, error } = await supabase
      .from("profiles")
      .select(`
        *,
        departments ( name ),
        user_roles ( roles ( id, name, display_name ) )
      `)
      .order("created_at", { ascending: false })
      
    if (error) throw error
    return data
  }

  const { data: users, error, isLoading, mutate } = useSWR("admin-users", fetchUsers)

  const handleUpdateStatus = async (userId: string, updates: { is_approved?: boolean, is_active?: boolean }) => {
    try {
      const { error } = await supabase
        .from("profiles")
        .update(updates)
        .eq("id", userId)

      if (error) throw error
      
      toast.success("User updated successfully")
      mutate()
    } catch (err: any) {
      toast.error(err.message || "Failed to update user")
    }
  }

  const getStatusBadge = (user: any) => {
    if (!user.is_approved) {
      return <Badge variant="secondary">Pending Approval</Badge>
    }
    if (user.is_active) {
      return <Badge variant="default" className="bg-green-500 hover:bg-green-600">Active</Badge>
    }
    return <Badge variant="destructive">Inactive</Badge>
  }

  if (error) return <div className="text-red-500 p-4">Failed to load users</div>

  return (
    <div className="space-y-4">
      <div className="rounded-md border bg-card">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>User</TableHead>
              <TableHead>Department</TableHead>
              <TableHead>Roles</TableHead>
              <TableHead>Status</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              Array.from({ length: 5 }).map((_, i) => (
                <TableRow key={i}>
                  <TableCell><Skeleton className="h-10 w-[200px]" /></TableCell>
                  <TableCell><Skeleton className="h-5 w-[100px]" /></TableCell>
                  <TableCell><Skeleton className="h-5 w-[100px]" /></TableCell>
                  <TableCell><Skeleton className="h-5 w-[80px]" /></TableCell>
                  <TableCell className="text-right"><Skeleton className="h-8 w-8 ml-auto" /></TableCell>
                </TableRow>
              ))
            ) : users?.length === 0 ? (
              <TableRow>
                <TableCell colSpan={5} className="text-center py-10 text-muted-foreground">
                  No users found
                </TableCell>
              </TableRow>
            ) : (
              users?.map((user: any) => (
                <TableRow key={user.id}>
                  <TableCell>
                    <div className="flex items-center gap-3">
                      <Avatar className="h-9 w-9">
                        <AvatarImage src={user.avatar_url || ""} />
                        <AvatarFallback>
                          {user.full_name?.substring(0, 2).toUpperCase() || "??"}
                        </AvatarFallback>
                      </Avatar>
                      <div className="flex flex-col">
                        <span className="font-medium">{user.full_name}</span>
                        <span className="text-xs text-muted-foreground">{user.email}</span>
                      </div>
                    </div>
                  </TableCell>
                  <TableCell>{user.departments?.name || "N/A"}</TableCell>
                  <TableCell>
                    <div className="flex flex-wrap gap-1">
                      {user.user_roles?.map((ur: any, idx: number) => (
                        <Badge key={idx} variant="outline" className="capitalize text-[10px] h-5">
                          {ur.roles?.display_name || ur.roles?.name.replace("_", " ")}
                        </Badge>
                      ))}
                      {(!user.user_roles || user.user_roles.length === 0) && (
                        <span className="text-xs text-muted-foreground">None</span>
                      )}
                    </div>
                  </TableCell>
                  <TableCell>
                    {getStatusBadge(user)}
                  </TableCell>
                  <TableCell className="text-right">
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" className="h-8 w-8 p-0">
                          <span className="sr-only">Open menu</span>
                          <MoreHorizontal className="h-4 w-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuLabel>Actions</DropdownMenuLabel>
                        <DropdownMenuItem onClick={() => navigator.clipboard.writeText(user.id)}>
                          Copy ID
                        </DropdownMenuItem>
                        <DropdownMenuSeparator />
                        
                        {!user.is_approved && (
                          <>
                            <DropdownMenuItem onClick={() => handleUpdateStatus(user.id, { is_approved: true, is_active: true })}>
                              <UserCheck className="mr-2 h-4 w-4 text-green-500" /> Approve User
                            </DropdownMenuItem>
                            <DropdownMenuItem className="text-red-500 focus:text-red-500" onClick={() => handleUpdateStatus(user.id, { is_approved: false, is_active: false })}>
                              <UserX className="mr-2 h-4 w-4" /> Reject User
                            </DropdownMenuItem>
                          </>
                        )}
                        
                        {user.is_approved && user.is_active && (
                          <DropdownMenuItem onClick={() => handleUpdateStatus(user.id, { is_active: false })}>
                            <UserX className="mr-2 h-4 w-4 text-yellow-500" /> Deactivate
                          </DropdownMenuItem>
                        )}
                        
                        {user.is_approved && !user.is_active && (
                          <DropdownMenuItem onClick={() => handleUpdateStatus(user.id, { is_active: true })}>
                            <UserCheck className="mr-2 h-4 w-4 text-green-500" /> Reactivate
                          </DropdownMenuItem>
                        )}
                        
                        <DropdownMenuSeparator />
                        <DropdownMenuItem onClick={() => {
                          setSelectedUser(user)
                          setIsRoleDialogOpen(true)
                        }}>
                          <Shield className="mr-2 h-4 w-4" /> Manage Roles
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>

      <RoleManagementDialog 
        user={selectedUser}
        isOpen={isRoleDialogOpen}
        onClose={() => setIsRoleDialogOpen(false)}
        onUpdate={mutate}
      />
    </div>
  )
}

