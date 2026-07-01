-- Extensiones necesarias
create extension if not exists "pgcrypto";

-- Función genérica para mantener updated_at al día en cualquier tabla
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
