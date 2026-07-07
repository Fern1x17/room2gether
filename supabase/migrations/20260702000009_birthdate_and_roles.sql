-- Cambios según docs/03-modelo-de-datos.md:
--  1. profiles.age (int) pasa a profiles.birthdate (date): se guarda la fecha
--     de nacimiento en vez de la edad.
--  2. Nuevo campo de rol en profiles ("tipo (usuario, moderador...)" en el
--     modelo; en la BD se llama role, en inglés, siguiendo la convención del
--     proyecto): 'user' | 'moderator'.

alter table public.profiles add column birthdate date;

-- Backfill: aproxima la fecha de nacimiento de las filas existentes a partir
-- de la edad. Se pierde el día/mes real (inevitable al convertir edad → fecha);
-- las cuentas existentes quedan con el aniversario en la fecha de la migración.
update public.profiles
set birthdate = (current_date - make_interval(years => age))::date
where birthdate is null;

alter table public.profiles alter column birthdate set not null;

-- Mayoría de edad (RF-02): equivale al antiguo check (age >= 18).
alter table public.profiles
  add constraint profiles_adult_check
  check (birthdate <= (current_date - interval '18 years'));

alter table public.profiles drop column age;

alter table public.profiles
  add column role text not null default 'user'
  check (role in ('user', 'moderator'));

-- El trigger de alta ahora lee birthdate de los metadatos de signUp().
-- role no se acepta desde el cliente: siempre entra como 'user' (default);
-- promover a moderador se hace desde el servidor (service_role).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, birthdate)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1)),
    (new.raw_user_meta_data ->> 'birthdate')::date
  );
  return new;
end;
$$;
