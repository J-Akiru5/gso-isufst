-- Create Enums
CREATE TYPE vehicle_status AS ENUM ('Available', 'On_Travel', 'Under_Maintenance', 'Out_of_Service');
CREATE TYPE travel_booking_status AS ENUM ('Pending', 'Approved', 'Rejected', 'Scheduled', 'Ongoing', 'Completed', 'Cancelled');

-- Create vehicles table
CREATE TABLE public.vehicles (
    id UUID DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    plate_number TEXT NOT NULL UNIQUE,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    vehicle_type TEXT NOT NULL,
    capacity INTEGER NOT NULL DEFAULT 4,
    status vehicle_status NOT NULL DEFAULT 'Available',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for vehicles
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;

-- Vehicles Policies
CREATE POLICY "Enable read access for all users" ON public.vehicles FOR SELECT USING (true);
CREATE POLICY "Enable insert for authenticated users only" ON public.vehicles FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users only" ON public.vehicles FOR UPDATE USING (auth.role() = 'authenticated');

-- Create travel_bookings table
CREATE TABLE public.travel_bookings (
    id UUID DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    booking_number TEXT NOT NULL UNIQUE,
    requester_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    vehicle_id UUID REFERENCES public.vehicles(id) ON DELETE SET NULL,
    destination TEXT NOT NULL,
    purpose TEXT NOT NULL,
    departure_time TIMESTAMP WITH TIME ZONE NOT NULL,
    return_time TIMESTAMP WITH TIME ZONE NOT NULL,
    passenger_count INTEGER NOT NULL DEFAULT 1,
    status travel_booking_status NOT NULL DEFAULT 'Pending',
    approved_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for travel_bookings
ALTER TABLE public.travel_bookings ENABLE ROW LEVEL SECURITY;

-- Travel Bookings Policies
CREATE POLICY "Users can view their own bookings" ON public.travel_bookings FOR SELECT USING (auth.uid() = requester_id OR auth.uid() = driver_id);
-- Assuming admins can view all, we'll add a generic one for now that we might refine later, or let the standard bypass handle it
CREATE POLICY "Enable read access for all users" ON public.travel_bookings FOR SELECT USING (true);
CREATE POLICY "Users can insert their own bookings" ON public.travel_bookings FOR INSERT WITH CHECK (auth.uid() = requester_id);
CREATE POLICY "Users can update their own bookings" ON public.travel_bookings FOR UPDATE USING (auth.uid() = requester_id OR auth.role() = 'authenticated');

-- Trigger to update updated_at
CREATE TRIGGER trg_vehicles_updated_at BEFORE UPDATE ON public.vehicles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_travel_bookings_updated_at BEFORE UPDATE ON public.travel_bookings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Trigger Function to update vehicle status based on booking status
CREATE OR REPLACE FUNCTION update_vehicle_status_on_travel()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'Ongoing' AND OLD.status != 'Ongoing' AND NEW.vehicle_id IS NOT NULL THEN
        UPDATE public.vehicles SET status = 'On_Travel' WHERE id = NEW.vehicle_id;
    ELSIF (NEW.status = 'Completed' OR NEW.status = 'Cancelled') AND (OLD.status = 'Ongoing' OR OLD.status = 'Scheduled') AND NEW.vehicle_id IS NOT NULL THEN
        UPDATE public.vehicles SET status = 'Available' WHERE id = NEW.vehicle_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER update_vehicle_status_trigger
AFTER UPDATE OF status ON public.travel_bookings
FOR EACH ROW
EXECUTE FUNCTION update_vehicle_status_on_travel();
