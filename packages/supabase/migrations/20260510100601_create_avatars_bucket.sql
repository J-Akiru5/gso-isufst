-- Create the bucket
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) 
values ('avatars', 'avatars', true, 5242880, ARRAY['image/png', 'image/jpeg', 'image/gif', 'image/webp'])
on conflict (id) do nothing;

-- Policy: Allow public read access to avatars
do $$
begin
    if not exists (
        select 1 from pg_policies where policyname = 'Avatar images are publicly accessible' and tablename = 'objects'
    ) then
        create policy "Avatar images are publicly accessible"
        on storage.objects for select
        using ( bucket_id = 'avatars' );
    end if;
end $$;

-- Policy: Allow authenticated users to upload their own avatar
do $$
begin
    if not exists (
        select 1 from pg_policies where policyname = 'Users can upload their own avatar' and tablename = 'objects'
    ) then
        create policy "Users can upload their own avatar"
        on storage.objects for insert
        to authenticated
        with check ( bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1] );
    end if;
end $$;

-- Policy: Allow authenticated users to update their own avatar
do $$
begin
    if not exists (
        select 1 from pg_policies where policyname = 'Users can update their own avatar' and tablename = 'objects'
    ) then
        create policy "Users can update their own avatar"
        on storage.objects for update
        to authenticated
        using ( bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1] );
    end if;
end $$;

-- Policy: Allow authenticated users to delete their own avatar
do $$
begin
    if not exists (
        select 1 from pg_policies where policyname = 'Users can delete their own avatar' and tablename = 'objects'
    ) then
        create policy "Users can delete their own avatar"
        on storage.objects for delete
        to authenticated
        using ( bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1] );
    end if;
end $$;
