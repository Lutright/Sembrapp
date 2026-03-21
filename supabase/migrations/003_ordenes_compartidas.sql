-- RF-CCOM-02: Órdenes compartidas en la red comunitaria
alter table public.ordenes
  add column if not exists compartida_en_red boolean not null default false,
  add column if not exists compartida_at timestamptz;

-- El campesino puede marcar su orden como compartida
create policy "Campesino actualiza compartida_en_red en sus órdenes"
  on public.ordenes for update
  using (auth.uid() = campesino_id);
