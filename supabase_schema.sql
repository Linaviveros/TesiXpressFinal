-- TesiXpress — Supabase schema
-- Usa auth nativo de Supabase para usuarios (auth.users).

create table if not exists public.chats (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  title text,
  style text check (style in ('APA','IEEE')),
  created_at timestamp with time zone default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid references public.chats(id) on delete cascade,
  role text check (role in ('user','assistant','system')),
  content text not null,
  created_at timestamp with time zone default now()
);

alter table public.chats enable row level security;
alter table public.messages enable row level security;

create policy "chats_select_own"
on public.chats for select
using (auth.uid() = user_id);

create policy "chats_insert_own"
on public.chats for insert
with check (auth.uid() = user_id);

create policy "chats_update_own"
on public.chats for update
using (auth.uid() = user_id);

create policy "chats_delete_own"
on public.chats for delete
using (auth.uid() = user_id);

create policy "messages_select_own"
on public.messages for select
using (exists (select 1 from public.chats c where c.id = chat_id and c.user_id = auth.uid()));

create policy "messages_insert_own"
on public.messages for insert
with check (exists (select 1 from public.chats c where c.id = chat_id and c.user_id = auth.uid()));

create policy "messages_update_own"
on public.messages for update
using (exists (select 1 from public.chats c where c.id = chat_id and c.user_id = auth.uid()));

create policy "messages_delete_own"
on public.messages for delete
using (exists (select 1 from public.chats c where c.id = chat_id and c.user_id = auth.uid()));
