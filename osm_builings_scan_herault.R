# ============================================================
# Script complet : comptage des bâtiments par tuile depuis un .pbf local
# ============================================================

library(sf)
library(osmextract)
library(leaflet)

# -------------------
# PARAMÈTRES À ADAPTER
# -------------------

# Chemin vers le fichier .pbf téléchargé (extrait Geofabrik)
pbf_file <- "/home/ecarnot/Documents/INRA/Personnel/sans_bat/languedoc-roussillon-250924.osm.pbf"

# Centre d'analyse (ici Montpellier)
center_lonlat <- c(3.8777, 43.6119)

# Taille d'une tuile (km)
cell_km <- 2

# Dimension de la grille (ex. 5x5 tuiles)
grid_nx <- 2
grid_ny <- 2

# -------------------
# LECTURE DES BÂTIMENTS
# -------------------

# Charger uniquement les multipolygones de type "building"
bld_sf <- oe_read(
  pbf_file,
  layer = "multipolygons",
  query = "SELECT * FROM multipolygons WHERE building IS NOT NULL"
)

# Reprojeter en Lambert-93 (mètres)
bld_sf <- st_transform(bld_sf, 2154)

# -------------------
# CRÉER LA GRILLE AUTOUR DU CENTRE
# -------------------

# Point central
center <- st_sfc(st_point(center_lonlat), crs = 4326) |> st_transform(2154)

# Créer la grille (cell_km converti en mètres)
grid <- st_make_grid(
  center,
  cellsize = c(cell_km*1000, cell_km*1000),
  n = c(grid_nx, grid_ny),
  what = "polygons",
  square = TRUE
)

grid_sf <- st_sf(id = 1:length(grid), geometry = grid)

# -------------------
# COMPTER LES BÂTIMENTS PAR TUILE
# -------------------

counts <- sapply(1:nrow(grid_sf), function(i) {
  inter <- st_intersection(bld_sf, grid_sf[i, ])
  nrow(inter)
})

grid_sf$count <- counts

# -------------------
# PRÉPARER LES CENTROÏDES POUR LES LABELS
# -------------------

centroids <- st_point_on_surface(st_geometry(grid_sf))
centroids_sf <- st_sf(
  label = grid_sf$count,
  geometry = centroids,
  crs = st_crs(grid_sf)
)

# -------------------
# CARTE INTERACTIVE LEAFLET
# -------------------

grid_wgs84 <- st_transform(grid_sf, 4326)
centroids_wgs84 <- st_transform(centroids_sf, 4326)

leaflet(grid_wgs84) %>%
  addProviderTiles("OpenStreetMap") %>%
  addPolygons(
    fillColor = ~colorNumeric("plasma", count)(count),
    color = "black", weight = 1, fillOpacity = 0.3,
    popup = ~paste("Bâtiments :", count)
  ) %>%
  addLabelOnlyMarkers(
    data = centroids_wgs84,
    label = ~as.character(label),
    labelOptions = labelOptions(
      noHide = TRUE, direction = "center", textOnly = TRUE,
      style = list("color" = "white", "font-weight" = "bold")
    )
  )
