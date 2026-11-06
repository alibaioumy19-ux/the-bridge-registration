-- The Bridge Events Platform: initial database schema
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'admin' check (role in ('super_admin','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  title jsonb not null,
  slug text not null unique,
  description jsonb not null default '{}'::jsonb,
  venue text,
  starts_at timestamptz,
  ends_at timestamptz,
  is_published boolean not null default false,
  is_registration_open boolean not null default true,
  approval_mode text not null default 'automatic' check (approval_mode in ('automatic','manual')),
  form_fields jsonb not null default '[]'::jsonb,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.registrations (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  registration_code text not null unique,
  full_name text not null,
  email text not null,
  phone text not null,
  university text not null,
  faculty text,
  academic_year text,
  answers jsonb not null default '{}'::jsonb,
  status text not null default 'confirmed' check (status in ('pending','confirmed','rejected','cancelled')),
  created_at timestamptz not null default now(),
  unique(event_id,email)
);

create index if not exists registrations_event_created_idx on public.registrations(event_id,created_at desc);
create index if not exists registrations_email_idx on public.registrations(email);
create index if not exists events_slug_idx on public.events(slug);

-- The database decides the initial status so public clients cannot bypass manual review.
create or replace function public.set_registration_status()
returns trigger language plpgsql security definer set search_path=public
as $$
declare mode text;
begin
  select approval_mode into mode from public.events where id = new.event_id and is_published = true and is_registration_open = true;
  if mode is null then
    raise exception 'Registration is closed for this event.';
  end if;
  new.status := case when mode = 'manual' then 'pending' else 'confirmed' end;
  return new;
end;
$$;

drop trigger if exists registrations_set_status on public.registrations;
create trigger registrations_set_status
before insert on public.registrations
for each row execute function public.set_registration_status();

alter table public.profiles enable row level security;
alter table public.events enable row level security;
alter table public.registrations enable row level security;

create or replace function public.is_bridge_admin()
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.profiles p where p.id=auth.uid() and p.role in ('super_admin','admin')); $$;

create policy "Public can view published events" on public.events for select using (is_published=true or public.is_bridge_admin());
create policy "Admins manage events" on public.events for all using (public.is_bridge_admin()) with check (public.is_bridge_admin());
create policy "Public can submit registration to open events" on public.registrations for insert with check (
  exists(select 1 from public.events e where e.id=event_id and e.is_published=true and e.is_registration_open=true)
);
create policy "Admins view registrations" on public.registrations for select using (public.is_bridge_admin());
create policy "Admins update registrations" on public.registrations for update using (public.is_bridge_admin()) with check (public.is_bridge_admin());
create policy "Admins manage profiles" on public.profiles for all using (public.is_bridge_admin()) with check (public.is_bridge_admin());

-- After creating the first Auth user in Supabase, promote it to Super Admin:
-- insert into public.profiles (id, role)
-- select id, 'super_admin' from auth.users where email = 'YOUR_ADMIN_EMAIL';
-- Create a first published event:
-- insert into public.events (title,slug,description,venue,is_published,approval_mode)
-- values ('{"en":"The Bridge | From Campus to Career","ar":"من الحرم الجامعي إلى الحياة المهنية"}',
-- 'from-campus-to-career',
-- '{"en":"A career event by The Bridge.","ar":"فعالية مهنية من The Bridge."}',
-- 'Borg El Arab University', true, 'automatic');
