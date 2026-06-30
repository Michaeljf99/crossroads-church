-- Crossroads Church — Updates feed backend
-- Run this once in your Supabase project: Dashboard → SQL Editor → New query → paste → Run.
-- Then put your Project URL + anon key into index.html (SUPABASE_URL / SUPABASE_ANON_KEY).

-- 1) Posts table -----------------------------------------------------------
create table if not exists public.posts (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz not null default now(),
  title       text not null,
  author      text,
  category    text not null default 'update',   -- update | event | prayer
  content     text not null,
  event_date  date,        -- optional, for events
  event_time  text,        -- optional, e.g. "6:00 PM"
  location    text,        -- optional
  link_url    text,        -- optional RSVP / details link
  image_url   text         -- filled automatically when you upload an image
);

alter table public.posts enable row level security;

-- Anyone can read updates (public website). Posting is gated by the admin
-- password in the page. (For tighter security, swap the insert policy for
-- Supabase Auth later — see note at the bottom.)
drop policy if exists "public read posts"   on public.posts;
drop policy if exists "public insert posts" on public.posts;
create policy "public read posts"   on public.posts for select using (true);
create policy "public insert posts" on public.posts for insert with check (true);

-- 2) Image storage bucket --------------------------------------------------
insert into storage.buckets (id, name, public)
values ('post-images', 'post-images', true)
on conflict (id) do nothing;

drop policy if exists "public read images"   on storage.objects;
drop policy if exists "public upload images" on storage.objects;
create policy "public read images"   on storage.objects for select using (bucket_id = 'post-images');
create policy "public upload images" on storage.objects for insert with check (bucket_id = 'post-images');

-- Done. New uploads from the website land in the post-images bucket and the
-- public URL is saved on the post automatically.

-- NOTE ON SECURITY: the anon key and admin password both live in the page,
-- so a determined person could post via the API. That's normal for a small
-- church site. To lock it down properly, enable Supabase Auth and change the
-- insert policies to `with check (auth.role() = 'authenticated')`.
