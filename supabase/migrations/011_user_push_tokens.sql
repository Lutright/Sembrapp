-- Tokens FCM por usuario/dispositivo (notificaciones push).
create table if not exists public.user_push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  fcm_token text not null,
  platform text,
  updated_at timestamptz not null default now(),
  unique (user_id, fcm_token)
);

create index if not exists user_push_tokens_user_id_idx
  on public.user_push_tokens (user_id);

alter table public.user_push_tokens enable row level security;

create policy "Usuario gestiona sus propios tokens push"
  on public.user_push_tokens for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
