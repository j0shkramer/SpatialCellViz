library(shiny)
library(shinymanager)
library(sf)
library(terra)
library(tidyverse)
library(data.table)
library(tmap)
library(plotly)
library(leaflet)
library(Polychrome)
library(pals)
library(paletteer)
library(tools)

# UI --------------
ui = fluidPage(
    tags$head(
    # Note the wrapping of the string in HTML()
    # below tags$sytle enable some modifying of the shiny styling
    # below I updated the font
    tags$style(HTML("
        @import url('https://fonts.googleapis.com/css2?family=Montserrat:ital,wght@0,100..900;1,100..900&family=Oswald:wght@200..700&family=Rammetto+One&display=swap');        
        body {
        background-color: white;
        color: #0c7c53ff;
        padding-bottom: 60px !important; /* Must be larger than the footer height (40px) */
        }
        
        h2 {
        font-family: 'Rammetto One', sans-serif;
        font-weight: 700;
        }
        h3 {
        font-family: 'Montserrat', sans-serif;
        font-weight: 300;
        }        
        h5 {
        color: #000000ff;
        }
        h6 {
        color: rgb(163, 163, 163);
        position: fixed;
        left: 0;
        bottom: 0;
        width: 100%;
        height: 30px;
        background-color: #f8f9fa; /* Light grey background */
        text-align: center;        /* Centers your text */
        line-height: 10px;
        padding: 10px 0;           /* Adds spacing around text */
        margin: 0;                 /* Removes default browser margins */
        border-top: 1px solid #e7e7e7; /* Optional: adds a top border divider */
        z-index: 999;              /* Ensures it stays on top of scrollable content */
        }
        .shiny-input-container {
        color: #474747;
        }"))
    ),
  
  ## Application title ----
  titlePanel("SpatialCellViz"),

  h3("Interactive spatial single-cell visualization"),

  h5("Josh Kramer - Last Updated: July 2026"),

  sidebarLayout(
        sidebarPanel(
           ## input file -----
          fileInput("files", "Upload single cell .csv file and corresponding .tiff file",
                    multiple = TRUE, accept = c(".csv", ".tiff")),
          uiOutput("plotBy"),
          uiOutput("selectXAxis"),
          uiOutput("selectYAxis"),
          uiOutput("subsetPhenotype"),
          plotOutput("ggplot")
        ),
    mainPanel(
      tmapOutput("tmap_plot", width = "1000px", height = "800px")
    )
  )
)

server <- function(input, output, session) {

  # Set TMAP mode to view
  tmap_mode("view")

  # Reactive expression that splits uploads into csv vs tiff
  uploaded <- reactive({
    req(input$files)

    ext <- tolower(file_ext(input$files$name))

    csv_row  <- input$files[ext == "csv", ]
    tiff_row <- input$files[ext %in% c("tif", "tiff"), ]

    list(
      csv_path  = if (nrow(csv_row)  > 0) csv_row$datapath[1]  else NULL,
      csv_name  = if (nrow(csv_row)  > 0) csv_row$name[1]      else NULL,
      tiff_path = if (nrow(tiff_row) > 0) tiff_row$datapath[1] else NULL,
      tiff_name = if (nrow(tiff_row) > 0) tiff_row$name[1]     else NULL
    )
  })

  # Extract CSV file
  csv_data <- reactive({
    req(uploaded()$csv_path)
    df <- fread(uploaded()$csv_path)
  })

  # Extract Tiff file, transform into sf object
  sf_data <- reactive({
    req(uploaded()$tiff_path)
    # Convert the raster into vector polygons, merging all neighboring pixels that share the same label value into a single polygon
    spatial_raster <- rast(uploaded()$tiff_path)
    cell_mask_vect <- as.polygons(spatial_raster, dissolve = TRUE)  
     # Convert the terra SpatVector into an sf object, since the rest of the
    cell_mask_sf   <- st_as_sf(cell_mask_vect) 
    col_list <- colnames(cell_mask_sf)
    cell_mask_sf <- cell_mask_sf |>
              rename(cell_label = !!col_list[1]) 
    # |>
    #           filter(cell_label != 0)
  })

  # Reactive that combines CSV and SF object for plotting
  combined_data <- reactive({
    req(sf_data(), csv_data())
    full_join(sf_data(), csv_data(), by = "cell_label")
  })

  output$plotBy <- renderUI({
    req(sf_data())
    selectInput("plot_by",
                "Plot Cell Mask By",
                choices = setdiff(
                  colnames(combined_data()),
                  c("cell_label", "cell_ID", "centroid_X_um", "centroid_Y_um",
                    "roi_id", "sample_group1", "sample_group2", "cell_area",
                    "centroid_Y_px", "centroid_X_px", "slide_type", "mibi_instr",
                    "roi_name", "roi_filename", "slide_roi_name", "UMAP1", "UMAP2", "geometry")
                ),
                selected = "phenotype")
  })

  output$selectXAxis <- renderUI({
    req(csv_data())
    selectInput("x_axis",
                "Select X Axis",
                choices = setdiff(
                  colnames(csv_data()),
                  c("cell_label", "cell_ID", "centroid_X_um", "centroid_Y_um",
                    "roi_id", "sample_group1", "sample_group2", "cell_area",
                    "centroid_Y_px", "centroid_X_px", "slide_type", "mibi_instr",
                    "roi_name", "roi_filename", "slide_roi_name", "UMAP1", "UMAP2", 
                    "geometry", "phenotype", "neigh_kmeans")
                )
      )
  })

  output$selectYAxis <- renderUI({
    req(csv_data())
    selectInput("y_axis",
                "Select Y Axis",
                choices = setdiff(
                  colnames(csv_data()),
                  c("cell_label", "cell_ID", "centroid_X_um", "centroid_Y_um",
                    "roi_id", "sample_group1", "sample_group2", "cell_area",
                    "centroid_Y_px", "centroid_X_px", "slide_type", "mibi_instr",
                    "roi_name", "roi_filename", "slide_roi_name", "UMAP1", "UMAP2", 
                    "geometry", "phenotype", "neigh_kmeans")
                )
      )
  })

  output$subsetPhenotype <- renderUI({
    req(csv_data())
    selectInput("subset_phenotype",
                "Subset Plot by Phenotype",
                choices = c("All", 
                            unique(csv_data()$phenotype))
      )
  })

  # Output ggplot
  output$ggplot <- renderPlot({
    req(csv_data(), input$x_axis, input$y_axis, input$subset_phenotype)

    if (input$subset_phenotype != "All") {
      csv_to_plot_data = csv_data() |> filter(phenotype == input$subset_phenotype)
      curr_title = paste("Biaxial Plot of", gsub("_", " ", input$subset_phenotype))
    } else {
      csv_to_plot_data = csv_data()
      curr_title = "Biaxial Plot of All Phenotypes"
    }

    ggplot(csv_to_plot_data, aes(x = .data[[input$x_axis]], y = .data[[input$y_axis]])) +
      geom_point(color = "black", alpha = 0.75) +
      geom_density2d(color = "blue") +
      theme_bw() +
      labs(title = curr_title, x = gsub("_", " ", input$x_axis), y = gsub("_", " ", input$y_axis))
  })

  # Output tmap plot
  output$tmap_plot <- renderTmap({
    req(combined_data(), input$plot_by)
    
    curr_plotting <- input$plot_by
    plot_data <- combined_data()
    
    # extract first value of selected column to evaluate data type
    # if it numeric, round it to the 3rd decimal plcae 
    if (is.numeric(combined_data()[[curr_plotting]][1])) {
        curr_palette = "magma"
        plot_data$hover_val <- round(plot_data[[curr_plotting]], 3)
    } else {
        curr_palette = "brewer.set3"
        plot_data$hover_val <- plot_data[[curr_plotting]]
    } 
      
      
    tm_shape(plot_data) +
      tm_polygons(
        fill = curr_plotting,
        fill.scale = tm_scale(values = curr_palette),
        hover = "hover_val",
        popup.vars = TRUE,
        popup.format = tm_label_format(digits = 3) # round all numeric data to the third decimal place
      ) +
      tm_title(text = paste("Cell Mask Colored By", gsub("_", " ", curr_plotting)),
               position = tm_pos_out())
  })
}

# Run App -------------------------------------------------------
shinyApp(ui, server)