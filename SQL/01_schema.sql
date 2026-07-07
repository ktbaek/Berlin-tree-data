-- table orders
create table if not exists orders (
    order_id serial primary key, 
    order_name text not null unique
);

-- table families
create table if not exists families (
    family_id serial primary key,
    family_name text not null unique,
    order_id integer not null references orders(order_id)
);

-- table districts
create table if not exists districts (
    district_id serial primary key,
    district_name text not null unique
);

-- table places
CREATE TABLE IF NOT EXISTS places (
    place_id SERIAL PRIMARY KEY,
    district_id INTEGER NOT NULL REFERENCES districts(district_id),
    place_name TEXT,

    CHECK (
        place_name IS NULL
        OR place_name <> ''
    )
);

-- unique named places within district
CREATE UNIQUE INDEX unique_named_places
ON places (district_id, place_name)
WHERE place_name IS NOT NULL;

-- only one district-only row per district
CREATE UNIQUE INDEX unique_district_only_place
ON places (district_id)
WHERE place_name IS NULL;

-- table taxon_common_names
create table if not exists taxon_common_names (
    common_name_id serial primary key,
    taxon_id integer not null references taxa(taxon_id) ON DELETE CASCADE,
    common_name TEXT NOT NULL,

    -- avoid duplicates per taxon
    UNIQUE (taxon_id, common_name),

    -- basic sanity
    CHECK (common_name <> '')
);

-- table trees
create table if not exists trees (
    updated_at date,
    dataset text not null,
    gisid text primary key,
    taxon_id integer references taxa(taxon_id),
    lat double precision not null,
    lon double precision not null,
    place_id integer references places(place_id),
    planting_year integer,
    tree_type text,
    trunc_circ double precision,
    tree_height double precision,
    is_duplicate_location boolean not null default false 
);

-- table taxon_icons
create table if not exists taxon_icons (
    id serial primary key,
    taxon_id INTEGER NOT NULL REFERENCES taxa(taxon_id),
    icon_id integer,
    allow_fallback boolean not null default TRUE
);

-- table taxon_descriptions
CREATE TABLE if not exists taxon_descriptions (
    taxon_id INTEGER PRIMARY KEY REFERENCES taxa(taxon_id),
    prose_html TEXT,
    source TEXT, -- e.g. 'LLM', 'manual'
    created_at DATE,
    updated_at TIMESTAMP
);

