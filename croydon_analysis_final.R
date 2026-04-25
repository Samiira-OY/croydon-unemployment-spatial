# =============================================================================
# Spatial Analysis of Unemployment in Croydon, London
# Author: Samiira Osman Yusuf
# BSc Social Data Science, University College London
# =============================================================================
# Data sources required (place in working directory):
#   - ts066.csv                                          (ONS Census 2021 employment table)
#   - Lower_layer_Super_Output_Areas_2021_EW_BGC_V3.geojson (ONS LSOA boundaries)
#   - OA_2021_EW_BGC_V2.shp                             (ONS OA boundaries)
#   - File_1_IoD2025_Index_of_Multiple_Deprivation.xlsx  (MHCLG IMD 2025)
# =============================================================================

# ── 0. Load Packages ──────────────────────────────────────────────────────────

library(sf)
library(dplyr)
library(stringr)
library(ggplot2)
library(classInt)
library(ggspatial)


# ── 1. Load and Prepare Employment Data ───────────────────────────────────────

# Load Census 2021 OA-level employment table (ts066)
employment_input <- read.csv("ts066.csv")

# Calculate unemployment rate as % of economically active population
employment <- data.frame(
  OA        = employment_input$OA,
  Unemployed = (employment_input$ts0660013 / employment_input$ts0660001) * 100
)


# ── 2. Load Spatial Boundaries ────────────────────────────────────────────────

# Read LSOA 2021 polygons and transform to British National Grid (EPSG:27700)
lsoa <- st_read("Lower_layer_Super_Output_Areas_2021_EW_BGC_V3.geojson",
                quiet = TRUE) %>%
  st_transform(27700)

# Filter to Croydon LSOAs only
croydon_lsoa <- lsoa %>%
  filter(str_detect(LSOA21NM, regex("^Croydon\\b", ignore_case = TRUE)))

# Read OA polygons (OA file already contains LSOA21CD)
oa <- st_read("OA_2021_EW_BGC_V2.shp", quiet = TRUE)

# Set CRS if missing
if (is.na(st_crs(oa))) st_crs(oa) <- 27700
oa <- st_transform(oa, 27700)

# Filter to Croydon OAs using LSOA name field
oa_croydon <- oa %>%
  filter(str_detect(LSOA21NM, regex("^Croydon\\b", ignore_case = TRUE)))


# ── 3. Join Unemployment to OAs and Aggregate to LSOA ────────────────────────

# Select relevant columns from employment data
unemp_oa <- employment %>% select(OA, Unemployed)

# Join unemployment onto Croydon OAs
oa_croydon <- oa_croydon %>%
  mutate(OA = OA21CD) %>%
  left_join(unemp_oa, by = "OA")

# Aggregate OA unemployment up to LSOA (mean rate)
unemp_lsoa <- oa_croydon %>%
  st_drop_geometry() %>%
  group_by(LSOA21CD) %>%
  summarise(Unemployed = mean(Unemployed, na.rm = TRUE), .groups = "drop")

# Join aggregated unemployment onto Croydon LSOA polygons
croydon_lsoa_data <- croydon_lsoa %>%
  left_join(unemp_lsoa, by = "LSOA21CD")

# Check for missing values
sum(is.na(croydon_lsoa_data$Unemployed))


# ── 4. Jenks Classification for Choropleth Mapping ───────────────────────────

x    <- croydon_lsoa_data$Unemployed
x_ok <- x[is.finite(x)]
k    <- min(5, length(unique(x_ok)))
brks <- classIntervals(x_ok, n = k, style = "quantile")$brks

croydon_lsoa_data$unemp_grp <- cut(
  croydon_lsoa_data$Unemployed,
  breaks = brks,
  include.lowest = TRUE
)


# ── 5. Visualisations ─────────────────────────────────────────────────────────

# Fig 1: Distribution of unemployment rates (histogram)
ggplot(croydon_lsoa_data, aes(Unemployed)) +
  geom_histogram(bins = 30, fill = "#b2182b", colour = "white") +
  labs(
    title = "Distribution of unemployment rates (LSOA)",
    x     = "Unemployment rate (%)",
    y     = "Number of LSOAs"
  ) +
  theme_minimal()

