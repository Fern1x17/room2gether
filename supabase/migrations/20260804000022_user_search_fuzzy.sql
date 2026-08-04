-- Buscador de usuarios: coincidencias parecidas además de las literales (CU-20)
--
-- Lo que YA funcionaba y no cambia: `ilike '%texto%'` es coincidencia por
-- subcadena, así que buscar "juan" ya encontraba "angeljuan". Eso no era el
-- problema.
--
-- Lo que se añade: tolerancia a erratas por similitud de trigramas
-- (`word_similarity` de pg_trgm), como segundo camino en OR con el LIKE.
-- Se usa `word_similarity` y no `similarity` porque mide lo escrito contra el
-- TROZO que mejor encaja del nombre, no contra el nombre entero: comparar algo
-- corto con un nombre largo daría siempre un parecido bajísimo.
--
-- Se compara con la función y no con el operador `<%` porque ese operador lee
-- su umbral de `pg_trgm.word_similarity_threshold`, y en Supabase el rol de
-- las migraciones no tiene permiso para fijar ese parámetro dentro de una
-- función. Con la función el umbral queda escrito aquí, que además es más
-- explícito: el resultado no depende de la sesión que llame.
--
-- COSTE, y es un compromiso consciente: `word_similarity` no puede usar el
-- índice GIN, así que esta segunda rama del OR obliga a recorrer la tabla. Con
-- el volumen de una sola ciudad es irrelevante. Cuando `profiles` crezca de
-- verdad habrá que revisarlo (lo natural: no calcular la rama difusa salvo que
-- la literal devuelva poco).
--
-- 0.4 tolera una errata en nombres de longitud normal. Ojo con las palabras
-- muy cortas: los trigramas son implacables ahí, y un cambio de vocal en una
-- palabra de cuatro letras baja el parecido a ~0.25, por debajo de cualquier
-- umbral usable. Para eso haría falta comparación fonética, no trigramas.

create or replace function public.search_profiles(
  p_query  text,
  p_limit  integer default 20,
  p_offset integer default 0
)
returns table (
  id           uuid,
  display_name text,
  avatar_url   text,
  city_name    text
)
language sql
stable
security definer
set search_path = public, extensions
as $$
  with q as (
    select
      -- Longitud sobre el texto crudo: el escapado añade caracteres y
      -- falsearía el mínimo de 2.
      length(btrim(coalesce(p_query, ''))) as needle_length,
      public.immutable_unaccent(
        replace(
          replace(
            replace(btrim(coalesce(p_query, '')), '\', '\\'),
            '%', '\%'
          ),
          '_', '\_'
        )
      ) as needle,
      -- Sin escapar: la similitud no interpreta comodines, y meterle barras
      -- invertidas falsearía el parecido.
      public.immutable_unaccent(btrim(coalesce(p_query, ''))) as raw_needle
  )
  select p.id, p.display_name, p.avatar_url, c.name
    from public.profiles p
    cross join q
    left join public.cities c on c.id = p.city_id
   where auth.uid() is not null                  -- sin sesión no se busca
     and q.needle_length >= 2                    -- mismo suelo que el cliente
     and p.id <> auth.uid()                      -- no me encuentro a mí mismo
     and (
       -- 1. Contiene lo escrito, tal cual. Esta rama sí usa el índice.
       public.immutable_unaccent(p.display_name) ilike '%' || q.needle || '%'
       -- 2. O se le parece lo bastante.
       or word_similarity(
            q.raw_needle, public.immutable_unaccent(p.display_name)
          ) >= 0.4
     )
     and not exists (
       select 1
         from public.blocks b
        where (b.blocker_id = auth.uid() and b.blocked_id = p.id)
           or (b.blocker_id = p.id       and b.blocked_id = auth.uid())
     )
   -- Primero lo literal (empieza por lo escrito, luego lo contiene) y después
   -- lo parecido, de más a menos. Así una aproximación nunca se cuela por
   -- delante de una coincidencia exacta. El id desempata para que la
   -- paginación por offset sea estable entre páginas.
   order by
     case
       when public.immutable_unaccent(p.display_name)
              ilike q.needle || '%'             then 0
       when public.immutable_unaccent(p.display_name)
              ilike '%' || q.needle || '%'      then 1
       else                                          2
     end asc,
     word_similarity(
       q.raw_needle, public.immutable_unaccent(p.display_name)
     ) desc,
     length(p.display_name) asc,
     p.display_name asc,
     p.id asc
   limit  least(greatest(coalesce(p_limit, 20), 1), 50)
   offset greatest(coalesce(p_offset, 0), 0);
$$;

revoke all on function public.search_profiles(text, integer, integer) from public;
grant execute on function public.search_profiles(text, integer, integer) to authenticated;
