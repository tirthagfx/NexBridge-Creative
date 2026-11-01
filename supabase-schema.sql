-- NexBridge Creative CMS / Supabase schema
-- Run this entire file in Supabase Dashboard > SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create or replace function public.is_nexbridge_admin()
returns boolean language sql stable security definer set search_path = public
as $$ select exists(select 1 from public.admin_users where user_id = auth.uid()); $$;
revoke all on function public.is_nexbridge_admin() from public;
grant execute on function public.is_nexbridge_admin() to authenticated;

create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(), title text not null, category text not null default '',
  description text default '', image_url text default '', project_url text default '',
  sort_order int not null default 0, is_visible boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.services (
  id uuid primary key default gen_random_uuid(), title text not null, icon text default '✳',
  description text default '', subcategories text[] not null default '{}',
  sort_order int not null default 0, is_visible boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.team_members (
  id uuid primary key default gen_random_uuid(), name text not null, designation text not null,
  bio text default '', image_url text default '', sort_order int not null default 0,
  is_visible boolean not null default true, created_at timestamptz not null default now()
);
create table if not exists public.jobs (
  id uuid primary key default gen_random_uuid(), title text not null, department text default '',
  location text default 'Dhaka / Remote', employment_type text default 'Full-time',
  description text default '', requirements text[] not null default '{}', is_active boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.applications (
  id uuid primary key default gen_random_uuid(), full_name text not null, email text not null,
  phone text not null, position text not null, portfolio_url text default '', resume_url text default '',
  experience text default '', message text default '', status text not null default 'Pending'
    check (status in ('Pending','Shortlisted','Interview','Rejected','Hired')),
  created_at timestamptz not null default now()
);
create table if not exists public.inquiries (
  id uuid primary key default gen_random_uuid(), name text not null, email text not null,
  service text default '', budget text default '', message text not null,
  created_at timestamptz not null default now()
);
create table if not exists public.site_settings (
  id uuid primary key default gen_random_uuid(), setting_key text unique not null,
  setting_value text not null default '', updated_at timestamptz not null default now()
);

alter table public.admin_users enable row level security;
alter table public.projects enable row level security;
alter table public.services enable row level security;
alter table public.team_members enable row level security;
alter table public.jobs enable row level security;
alter table public.applications enable row level security;
alter table public.inquiries enable row level security;
alter table public.site_settings enable row level security;

-- Only the signed-in, explicitly allow-listed admin can read the admin allow-list.
drop policy if exists "admin can read own admin record" on public.admin_users;
create policy "admin can read own admin record" on public.admin_users for select to authenticated using (user_id = auth.uid());
-- Public visitors can read only published content; admin can manage all records.
drop policy if exists "public reads visible projects" on public.projects;
create policy "public reads visible projects" on public.projects for select to anon, authenticated using (is_visible or public.is_nexbridge_admin());
drop policy if exists "admin manages projects" on public.projects;
create policy "admin manages projects" on public.projects for all to authenticated using (public.is_nexbridge_admin()) with check (public.is_nexbridge_admin());
drop policy if exists "public reads visible services" on public.services;
create policy "public reads visible services" on public.services for select to anon, authenticated using (is_visible or public.is_nexbridge_admin());
drop policy if exists "admin manages services" on public.services;
create policy "admin manages services" on public.services for all to authenticated using (public.is_nexbridge_admin()) with check (public.is_nexbridge_admin());
drop policy if exists "public reads visible team" on public.team_members;
create policy "public reads visible team" on public.team_members for select to anon, authenticated using (is_visible or public.is_nexbridge_admin());
drop policy if exists "admin manages team" on public.team_members;
create policy "admin manages team" on public.team_members for all to authenticated using (public.is_nexbridge_admin()) with check (public.is_nexbridge_admin());
drop policy if exists "public reads active jobs" on public.jobs;
create policy "public reads active jobs" on public.jobs for select to anon, authenticated using (is_active or public.is_nexbridge_admin());
drop policy if exists "admin manages jobs" on public.jobs;
create policy "admin manages jobs" on public.jobs for all to authenticated using (public.is_nexbridge_admin()) with check (public.is_nexbridge_admin());
-- Anyone may submit a form; only admin can view/update/delete records.
drop policy if exists "public can submit applications" on public.applications;
create policy "public can submit applications" on public.applications for insert to anon, authenticated with check (true);
drop policy if exists "admin manages applications" on public.applications;
create policy "admin manages applications" on public.applications for all to authenticated using (public.is_nexbridge_admin()) with check (public.is_nexbridge_admin());
drop policy if exists "public can submit inquiries" on public.inquiries;
create policy "public can submit inquiries" on public.inquiries for insert to anon, authenticated with check (true);
drop policy if exists "admin manages inquiries" on public.inquiries;
create policy "admin manages inquiries" on public.inquiries for all to authenticated using (public.is_nexbridge_admin()) with check (public.is_nexbridge_admin());
drop policy if exists "public reads site settings" on public.site_settings;
create policy "public reads site settings" on public.site_settings for select to anon, authenticated using (true);
drop policy if exists "admin manages site settings" on public.site_settings;
create policy "admin manages site settings" on public.site_settings for all to authenticated using (public.is_nexbridge_admin()) with check (public.is_nexbridge_admin());

-- Public image bucket. Uploading/managing files requires admin login.
insert into storage.buckets(id,name,public) values ('nexbridge-media','nexbridge-media',true) on conflict(id) do nothing;
drop policy if exists "public can view NexBridge media" on storage.objects;
create policy "public can view NexBridge media" on storage.objects for select to anon, authenticated using (bucket_id='nexbridge-media');
drop policy if exists "admin uploads NexBridge media" on storage.objects;
create policy "admin uploads NexBridge media" on storage.objects for insert to authenticated with check (bucket_id='nexbridge-media' and public.is_nexbridge_admin());
drop policy if exists "admin updates NexBridge media" on storage.objects;
create policy "admin updates NexBridge media" on storage.objects for update to authenticated using (bucket_id='nexbridge-media' and public.is_nexbridge_admin()) with check (bucket_id='nexbridge-media' and public.is_nexbridge_admin());
drop policy if exists "admin deletes NexBridge media" on storage.objects;
create policy "admin deletes NexBridge media" on storage.objects for delete to authenticated using (bucket_id='nexbridge-media' and public.is_nexbridge_admin());

-- Starter content (only inserts missing items; editable later from Admin Panel).
create unique index if not exists services_title_uidx on public.services(title);
create unique index if not exists jobs_title_uidx on public.jobs(title);
insert into public.services(title,icon,description,subcategories,sort_order) values
('Graphic Design','✳','Creative visuals that make brands memorable.','{"Social Media Design","Ad Creatives","Brand Identity","Marketing Materials"}',1),
('Digital Marketing','↗','Digital campaigns built to reach the right audience.','{"Social Media Management","Campaign Strategy","Content Marketing","Paid Advertising"}',2),
('Video Editing','▶','Engaging edits and motion-led visual storytelling.','{"Social Media Videos","Promotional Videos","Reels & Shorts","Motion Graphics"}',3),
('Web Design','⌘','Modern digital experiences for growing businesses.','{"Website Design","Landing Pages","UI Design","Website Development"}',4)
on conflict (title) do nothing;
insert into public.jobs(title,department,location,employment_type,description,requirements) values
('Intern Graphic Designer','Design','Dhaka / Remote','Internship','Learn practical design skills and support the team with creative visual content.','{"Basic Photoshop or Illustrator knowledge","Creative mindset","Willingness to learn"}'),
('Junior Graphic Designer','Design','Dhaka / Remote','Full-time','Create social media posts, advertising creatives, and brand visuals.','{"Portfolio required","Good Photoshop / Illustrator skills","Attention to detail"}'),
('Senior Graphic Designer','Design','Dhaka / Remote','Full-time','Lead visual execution, develop creative concepts, and deliver high-quality design solutions.','{"Strong portfolio","Professional design experience","Creative direction skills"}'),
('Digital Marketer','Marketing','Dhaka / Remote','Full-time','Support digital campaigns, social media strategy, and performance improvement.','{"Digital marketing knowledge","Content and campaign planning","Analytical mindset"}'),
('Video Editor','Video','Dhaka / Remote','Full-time','Edit engaging short-form videos, promotional content, and social media creatives.','{"Video editing portfolio","Premiere Pro or equivalent","Storytelling skills"}')
on conflict (title) do nothing;