# Fig 2a: Unemployment choropleth map (basic)
ggplot(croydon_lsoa_data) +
  geom_sf(aes(fill = unemp_grp), colour = "white", linewidth = 0.15) +
  scale_fill_brewer(palette = "Reds", na.value = "grey90",
                    name = "Unemployment\n(quintiles)") +
  labs(
    title    = "Unemployment rate (%) by LSOA — Croydon",
    subtitle = "OA unemployment aggregated to LSOA",
    caption  = "Source: Census OA unemployment; ONS LSOA boundaries"
  ) +
  annotation_scale(location = "bl", width_hint = 0.35) +
  annotation_north_arrow(location = "tl",
                          style = north_arrow_fancy_orienteering) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.major = element_line(colour = "grey90", linewidth = 0.2),
    legend.position  = "right"
  )

# Fig 2b: Unemployment choropleth map (with borough outline)
croydon_map     <- st_transform(croydon_lsoa_data, 27700)
croydon_outline <- st_union(croydon_map)

ggplot() +
  geom_sf(data = croydon_map, aes(fill = unemp_grp),
          colour = "white", linewidth = 0.15) +
  geom_sf(data = croydon_outline, fill = NA,
          colour = "grey20", linewidth = 0.6) +
  scale_fill_brewer(palette = "Reds", na.value = "grey90",
                    name = "Unemployment\n(quintiles)") +
  annotation_north_arrow(location = "tl",
                          style = north_arrow_fancy_orienteering) +
  annotation_scale(location = "bl", width_hint = 0.35) +
  labs(
    title    = "Unemployment rate (%) by LSOA — Croydon",
    subtitle = "OA unemployment aggregated to LSOA",
    caption  = "Source: Census OA unemployment; ONS LSOA boundaries"
  ) +
  theme_void(base_size = 12) +
  theme(
    legend.position  = "right",
    plot.title       = element_text(face = "bold")
  )


# ── 6. Add IMD 2025 Deprivation Data ─────────────────────────────────────────

library(readxl)

imd <- read_excel("File_1_IoD2025_Index_of_Multiple_Deprivation.xlsx", sheet = 2)

# Inspect column names
names(imd)

# Rename key IMD variables
imd <- imd %>%
  rename(
    LSOA21CD   = `LSOA code (2021)`,
    IMD_rank   = `Index of Multiple Deprivation (IMD) Rank (where 1 is most deprived)`,
    IMD_decile = `Index of Multiple Deprivation (IMD) Decile (where 1 is most deprived 10% of LSOA`
  )

# Join IMD onto Croydon LSOA data
croydon_lsoa_data <- croydon_lsoa_data %>%
  left_join(imd %>% select(LSOA21CD, IMD_rank, IMD_decile),
            by = "LSOA21CD")

# Check
summary(croydon_lsoa_data$IMD_decile)
sum(is.na(croydon_lsoa_data$IMD_decile))

# Fig 4: IMD 2025 deciles choropleth map
reds10 <- c("#fff5f0","#fee0d2","#fcbba1","#fc9272","#fb6a4a",
            "#ef3b2c","#cb181d","#a50f15","#67000d","#3b0000")

ggplot(croydon_lsoa_data) +
  geom_sf(aes(fill = factor(IMD_decile)), colour = "white", linewidth = 0.15) +
  scale_fill_manual(
    values   = reds10,
    name     = "IMD decile\n(1 = most deprived)",
    na.value = "grey90"
  ) +
  labs(
    title    = "Index of Multiple Deprivation (2025) by LSOA — Croydon",
    subtitle = "IMD deciles (1 = most deprived 10%)",
    caption  = "Source: IMD 2025; ONS LSOA boundaries"
  ) +
  annotation_scale(location = "bl", width_hint = 0.35) +
  annotation_north_arrow(location = "tl",
                          style = north_arrow_fancy_orienteering) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.major = element_line(colour = "grey90", linewidth = 0.2),
    legend.position  = "right"
  )


# ── 7. Spatial Autocorrelation ────────────────────────────────────────────────

library(spdep)

# Global OLS model
ols <- lm(Unemployed ~ IMD_rank, data = croydon_lsoa_data)
summary(ols)

# Spatial weights matrix (Queen contiguity)
nb <- poly2nb(croydon_lsoa_data, queen = TRUE)
lw <- nb2listw(nb, style = "W", zero.policy = TRUE)

# Attach OLS residuals
croydon_lsoa_data$ols_resid <- residuals(ols)

# Global Moran's I on OLS residuals
moran_ols <- moran.test(
  croydon_lsoa_data$ols_resid,
  lw,
  zero.policy = TRUE
)
moran_ols


# ── 8. LISA — Local Spatial Clustering ───────────────────────────────────────

croydon_lisa <- st_make_valid(croydon_lsoa_data)

