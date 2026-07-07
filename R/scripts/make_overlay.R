library(sf)
library(ggplot2)

trees <- st_read("trees_resolved.geojson") %>%
  st_transform(3857)

# Transform bounds to 3857 too
bbox <- st_bbox(c(xmin = 13.091378, xmax = 13.756759,
                  ymin = 52.341184, ymax = 52.659939),
                crs = 4326) %>%
  st_as_sfc() %>%
  st_transform(3857) %>%
  st_bbox()

ggplot(trees) +
  geom_sf(aes(color = fillcolor), size = 0.1, alpha = 0.6, shape = 16) +
  scale_color_identity() +
  coord_sf(xlim = c(bbox["xmin"], bbox["xmax"]),
           ylim = c(bbox["ymin"], bbox["ymax"]),
           crs = 3857,
           expand = FALSE) +
  theme_void() +
  theme(panel.background = element_rect(fill = "transparent", color = NA),
        plot.background = element_rect(fill = "transparent", color = NA))

ggsave("../website/src/assets/img/berlin_overview.png", width = 20, height = 15.74, dpi = 300, bg = "transparent")