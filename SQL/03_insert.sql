-- insert orders
INSERT INTO orders (order_name)
SELECT DISTINCT ro.order_name
FROM raw_orders ro;

-- insert families
INSERT INTO families (family_name, order_id)
SELECT DISTINCT
    rf.family_name,
    o.order_id
FROM raw_families rf
JOIN orders o USING (order_name)
WHERE rf.family_name <> '' AND rf.order_name <> '';

-- insert districts
INSERT INTO districts (district_name)
SELECT DISTINCT rd.district_name
FROM raw_districts rd;

-- insert places
INSERT INTO places (place_name, district_id)
SELECT DISTINCT 
    rp.place_name,
    d.district_id
FROM raw_places rp
JOIN districts d USING (district_name)
WHERE rp.place_name <> '' AND rp.district_name <> '';