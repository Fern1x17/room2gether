-- Crea automáticamente la fila de profiles al registrarse un usuario.
-- security definer: se ejecuta con privilegios del owner de la función, no del
-- usuario que se está registrando (que todavía no tiene sesión/JWT en ese instante),
-- así que evita el bloqueo por RLS en public.profiles.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, age)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1)),
    (new.raw_user_meta_data ->> 'age')::int
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();
