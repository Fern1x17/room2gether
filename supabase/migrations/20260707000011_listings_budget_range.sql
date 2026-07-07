-- CU-06: quien busca piso indica un rango de presupuesto (min-max) en vez de
-- un precio. price pasa a usarse solo en publicaciones 'offering'.

alter table public.listings
  add column budget_min int,
  add column budget_max int;

-- Filas 'seeking' existentes: su price era el presupuesto que estaban
-- dispuestos a pagar; se traslada al rango y se limpia price.
update public.listings
set budget_min = price, budget_max = price
where type = 'seeking';

alter table public.listings alter column price drop not null;

update public.listings
set price = null
where type = 'seeking';

-- Coherencia por tipo: offering exige precio; seeking exige rango válido.
alter table public.listings
  add constraint listings_price_by_type_check
  check (
    (type = 'offering' and price is not null)
    or (type = 'seeking' and budget_min is not null and budget_max is not null
        and budget_min <= budget_max)
  );
