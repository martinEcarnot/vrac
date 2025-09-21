library(osmdata)
library(sf)
library(ggplot2)
library(dplyr)
library(ggspatial)
library(prettymapr)
library(raster)
library(leaflet)



crs_metric <- 2154  # Lambert-93 (mètres)

# --- paramètres ---
center <- c(3.8777, 43.6119)  # Montpellier
half_side <- 1000             # demi-côté en mètres (=> carré 2x2 km)

# combien de carrés autour du centre (en pas de 2*half_side)
n_lon <- 6  # nombre de pas en longitude
n_lat <- 6  # nombre de pas en latitude

# --- fonction pour créer un carré ---
make_square <- function(lon, lat, half_side = 1000) {
  pt <- st_sfc(st_point(c(lon, lat)), crs = 4326)
  pt_m <- st_transform(pt, crs_metric)
  coords <- st_coordinates(pt_m)[1, ]
  x <- coords["X"]; y <- coords["Y"]
  
  st_sfc(
    st_polygon(list(matrix(
      c(x - half_side, y - half_side,
        x + half_side, y - half_side,
        x + half_side, y + half_side,
        x - half_side, y + half_side,
        x - half_side, y - half_side),
      ncol = 2, byrow = TRUE))),
    crs = crs_metric
  )
}

# --- fonction pour compter les bâtiments dans un carré ---
count_buildings <- function(square) {
  bbox_wgs84 <- st_bbox(st_transform(square, 4326))
  q <- opq(bbox = bbox_wgs84) %>% add_osm_feature(key = "building")
  osm_res <- osmdata_sf(q)
  
  get_geom <- function(x) {
    if (!is.null(x) && "geometry" %in% colnames(x)) x["geometry"] else NULL
  }
  bld_polys <- rbind(get_geom(osm_res$osm_polygons),
                     get_geom(osm_res$osm_multipolygons))
  
  if (is.null(bld_polys) || nrow(bld_polys) == 0) return(0)
  nrow(bld_polys)
}

# --- grille de points autour du centre ---
lon0 <- center[1]; lat0 <- center[2]
step_deg <- 0.02  # ~2 km en lat/lon (approx, suffisant pour construire la grille)
lons <- seq(lon0 - step_deg, lon0 + step_deg, length.out = n_lon)
lats <- seq(lat0 - step_deg, lat0 + step_deg, length.out = n_lat)
grid_points <- expand.grid(lon = lons, lat = lats)

# --- boucle ---
results <- list()
for (i in 1:nrow(grid_points)) {
  lon <- grid_points$lon[i]; lat <- grid_points$lat[i]
  square <- make_square(lon, lat, half_side)
  count <- count_buildings(square)
  
  results[[i]] <- st_sf(
    id = i,
    count_buildings = count,
    geometry = square
  )
  cat("Carré", i, ": ", count, "bâtiments\n")
}

squares_sf <- do.call(rbind, results)
centroids <- st_point_on_surface(squares_sf)
centroids_sf <- st_sf(label = squares_sf$count_buildings, geometry = centroids)

# centroïdes "au centre des polygones"
centroids <- st_point_on_surface(st_geometry(squares_sf))

# construire un sf avec juste les labels
centroids_sf <- st_sf(
  label = squares_sf$count_buildings,
  geometry = centroids,
  crs = st_crs(squares_sf)
)

# --- carte ---

# transformation en WGS84
squares_wgs84 <- st_transform(squares_sf, 4326)
centroids_wgs84 <- st_transform(centroids_sf, 4326)

# s'assurer que tous les carrés ont un nombre
squares_wgs84$count_buildings[is.na(squares_wgs84$count_buildings)] <- 0
centroids_wgs84$label[is.na(centroids_wgs84$label)] <- 0

# carte interactive
leaflet(squares_wgs84) %>%
  addProviderTiles("OpenStreetMap") %>%
  addPolygons(
    fillColor = ~colorNumeric("plasma", count_buildings)(count_buildings),
    weight = 1,
    color = "black",
    fillOpacity = 0.3,   # plus transparent
    popup = ~paste("Bâtiments :", count_buildings)
  ) %>%
  addLabelOnlyMarkers(
    data = centroids_wgs84,
    label = ~as.character(label),
    labelOptions = labelOptions(
      noHide = TRUE, direction = "center", textOnly = TRUE,
      style = list("color" = "white", "font-weight" = "bold")
    )
  )
