-- ============================================
-- ENUM TYPES
-- ============================================

create type user_role as enum ('HOST', 'COHOST', 'PERSONNEL');
create type member_status as enum ('ACTIVE', 'INVITED', 'LEFT');
create type personnel_type as enum ('CLEANER', 'GARDENER', 'COOK', 'OTHER');

create type area_type as enum ('PANTRY', 'FRIDGE', 'FREEZER');
create type shopping_status as enum ('PENDING', 'BOUGHT', 'CANCELLED');

create type task_status as enum ('TODO', 'DONE', 'SKIPPED');
create type repeat_rule as enum ('NONE', 'DAILY', 'WEEKLY', 'MONTHLY');

create type notification_type as enum ('TASK', 'REMINDER', 'PANTRY_LOW', 'SYSTEM', 'DIET');

-- ============================================
-- USERS PROFILE
-- ============================================

create table if not exists users_profile (
    id uuid primary key references auth.users(id) on delete cascade,
    name text,
    email text unique,
    birthdate date,
    avatar_url text,
    created_at timestamptz default now()
);

-- ============================================
-- HOUSEHOLD
-- ============================================

create table if not exists household (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    address text,
    timezone text default 'Europe/Rome',
    created_at timestamptz default now()
);

-- ============================================
-- HOUSEHOLD MEMBER
-- ============================================

create table if not exists household_member (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references users_profile(id) on delete set null,
    household_id uuid references household(id) on delete cascade,
    role user_role not null,
    member_status member_status default 'ACTIVE',
    is_personnel boolean default false,
    personnel_type personnel_type,
    created_at timestamptz default now()
);

-- ============================================
-- PETS
-- ============================================

create table if not exists pets (
    id uuid primary key default gen_random_uuid(),
    household_id uuid references household(id) on delete cascade,
    name text not null,
    species text,
    breed text,
    birthdate date,
    created_at timestamptz default now()
);

-- ============================================
-- TASKS
-- ============================================

create table if not exists tasks (
    id uuid primary key default gen_random_uuid(),
    household_id uuid references household(id) on delete cascade,
    title text not null,
    description text,
    task_date date not null,
    time_from time,
    time_to time,
    repeat_rule repeat_rule default 'NONE',
    visibility text default 'ALL', -- ALL, HOST_ONLY, PERSONNEL_ONLY (gestibile da app)
    created_by uuid references household_member(id),
    created_at timestamptz default now()
);

-- ============================================
-- SUBTASK
-- ============================================

create table if not exists subtask (
    id uuid primary key default gen_random_uuid(),
    task_id uuid references tasks(id) on delete cascade,
    title text not null,
    is_done boolean default false
);

-- ============================================
-- TASK ASSIGNMENTS
-- ============================================

create table if not exists task_assignment (
    id uuid primary key default gen_random_uuid(),
    task_id uuid references tasks(id) on delete cascade,
    member_id uuid references household_member(id),
    status task_status default 'TODO',
    completed_at timestamptz
);

-- NO UNIQUE CONSTRAINT (puoi assegnare stesso task in giorni diversi)

-- ============================================
-- PANTRY / FRIDGE / FREEZER ITEMS
-- ============================================

create table if not exists pantry_item (
    id uuid primary key default gen_random_uuid(),
    household_id uuid references household(id) on delete cascade,
    name text not null,
    quantity integer default 1,
    area area_type not null,
    expiration_date date,
    barcode text,
    created_at timestamptz default now()
);

-- ============================================
-- SHOPPING LIST
-- ============================================

create table if not exists shopping_item (
    id uuid primary key default gen_random_uuid(),
    household_id uuid references household(id) on delete cascade,
    name text not null,
    quantity integer default 1,
    status shopping_status default 'PENDING',
    created_at timestamptz default now()
);

-- ============================================
-- NOTIFICATIONS
-- ============================================

create table if not exists notifications (
    id uuid primary key default gen_random_uuid(),
    household_id uuid references household(id) on delete cascade,
    title text not null,
    description text,
    type notification_type,
    read boolean default false,
    created_at timestamptz default now()
);

-- ============================================
-- DIET DOCUMENT
-- ============================================

create table if not exists diet_document (
    id uuid primary key default gen_random_uuid(),
    member_id uuid references household_member(id) on delete cascade,
    url text not null,
    uploaded_at timestamptz default now()
);

-- ============================================
-- ACTIVITY DAYS (SEMPLIFICATO)
-- ============================================

create table if not exists member_activity_days (
    id uuid primary key default gen_random_uuid(),
    member_id uuid references household_member(id) on delete cascade,
    day date not null,
    has_tasks boolean default true,
    created_at timestamptz default now(),
    constraint unique_member_day unique (member_id, day)
);

-- ============================================
-- GOOGLE CALENDAR INTEGRATION
-- ============================================

create table if not exists google_calendar_integration (
    id uuid primary key default gen_random_uuid(),
    member_id uuid references household_member(id) on delete cascade,

    oauth_provider text default 'google',        -- provider OAuth
    access_token text,                           -- access token corrente
    refresh_token text,                          -- per ottenere nuovi token
    token_expires_at timestamptz,                -- ora in cui il token scade

    external_calendar_id text,                   -- es: primary o id custom

    last_sync_at timestamptz,
    created_at timestamptz default now()
);

-- ============================================
-- CONSUMPTION HISTORY (OPZIONALE)
-- ============================================

create table if not exists consumption_history (
    id uuid primary key default gen_random_uuid(),
    pantry_item_id uuid references pantry_item(id) on delete set null,
    household_id uuid references household(id) on delete cascade,
    consumed_at timestamptz default now(),
    quantity integer default 1
);

-- ============================================
-- RPC FUNCTIONS
-- ============================================

-- 1) Assegna task a più membri
create or replace function assign_task_to_members(task uuid, members uuid[])
returns void as $$
begin
    insert into task_assignment (task_id, member_id)
    select task, unnest(members)
    on conflict do nothing;
end;
$$ language plpgsql;

-- 2) Registra activity day
create or replace function register_activity(member uuid, day date)
returns void as $$
begin
    insert into member_activity_days (member_id, day)
    values (member, day)
    on conflict do nothing;
end;
$$ language plpgsql;

-- 3) Aggiunta massiva prodotti da OCR + AI
create or replace function add_pantry_items_from_json(items jsonb)
returns void as $$
begin
  insert into pantry_item (household_id, name, quantity, area, expiration_date)
  select 
    (items->>'household_id')::uuid,
    p->>'name',
    coalesce((p->>'qty')::int, 1),
    (p->>'area')::area_type,
    (p->>'exp')::date
  from jsonb_array_elements(items->'products') as p;
end;
$$ language plpgsql;
