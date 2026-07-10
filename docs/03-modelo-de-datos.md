# Modelo de Datos — Room2gether

> Diagrama entidad-relación en Mermaid. Se renderiza en GitHub y en VS Code
> (con la extensión de Mermaid). Mantenlo sincronizado con la skill
> `supabase-schema` y con las migraciones reales.

```mermaid
erDiagram
    PROFILES ||--o{ LISTINGS : "publica"
    PROFILES ||--o{ MESSAGES : "envía"
    PROFILES ||--o{ REPORTS : "reporta"
    LISTINGS ||--o{ CONVERSATIONS : "origina"
    CONVERSATIONS ||--o{ MESSAGES : "contiene"
    PROFILES ||--o{ CONVERSATIONS : "participa"
    PROFILES ||--o{ BLOCKS : "bloquea"
    CITIES ||--o{ PROFILES : "es ciudad de"
    CITIES ||--o{ LISTINGS : "ubica"
    LISTINGS ||--o| LISTING_ADDRESSES : "dirección exacta"

    PROFILES {
        uuid id PK
        text display_name
        date birthdate
        text bio
        text avatar_url
        uuid city_id FK
        int budget_min
        int budget_max
        bool is_smoker
        bool has_pets
        bool is_verified
        text role "user (usuario) o moderator (moderador)"
        timestamptz created_at
    }

    LISTINGS {
        uuid id PK
        uuid owner_id FK
        text type
        text title
        text description
        uuid city_id FK
        text neighborhood
        int price "solo offering"
        int budget_min "solo seeking"
        int budget_max "solo seeking"
        bool is_featured
        timestamptz featured_until
        bool is_business
        text status
        timestamptz created_at
    }

    CONVERSATIONS {
        uuid id PK
        uuid user_a FK
        uuid user_b FK
        uuid listing_id FK
        timestamptz created_at
    }

    MESSAGES {
        uuid id PK
        uuid conversation_id FK
        uuid sender_id FK
        text content
        timestamptz read_at
        timestamptz created_at
    }

    REPORTS {
        uuid id PK
        uuid reporter_id FK
        uuid reported_user_id FK
        uuid reported_listing_id FK
        text reason
        text status
    }

    BLOCKS {
        uuid blocker_id FK
        uuid blocked_id FK
    }

    CITIES {
        uuid id PK
        text name "nombre canonico, ej. A Coruna"
        text normalized_name "minusculas y sin tildes, ej. a coruna"
        text_array aliases "alternativos normalizados, ej. la coruna"
        text google_place_id "identidad canonica (Google Places), unico"
        bool is_active "ciudad foco de marketing; no limita el selector"
        timestamptz created_at
        timestamptz updated_at
    }

    LISTING_ADDRESSES {
        uuid listing_id PK "FK a listings, 1:1"
        text formatted_address
        text google_place_id
        double latitude
        double longitude
        bool is_public "true = mostrar direccion completa"
        timestamptz created_at
        timestamptz updated_at
    }
```

## Notas
- Toda tabla con RLS activado (ver skill `supabase-schema`).
- `profiles.id` = `auth.users.id` de Supabase.
- Las fotos de las publicaciones pueden ir en un `text[]` o en una tabla
  `listing_photos` aparte si necesitas orden/metadatos.
- `cities` (RF-15): registro de ciudades poblado bajo demanda desde Google
  Places. El selector sugiere cualquier localidad de España vía Places
  Autocomplete; al elegir una, la RPC `get_or_create_city` (security definer)
  devuelve su fila creándola si es la primera vez. La identidad canónica es
  `google_place_id` (único); `normalized_name` ya NO es único (hay municipios
  homónimos en España) y solo sirve para casar filas antiguas sin place_id.
  `is_active` se reinterpreta como "ciudad foco de marketing" y no limita el
  selector. El cliente sigue sin escribir directamente (RLS solo SELECT);
  `city_id` usa `on delete restrict`.
- `listing_addresses` (CU-06): dirección exacta opcional de una publicación,
  1:1 con `listings` y en tabla propia porque RLS es por fila — así "mostrar
  solo el barrio" se garantiza en la BD. SELECT solo si `is_public` o si la
  publicación es del usuario; escritura solo del dueño. El barrio y la
  dirección vienen de Google Places (el catálogo `neighborhoods` se retiró):
  `listings.neighborhood` sigue siendo texto y almacena el nombre
  canónico elegido en el selector.
