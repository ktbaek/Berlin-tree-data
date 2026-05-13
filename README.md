# Tree data Berlin

## Data
Data was downloaded as `.gpkg` files on May 11, 2026 from https://gdi.berlin.de/geonetwork/srv/ger/catalog.search#/metadata/48ad3a23-d974-3458-90b7-deb0d5941c0a. Two files were downloaed, one for street trees (strassenbäume) and one for park trees (anlagenbaüme).

The data was converted to `.csv` files in R using the `sf` package, including converting the coordinates to WGS84 format:

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