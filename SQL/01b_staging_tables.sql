-- Create staging tables

create table if not exists raw_families (
    family_name text,
    order_name text
);

create table if not exists raw_orders (
    order_name text
);

create table if not exists raw_districts (
    district_name text
);

create table if not exists raw_places (
    place_name text,
    district_name text
);


create table if not exists raw_taxa (
    family text,
    genus text,
    species text,
    is_hybrid boolean,
    subsp text,
    var text,
    form text,
    cultivar text,
    selection text,
    taxon_level text
);

create table if not exists raw_taxon_common_names (
    genus text,
    species text,
    is_hybrid boolean,
    subsp text,
    var text,
    form text,
    selection text,
    cultivar text,
    common_name text
);

create table if not exists raw_trees (
    updated_at date,
    dataset text,
    gisid text,
    genus text,
    species text,
    is_hybrid boolean,
    subsp text,
    var text,
    form text,
    selection text,
    cultivar text,
    planting_year integer,
    tree_type text,
    trunk_circ double precision,
    tree_height double precision,
    place_name text,
    district_name text,
    lon double precision,
    lat double precision,
    is_duplicate_location boolean,
    art_dtsch text,
    gattung_deutsch text
);

create table if not exists raw_taxon_icons (
    genus text,
    species text,
    is_hybrid boolean,
    subsp text,
    var text,
    form text,
    selection text,
    cultivar text,
    icon_id integer,
    allow_fallback boolean
);