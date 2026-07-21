# SpatialCellViz

**An R Shiny app for visualization of spatial single-cell data with cell masks**

SpatialCellViz makes it easy to explore spatial single-cell data across an ROI (region of interest)

![example](images/example.png)

## Features
- Visualize spatial single-cell data for a single ROI
- Visualize cell masks
- Overlay cell phenotype, biomarker expression, or cellular neighborhoods on spatial plots
- Explore biaxial plots of biomarkers and subset by phenotype

## Inputs

SpatialCellViz accepts a CSV file containing single-cell data and its corresponding `.tiff` file (upload limit: **1 G**)

### Required Columns

| Column          | Required? | Description                                                            |
|-----------------|-----------|------------------------------------------------------------------------|
| `phenotype`     | Yes       | Cell Phenotype                                                         |
| `cell_label`    | Yes       | Unique identifier for each cell that matches its corresponding cell in `.tiff` file |

## Running Locally

### Requirements
- R version ≥ 4.5.3
- R packages:
    - `shiny`
    - `shinymanager`
    - `sf`
    - `terra`
    - `tidyverse`
    - `data.table`
    - `tmap`
    - `plotly`
    - `leaflet`
    - `Polychrome`
    - `pals`
    - `tools`

Install the required packages in R:
```
install.packages(c(
    "shiny", "shinymanager", "sf", "terra", "tidyverse", "data.table",
    "tmap", "plotly", "leaflet", "Polychrome", "pals"
))
```

### 1. Clone the repository

```
git clone https://github.com/j0shkramer-op/SpatialCellViz.git
```

### 2. Navigate to repository

```
cd SpatialCellViz
```

### 3. Launch the app

```
shiny::runApp()
```