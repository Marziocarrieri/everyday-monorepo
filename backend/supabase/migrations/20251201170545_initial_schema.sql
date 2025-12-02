-- ============================================
--  EXTENSION (per gen_random_uuid)
-- ============================================

create extension if not exists "pgcrypto";

-- ============================================
--  ENUM TYPES
-- ============================================

create type public.household_role as enum ('HOST', 'COHOST', 'PERSONNEL');

create type public.storage_area as enum ('FRIDGE', 'PANTRY', 'FREEZER');

create type public.shopping_item_status as enum ('PENDING', 'BOUGHT', 'CANCELLED');

create type public.task_status as enum ('PENDING', 'IN_PROGRESS', 'DONE', 'CANCELLED');

create type public.task_category as enum ('PERSONAL', 'FAMILY', 'PERSONNEL', 'PET', 'OTHER');

create type public.task_source as enum ('MANUAL', 'GOOGLE_CALENDAR', 'AI_SUGGESTED');

create type public.notification_type as enum (
  'TASK_REMINDER',
  'PANTRY_MISSING_ITEM',
  'DIET_SUGGESTION',
  'SYSTEM'
);

create type public.calendar_provider as enum ('GOOGLE');

-- ============================================
--  PROFILI / UTENTI (collegati a auth.users)
-- ============================================

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null,
  default_locale text,
  timezone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================
--  CASA / FAMIGLIA
-- ============================================

create table public.households (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text,
  timezone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.household_members (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  role public.household_role not null,
  display_name text,            -- "Mamma", "Enrico", ecc.
  personnel_type text,          -- "housekeeper", "gardener", ecc. (solo per PERSONNEL)
  status text,                  -- "AT_HOME", "NOT_AT_HOME", ecc. opzionale
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (household_id, profile_id)
);

create table public.pets (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  name text not null,
  species text not null,        -- dog, cat, ecc.
  breed text,
  birthdate date,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================
--  CONFIGURAZIONE CASA
-- ============================================

create table public.home_configs (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  nickname text,                 -- "Villa al mare"
  floors integer,                -- numero piani
  square_meters integer,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (household_id)
);

create table public.rooms (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  name text not null,            -- "Kitchen", "Bathroom 1"
  type text,                     -- "kitchen", "bedroom", "bathroom"...
  floor integer,                 -- piano (0 = ground)
  area_m2 numeric(10,2),
  created_at timestamptz not null default now()
);

-- ============================================
--  TASK / ROUTINE / SUBTASK
-- ============================================

create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  title text not null,
  description text,
  category public.task_category not null default 'PERSONAL',
  start_at timestamptz,
  due_at timestamptz,
  duration_minutes integer,
  status public.task_status not null default 'PENDING',
  source public.task_source not null default 'MANUAL',
  created_by_member_id uuid not null references public.household_members (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.subtasks (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks (id) on delete cascade,
  label text not null,           -- "Cleanser", "Serum", ...
  is_done boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

-- task assegnate a uno o più membri (Home / Family / Personnel)
create table public.task_assignees (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks (id) on delete cascade,
  member_id uuid not null references public.household_members (id) on delete cascade,
  unique (task_id, member_id)
);

-- ============================================
--  DISPENSA / FRIGO / FREEZER
-- ============================================

create table public.pantry_items (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  name text not null,            -- "chicken breast", "rice", ...
  storage_area public.storage_area not null,
  quantity numeric(10,2),
  unit text,                     -- "kg", "pcs"...
  expires_at date,
  grid_row integer,              -- posizione nella griglia (opzionale)
  grid_col integer,
  is_deleted boolean not null default false,
  last_updated_by_member_id uuid references public.household_members (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================
--  LISTA DELLA SPESA
-- ============================================

create table public.shopping_lists (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  name text not null,
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.shopping_list_items (
  id uuid primary key default gen_random_uuid(),
  shopping_list_id uuid not null references public.shopping_lists (id) on delete cascade,
  pantry_item_id uuid references public.pantry_items (id),
  name text not null,
  quantity numeric(10,2),
  unit text,
  status public.shopping_item_status not null default 'PENDING',
  created_by_member_id uuid references public.household_members (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================
--  DIETA (PDF CARICATI)
-- ============================================

create table public.diet_documents (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.household_members (id) on delete cascade,
  file_path text not null,       -- path nello storage Supabase
  original_filename text,
  uploaded_at timestamptz not null default now()
);

-- ============================================
--  NOTIFICHE
-- ============================================

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  member_id uuid references public.household_members (id), -- destinatario
  type public.notification_type not null,
  title text not null,
  body text not null,
  scheduled_for timestamptz,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

-- ============================================
--  GOOGLE CALENDAR (SOLO IMPORT)
-- ============================================

-- account esterno collegato a un membro (es. Google)
create table public.external_calendar_accounts (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.household_members (id) on delete cascade,
  provider public.calendar_provider not null,
  email text not null,
  access_token text not null,        -- da cifrare lato backend / vault
  refresh_token text not null,
  token_expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- mappa un evento Google importato a una task creata nell'app
create table public.external_event_mappings (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks (id) on delete cascade,
  external_account_id uuid not null references public.external_calendar_accounts (id) on delete cascade,
  external_event_id text not null,      -- id evento su Google
  external_calendar_id text not null,   -- es. 'primary'
  last_synced_at timestamptz not null default now(),
  unique (task_id, external_account_id)
);
