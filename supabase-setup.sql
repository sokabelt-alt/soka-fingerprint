-- Soka Fingerprint: videos and platforms only.
-- Owner UID supplied by the site owner:
-- 01a5cc77-0776-475e-a5ce-fc995ae3c8b5
-- Do not use these public-read policies for private shop data such as orders or customer details.

create table if not exists public.videos (
  id uuid primary key default gen_random_uuid(),
  language text not null check (language in ('ckb', 'ar', 'en')),
  slot smallint not null check (slot between 1 and 3),
  title text not null,
  description text not null default '',
  video_url text not null,
  thumbnail_url text not null default '',
  published boolean not null default true,
  created_at timestamptz not null default now(),
  unique (language, slot)
);

create table if not exists public.platforms (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  url text not null,
  image_url text not null default '',
  published boolean not null default true,
  sort_order smallint not null default 0
);

alter table public.videos enable row level security;
alter table public.platforms enable row level security;

revoke insert, update, delete on public.videos, public.platforms from anon;
grant select on public.videos, public.platforms to anon, authenticated;
grant insert, update, delete on public.videos, public.platforms to authenticated;

-- Visitors can read published content.
drop policy if exists "Anyone can read published videos" on public.videos;
create policy "Anyone can read published videos"
on public.videos for select to anon, authenticated
using (published = true);

drop policy if exists "Owner can manage videos" on public.videos;
create policy "Owner can manage videos"
on public.videos for all to authenticated
using ((select auth.uid()) = '01a5cc77-0776-475e-a5ce-fc995ae3c8b5'::uuid)
with check ((select auth.uid()) = '01a5cc77-0776-475e-a5ce-fc995ae3c8b5'::uuid);

drop policy if exists "Anyone can read published platforms" on public.platforms;
create policy "Anyone can read published platforms"
on public.platforms for select to anon, authenticated
using (published = true);

drop policy if exists "Owner can manage platforms" on public.platforms;
create policy "Owner can manage platforms"
on public.platforms for all to authenticated
using ((select auth.uid()) = '01a5cc77-0776-475e-a5ce-fc995ae3c8b5'::uuid)
with check ((select auth.uid()) = '01a5cc77-0776-475e-a5ce-fc995ae3c8b5'::uuid);

-- Storage bucket for uploading video files from the owner's phone gallery.
insert into storage.buckets (id, name, public)
values ('soka-videos', 'soka-videos', true)
on conflict (id) do update set public = true;

drop policy if exists "Anyone can watch Soka videos" on storage.objects;
create policy "Anyone can watch Soka videos"
on storage.objects for select to anon, authenticated
using (bucket_id = 'soka-videos');

drop policy if exists "Owner can upload Soka videos" on storage.objects;
create policy "Owner can upload Soka videos"
on storage.objects for insert to authenticated
with check (bucket_id = 'soka-videos' and (select auth.uid()) = '01a5cc77-0776-475e-a5ce-fc995ae3c8b5'::uuid);
