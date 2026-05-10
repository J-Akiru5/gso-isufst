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

export function UsersSettingsClient() {
  const supabase = createClient()

  const fetchUsers = async () => {
    const { data, error } = await supabase
      .from("profiles")
      .select(`
        *,
        departments ( name ),
        user_roles ( roles ( name ) )
      `)
      .order("created_at", { ascending: false })
      
    if (error) throw error
    return data
  }

  const { data: users, error, isLoading, mutate } = useSWR("admin-users", fetchUsers)

  const handleUpdateStatus = async (userId: string, newStatus: string) => {
    try {
      const { error } = await supabase
        .from("profiles")
        .update({ status: newStatus })
        .eq("id", userId)

      if (error) throw error
      
      toast.success(`User status updated to ${newStatus}`)
      mutate()
    } catch (err: any) {
      toast.error(err.message || "Failed to update status")
    }
  }

  if (error) return <div className="text-red-500">Failed to load users</div>

  return (
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
                <TableCell><Skeleton className="h-5 w-[60px]" /></TableCell>
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
                      <Badge key={idx} variant="outline" className="capitalize">
                        {ur.roles?.name.replace("_", " ")}
                      </Badge>
                    ))}
                    {(!user.user_roles || user.user_roles.length === 0) && (
                      <span className="text-xs text-muted-foreground">None</span>
                    )}
                  </div>
                </TableCell>
                <TableCell>
                  <Badge 
                    variant={
                      user.status === "active" ? "default" :
                      user.status === "pending" ? "secondary" :
                      "destructive"
                    }
                  >
                    {user.status}
                  </Badge>
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
                      {user.status === 'pending' && (
                        <>
                          <DropdownMenuItem onClick={() => handleUpdateStatus(user.id, 'active')}>
                            <UserCheck className="mr-2 h-4 w-4 text-green-500" /> Approve User
                          </DropdownMenuItem>
                          <DropdownMenuItem onClick={() => handleUpdateStatus(user.id, 'rejected')}>
                            <UserX className="mr-2 h-4 w-4 text-red-500" /> Reject User
                          </DropdownMenuItem>
                        </>
                      )}
                      {user.status === 'active' && (
                        <DropdownMenuItem onClick={() => handleUpdateStatus(user.id, 'inactive')}>
                          <UserX className="mr-2 h-4 w-4 text-yellow-500" /> Deactivate
                        </DropdownMenuItem>
                      )}
                      {(user.status === 'inactive' || user.status === 'rejected') && (
                        <DropdownMenuItem onClick={() => handleUpdateStatus(user.id, 'active')}>
                          <UserCheck className="mr-2 h-4 w-4 text-green-500" /> Reactivate
                        </DropdownMenuItem>
                      )}
                      <DropdownMenuSeparator />
                      <DropdownMenuItem disabled>
                        <Shield className="mr-2 h-4 w-4" /> Manage Roles (Coming soon)
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
  )
}
