# Spatial Analysis of Unemployment in Croydon, London

**Neighbourhood-level spatial analysis of unemployment and deprivation across Croydon using R**

This project analyses spatial inequalities in unemployment across Croydon at Lower Super Output Area (LSOA) level, combining 2021 Census data with the Index of Multiple Deprivation (IMD 2025). The analysis moves beyond borough-wide averages to identify where unemployment clusters, how it relates to deprivation, and where that relationship is strongest — with direct implications for spatially targeted employment policy.

---
##  Full Report

**[→ View full report with maps and analysis](./Report%20Spatial%20Analysis%20of%20unemployment%20in%20Croydon%2CLondon.pdf)**

Includes executive summary, choropleth maps, LISA cluster analysis, GWR outputs, and full technical appendix.

---

## Key Findings

- Unemployment in Croydon is **not randomly distributed** — statistically significant spatial clustering is confirmed at LSOA level
- **High-High unemployment clusters** are concentrated in northern Croydon; **Low-Low clusters** dominate the south — a pronounced north-south divide
- Deprivation (IMD) is **closely associated with unemployment** but the relationship is **spatially heterogeneous**: deprivation is a much stronger predictor of unemployment in eastern and southern LSOAs, with weaker explanatory power elsewhere
- These findings suggest that **uniform borough-wide employment interventions risk overlooking** the neighbourhoods where deprivation most constrains labour market participation — spatially targeted policies are likely to be more effective

---

## Maps & Visualisations

The analysis produces six publication-quality outputs:

| Figure | Description |
|---|---|
| Fig 1 | Distribution of unemployment rates across Croydon LSOAs (histogram) |
| Fig 2 | Unemployment rate (%) by LSOA — choropleth map |
| Fig 3 | LISA cluster map — High-High / Low-Low clusters and spatial outliers |
| Fig 4 | Index of Multiple Deprivation (IMD 2025) deciles by LSOA |
| Fig 5 | GWR local coefficients — spatial variation in IMD-unemployment relationship |
| Fig 6 | GWR local R² — explanatory power of IMD across space |

---

## Data Sources

| Dataset | Source | Year |
|---|---|---|
| Unemployment rates (OA level) | ONS Census 2021 | 2021 |
| LSOA boundary polygons | ONS Open Geography Portal | 2021 |
| Index of Multiple Deprivation | Ministry of Housing, Communities & Local Government | 2025 |

> **Note:** Raw boundary and Census files are not included due to file size. See the technical appendix in the report for full dataset descriptions and download links.

---

## Methods

### Data Processing
- Unemployment data sourced at Output Area (OA) level and aggregated to LSOA using **population-weighted means**
- IMD 2025 data joined to LSOA boundary polygons by LSOA code
- All spatial operations in **British National Grid (EPSG:27700)**
- Choropleth maps classified using **Jenks natural breaks** to handle right-skewed unemployment distribution

### Spatial Autocorrelation
- **Global Moran's I** computed to test for spatial clustering under the null hypothesis of spatial randomness — confirmed statistically significant positive autocorrelation
- **Local Indicators of Spatial Association (LISA)** computed using Local Moran's I to identify statistically significant High-High and Low-Low clusters (p < 0.05)
- **Distance-based spatial weights matrix** (2.5 km band) adopted after contiguity-based matrices produced unstable results due to irregular LSOA geometries at borough periphery

### Geographically Weighted Regression (GWR)
- GWR applied with **IMD rank** as explanatory variable to examine spatial heterogeneity in the deprivation-unemployment relationship
- **Adaptive bandwidth** selected to account for uneven spatial density across Croydon
- Local R² values extracted and mapped to assess where IMD explains unemployment variation most effectively

---

## Repository Structure

```
croydon-unemployment-spatial/
│
├── analysis.R          # Full R script — data processing, mapping, LISA, GWR
├── report.pdf          # Full project report with maps, findings, and technical appendix
├── README.md
└── LICENSE
```

---

## How to Reproduce

### Requirements
R (≥ 4.1.0) with the following packages:

```r
library(sf)
library(dplyr)
library(stringr)
library(ggplot2)
library(ggplot2)
library(classInt)
library(ggspatial)
library(readxl)
library(spdep)
library(spgwr)
```

### Data required (download separately)
- ONS LSOA 2021 boundaries: `Lower_layer_Super_Output_Areas_2021_EW_BGC_V3.geojson`
- ONS Census 2021 OA unemployment: `OA_2021_EW_BGC_V2.shp`
- IMD 2025: `File_1_IoD2025_Index_of_Multiple_Deprivation.xlsx`

### Run
1. Clone this repository
2. Place the required data files in your working directory
3. Open and run `analysis.R` in RStudio

---

## Tools & Packages

| Package | Purpose |
|---|---|
| `sf` | Spatial data handling, geometric operations, CRS transformations |
| `dplyr` | Data wrangling and joins |
| `ggplot2` + `ggspatial` | Choropleth maps with north arrows and scale bars |
| `classInt` | Jenks natural breaks classification |
| `spdep` | Spatial weights matrices, Global Moran's I, LISA |
| `spgwr` | Geographically Weighted Regression (GWR) |
| `readxl` | Reading IMD Excel files |

---

## References

- Anselin, L. (1995) Local indicators of spatial association — LISA. *Geographical Analysis*, 27(2), pp. 93–115.
- Brunsdon, C., Fotheringham, A.S. and Charlton, M. (1996) Geographically weighted regression. *Geographical Analysis*, 28(4), pp. 281–298.
- Fotheringham, A.S., Brunsdon, C. and Charlton, M. (2002) *Geographically Weighted Regression*. Chichester: Wiley.
- McLennan, D. et al. (2019) *The English Indices of Deprivation 2019: Technical Report*. MHCLG.
- OECD (2019) *Local Economic and Employment Development: Making Decentralisation Work*. Paris: OECD Publishing.

---

## Author

**Samiira Osman Yusuf**
BSc Social Data Science, University College London
[linkedin.com/in/samiira-yusuf-36192b35a](https://linkedin.com/in/samiira-yusuf-36192b35a) | [github.com/Samiira-OY](https://github.com/Samiira-OY)
