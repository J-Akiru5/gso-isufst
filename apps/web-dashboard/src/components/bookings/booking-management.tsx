"use client";

import React from 'react';
import { createBrowserClient } from '@supabase/ssr';
import { Button } from '@/components/ui/button';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { toast } from 'sonner';
import useSWR from 'swr';
import useSWRMutation from 'swr/mutation';

export default function BookingManagement() {
  const supabase = createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
  const { data: bookings, mutate } = useSWR('admin_bookings', async () => {
    const { data } = await supabase
      .from('bookings')
      .select('*, profiles(full_name), rooms(name), buildings(name)')
      .order('created_at', { ascending: false });
    return data;
  });

  const { trigger: updateStatus } = useSWRMutation('updateBookingStatus', async (_key: string, { arg }: { arg: { id: string, status: string } }) => {
    const userId = (await supabase.auth.getUser()).data.user?.id;
    const { error } = await supabase.from('bookings').update({
      status: arg.status,
      approved_by: userId,
      approval_date: new Date().toISOString(),
    }).eq('id', arg.id);
    
    if (error) throw error;
    return arg;
  });

  const handleStatusChange = async (id: string, status: string) => {
    try {
      await updateStatus({ id, status });
      toast.success(`Booking marked as ${status}`);
      mutate();
    } catch (error: any) {
      toast.error(error.message || 'Failed to update status');
    }
  };

  return (
    <div className="p-6 space-y-6">
      <h1 className="text-3xl font-bold">Manage Bookings</h1>
      <div className="bg-white rounded-xl shadow-sm border overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>User</TableHead>
              <TableHead>Room</TableHead>
              <TableHead>Start Time</TableHead>
              <TableHead>End Time</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Attachment</TableHead>
              <TableHead>Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {bookings?.map((b) => (
              <TableRow key={b.id}>
                <TableCell className="font-medium">{b.profiles?.full_name}</TableCell>
                <TableCell>{b.rooms?.name} ({b.buildings?.name})</TableCell>
                <TableCell>{new Date(b.start_time).toLocaleString()}</TableCell>
                <TableCell>{new Date(b.end_time).toLocaleString()}</TableCell>
                <TableCell>
                  <Badge variant={b.status === 'approved' ? 'default' : b.status === 'rejected' ? 'destructive' : 'outline'}>
                    {b.status}
                  </Badge>
                </TableCell>
                <TableCell>
                  {b.attachment_url ? (
                    <Button variant="link" onClick={() => window.open(b.attachment_url, '_blank')}>View Letter</Button>
                  ) : (
                    <span className="text-muted-foreground">No file</span>
                  )}
                </TableCell>
                <TableCell>
                  {b.status === 'pending' && (
                    <div className="flex gap-2">
                      <Button size="sm" variant="outline" onClick={() => handleStatusChange(b.id, 'rejected')}>Reject</Button>
                      <Button size="sm" onClick={() => handleStatusChange(b.id, 'approved')}>Approve</Button>
                    </div>
                  )}
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>
    </div>
  );
}
