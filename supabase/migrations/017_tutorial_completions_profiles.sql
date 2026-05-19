-- Tutorial: progreso remoto (sync opcional) + flag en perfil para desactivar guías.
-- La app usa SharedPreferences como fuente de verdad; esta tabla complementa multi-dispositivo.

create table if not exists public.tutorial_completions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  tutorial_key text not null,
  completed_at timestamptz not null default now(),
  unique (user_id, tutorial_key)
);

create index if not exists tutorial_completions_user_id_idx
  on public.tutorial_completions (user_id);

alter table public.tutorial_completions enable row level security;

create policy "Usuario ve sus tutorial_completions"
  on public.tutorial_completions for select
  using (auth.uid() = user_id);

create policy "Usuario inserta tutorial_completions"
  on public.tutorial_completions for insert
  with check (auth.uid() = user_id);

create policy "Usuario actualiza tutorial_completions"
  on public.tutorial_completions for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

alter table public.profiles
  add column if not exists tutorials_enabled boolean not null default true;

comment on column public.profiles.tutorials_enabled is 'Si false, la app no muestra tutoriales contextuales automáticos (sigue pudiendo usarse ayuda manual si se desea).';