# Spatial weights for LISA
nb_u <- poly2nb(croydon_lisa, queen = TRUE)
lw_u <- nb2listw(nb_u, style = "W", zero.policy = TRUE)

# Local Moran's I
x    <- croydon_lisa$Unemployed
lm_u <- localmoran(x, lw_u, zero.policy = TRUE)

# Check column names
colnames(lm_u)

# Extract LISA statistics
croydon_lisa <- croydon_lisa %>%
  mutate(
    lisa_I  = lm_u[, "Ii"],
    lisa_p  = lm_u[, "Pr(z != E(Ii))"],
    x_z     = as.numeric(scale(x)),
    lag_x_z = as.numeric(lag.listw(lw_u, x_z, zero.policy = TRUE))
  )

# Classify LISA clusters (significance threshold p < 0.05)
alpha <- 0.05
croydon_lisa <- croydon_lisa %>%
  mutate(
    lisa_cluster = case_when(
      lisa_p > alpha             ~ "Not significant",
      x_z >= 0 & lag_x_z >= 0  ~ "High-High",
      x_z <= 0 & lag_x_z <= 0  ~ "Low-Low",
      x_z >= 0 & lag_x_z <= 0  ~ "High-Low",
      x_z <= 0 & lag_x_z >= 0  ~ "Low-High",
      TRUE                       ~ "Not significant"
    ),
    lisa_cluster = factor(
      lisa_cluster,
      levels = c("High-High", "Low-Low", "High-Low", "Low-High", "Not significant")
    )
  )

# Fig 3: LISA cluster map
ggplot(croydon_lisa) +
  geom_sf(aes(fill = lisa_cluster), colour = "white", linewidth = 0.15) +
  scale_fill_manual(
    values = c(
      "High-High"       = "#b2182b",
      "Low-Low"         = "#2166ac",
      "High-Low"        = "#ef8a62",
      "Low-High"        = "#67a9cf",
      "Not significant" = "grey92"
    ),
    name = "LISA cluster type\n(p < 0.05)"
  ) +
  annotation_scale(location = "bl", width_hint = 0.35) +
  annotation_north_arrow(location = "tl",
                          style = north_arrow_fancy_orienteering) +
  labs(
    title    = "Spatial clustering of unemployment (LISA) — Croydon",
    subtitle = "High–High / Low–Low clusters and spatial outliers",
    caption  = "Source: Census OA unemployment aggregated to LSOA; Local Moran's I"
  ) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.major = element_line(colour = "grey90", linewidth = 0.2))


# ── 9. Geographically Weighted Regression (GWR) ──────────────────────────────

library(spgwr)

# Ensure projected CRS
croydon_gwr <- st_transform(croydon_lsoa_data, 27700)

# Extract LSOA centroids as coordinates
coords <- st_coordinates(st_centroid(croydon_gwr))

# Adaptive bandwidth selection
bw <- gwr.sel(
  Unemployed ~ IMD_rank,
  data   = as(croydon_gwr, "Spatial"),
  coords = coords,
  adapt  = TRUE
)
bw

# Run GWR model
gwr_model <- gwr(
  Unemployed ~ IMD_rank,
  data      = as(croydon_gwr, "Spatial"),
  coords    = coords,
  adapt     = bw,
  hatmatrix = TRUE,
  se.fit    = TRUE
)

# Attach GWR outputs back to sf object
croydon_gwr$IMD_coef <- gwr_model$SDF$IMD_rank
croydon_gwr$local_R2 <- gwr_model$SDF$localR2

summary(croydon_gwr$IMD_coef)
summary(croydon_gwr$local_R2)

# Fig 5: GWR local IMD coefficients
ggplot(croydon_gwr) +
  geom_sf(aes(fill = IMD_coef)) +
  scale_fill_viridis_c(option = "plasma", name = "Local IMD coefficient") +
  labs(
    title    = "Spatial variation in IMD–unemployment relationship",
    subtitle = "GWR local coefficients"
  ) +
  theme_minimal()

# Fig 6: GWR local R²
ggplot(croydon_gwr) +
  geom_sf(aes(fill = local_R2)) +
  scale_fill_viridis_c(option = "viridis", name = "Local R²") +
  labs(
    title    = "Local explanatory power of IMD",
    subtitle = "GWR local R²"
  ) +
  theme_minimal()


# ── 10. Save Output Objects ───────────────────────────────────────────────────

saveRDS(croydon_gwr, "croydon_gwr.rds")

# =============================================================================
# End of script
# =============================================================================
