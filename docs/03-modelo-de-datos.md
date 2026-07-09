# Modelo de Datos — Roomie

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
        bool is_active "solo las activas salen en el selector"
        timestamptz created_at
        timestamptz updated_at
    }
```

## Notas
- Toda tabla con RLS activado (ver skill `supabase-schema`).
- `profiles.id` = `auth.users.id` de Supabase.
- Las fotos de las publicaciones pueden ir en un `text[]` o en una tabla
  `listing_photos` aparte si necesitas orden/metadatos.
- `cities` (RF-15): catálogo gestionado por migración/panel — el cliente solo
  lee. `city_id` usa `on delete restrict`: una ciudad con perfiles o
  publicaciones no puede borrarse; para retirarla se pone `is_active = false`
  y deja de aparecer en el selector sin romper datos históricos.
