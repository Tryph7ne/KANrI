-- Kanri : tables et règles de sécurité.
-- À coller une seule fois dans Supabase → SQL Editor → New query → Run.

create table if not exists public.shops (
  id         text primary key,
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name       text not null check (char_length(name) between 1 and 60),
  act        text not null default '' check (char_length(act) <= 80),
  goal       numeric not null default 0 check (goal >= 0),
  created    timestamptz not null default now()
);

create table if not exists public.entries (
  id         text primary key,
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  shop_id    text not null references public.shops(id) on delete cascade,
  t          text not null check (t in ('vente', 'depense')),
  a          numeric not null check (a >= 0),
  o          integer not null default 0 check (o >= 0),
  d          date not null,
  c          text not null default '' check (char_length(c) <= 60),
  n          text not null default '' check (char_length(n) <= 120),
  created_at timestamptz not null default now()
);

create table if not exists public.settings (
  user_id  uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  currency text not null default '€' check (char_length(currency) <= 8)
);

create index if not exists entries_user_date on public.entries (user_id, d);
create index if not exists entries_shop on public.entries (shop_id);
create index if not exists shops_user on public.shops (user_id);

-- Chaque personne ne voit et ne modifie que ses propres données.
alter table public.shops    enable row level security;
alter table public.entries  enable row level security;
alter table public.settings enable row level security;

drop policy if exists "own shops" on public.shops;
create policy "own shops" on public.shops
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own entries" on public.entries;
create policy "own entries" on public.entries
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid() and exists (select 1 from public.shops s where s.id = shop_id and s.user_id = auth.uid()));

drop policy if exists "own settings" on public.settings;
create policy "own settings" on public.settings
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
