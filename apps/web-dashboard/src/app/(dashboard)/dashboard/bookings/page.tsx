"use client";

import React, { useState } from 'react';
import FullCalendar from '@fullcalendar/react';
import dayGridPlugin from '@fullcalendar/daygrid';
import timeGridPlugin from '@fullcalendar/timegrid';
import interactionPlugin from '@fullcalendar/interaction';
import { createClientComponentClient } from '@supabase/auth-helpers-nextjs';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import { toast } from 'sonner';
import { useSWR, useSWRMutation } from 'swr';
import { BookingManagement } from '@/components/bookings/booking-management';

export default function BookingsPage() {
  const supabase = createClientComponentClient();
  const [isBookingModalOpen, setIsBookingModalOpen] = useState(false);
  const [selectedRoom, setSelectedRoom] = useState<string>('');
  const [startTime, setStartTime] = useState('');
  const [endTime, setEndTime] = useState('');
  const [notes, setNotes] = useState('');
  const [attachment, setAttachment] = useState<File | null>(null);

  const { data: rooms } = useSWR('rooms', async () => {
    const { data } = await supabase.from('rooms').select('*, buildings(name)').eq('is_active', true);
    return data;
  });

  const { data: bookings, mutate } = useSWR('bookings', async () => {
    const { data } = await supabase
      .from('bookings')
      .select('*, rooms(name), buildings(name)')
      .order('start_time');
    return data;
  });

  const { trigger: createBooking } = useSWRMutation('createBooking', async (arg: any) => {
    const { data, error } = await supabase.from('bookings').insert(arg);
    if (error) throw error;
    return data;
  });

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setAttachment(e.target.files[0]);
    }
  };

  const submitBooking = async () => {
    if (!selectedRoom || !startTime || !endTime) {
      toast.error('Please fill in all required fields');
      return;
    }

    try {
      let attachmentUrl = null;
      if (attachment) {
        const { data: { user } } = await supabase.auth.getUser();
        const userId = user?.id;
        const fileName = `${Date.now()}_${attachment.name}`;
        const filePath = `${userId}/${fileName}`;
        
        const { data: uploadData, error: uploadError } = await supabase.storage
          .from('booking_attachments')
          .upload(filePath, attachment);

        if (uploadError) throw uploadError;
        attachmentUrl = supabase.storage.from('booking_attachments').getPublicUrl(filePath).data.publicUrl;
      }

      await createBooking({
        user_id: (await supabase.auth.getUser()).data.user?.id,
        room_id: selectedRoom,
        start_time: startTime,
        end_time: endTime,
        attachment_url: attachmentUrl,
        notes: notes,
        status: 'pending',
      });

      toast.success('Booking request submitted!');
      setIsBookingModalOpen(false);
      mutate();
    } catch (error: any) {
      toast.error(error.message || 'Failed to submit booking');
    }
  };

  const events = bookings?.map(b => ({
    id: b.id,
    title: `${b.rooms?.name} (${b.status})`,
    start: b.start_time,
    end: b.end_time,
    backgroundColor: b.status === 'approved' ? '#16a34a' : b.status === 'rejected' ? '#dc2626' : '#f59e0b',
  })) || [];

  return (
    <div className="p-6 space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold">Building Bookings</h1>
        <Dialog open={isBookingModalOpen} onOpenChange={setIsBookingModalOpen}>
          <DialogTrigger asChild>
            <Button onClick={() => setIsBookingModalOpen(true)}>Request Booking</Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Request Room Booking</DialogTitle>
            </DialogHeader>
            <div className="grid gap-4 py-4">
              <div className="grid gap-2">
                <Label htmlFor="room">Room</Label>
                <Select onValueChange={setSelectedRoom}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select a room" />
                  </SelectTrigger>
                  <SelectContent>
                    {rooms?.map((room: any) => (
                      <SelectItem key={room.id} value={room.id}>
                        {room.buildings?.name} - {room.name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="grid gap-2">
                  <Label htmlFor="start">Start Time</Label>
                  <Input id="start" type="datetime-local" onChange={(e) => setStartTime(e.target.value)} />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="end">End Time</Label>
                  <Input id="end" type="datetime-local" onChange={(e) => setEndTime(e.target.value)} />
                </div>
              </div>
              <div className="grid gap-2">
                <Label htmlFor="file">Approval Letter (PDF/Image)</Label>
                <Input id="file" type="file" accept=".pdf,.jpg,.jpeg,.png" onChange={handleFileChange} />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="notes">Notes</Label>
                <Textarea id="notes" onChange={(e) => setNotes(e.target.value)} />
              </div>
              <Button onClick={submitBooking}>Submit Request</Button>
            </div>
          </DialogContent>
        </Dialog>
      </div>

      <div className="bg-white p-4 rounded-xl shadow-sm border">
        <FullCalendar
          plugins={[dayGridPlugin, timeGridPlugin, interactionPlugin]}
          initialView="dayGridMonth"
          headerToolbar={{
            left: 'prev,next today',
            center: 'title',
            right: 'dayGridMonth,timeGridWeek,timeGridDay',
          }}
          events={events}
          height="auto"
        />
      </div>

      <div className="mt-12">
        <h2 className="text-2xl font-bold mb-4">Booking Management</h2>
        <BookingManagement />
      </div>
    </div>
  );
}
