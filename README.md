# From raw data to structured taxonomy: Berlin’s urban tree dataset

## Data source
Data was downloaded from [GDI-BE](https://gdi.berlin.de/geonetwork/srv/ger/catalog.search#/metadata/48ad3a23-d974-3458-90b7-deb0d5941c0a) on May 11, 2026. Two files were downloaded, one for street trees (Strassenbäume) and one for park trees (Anlagenbaüme). The two datasets contain information about ~950,000 trees in Berlin. The original datasets, not included here, are licensed under `DL-DE-ZERO-2.0`.

The data was converted from `.gpkg` to `.csv` files in R using the `sf` package, including converting the coordinates to WGS84 format:

```R
df <- sf::st_read("raw_data/strassenbaeume.gpkg")
df |> 
    mutate(
        wgs84 = sf::st_transform(geom, 4326),
        lon = sf::st_coordinates(wgs84)[, 1],
        lat = sf::st_coordinates(wgs84)[, 2]
        ) |>
    select(-wgs84)
```

