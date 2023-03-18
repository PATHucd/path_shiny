tagUI <- function(id, label = 'Tag History UI') {
  ns <- NS(id)

  tagList(
    textInput(ns("tag_code"), "Tag Code", placeholder = "A69-1303-4324"),
    selectInput(ns("year"), "Year", choices = seq(year_range$min, year_range$max),
                selected = 2017L),
    leafletOutput(ns("map"), height = "500px")
  )
}

# Not sure if we'll need the data_query here - assume we'll need parent because
# for leafletProxy
tagServer <- function(id, data_query, parent) {
  moduleServer(
    id,
    function(input, output, session) {

      tag_history <- reactive({

        if (is.null(input$tag_code)) return(NULL)

        # will not work on some years - fix!
        dbtable <- tbl(con, in_schema("ucdhist", paste0("otn_detections_", input$year)))
        df <- dbtable |>
          filter(fieldnumber == !!input$tag_code) |>
          collect()

      })

      output$map <- renderLeaflet({

        leaflet() |>
          addProviderTiles("Esri.WorldGrayCanvas", group = "Gray") |>
          addProviderTiles("OpenStreetMap.Mapnik", group = "Mapnik") |>
          addProviderTiles("USGS.USTopo", group = "USTopo") |>
          addProviderTiles("USGS.USImageryTopo", group = "USImageTopo") |>
          addProviderTiles("Esri.NatGeoWorldMap", group = "NatGeo") |>
          setView(-120, 39, zoom = 7) |>
          addLayersControl(baseGroups = c("Mapnik", "USTopo",
                                          "USImageTopo", "NatGeo", "Gray"))

      })

      # Color palette for the map
      pal <- colorNumeric(
        palette = "viridis",
        domain = NULL
      )

      # Update the map when something changes
      observe({

        # Only update if this is the currently active tab - otherwise leafletProxy
        # will not work
        if (parent$input$tabs != "Tag History") {
          return(NULL)
        }

        d <- tag_history()
        if (is.null(d)) {
          return(NULL)
        }

        # Clear out the previous data
        lp <- leafletProxy("map", session = session, data = d) |>
          clearMarkers() |>
          clearControls() |>
          clearMarkerClusters()

        # Add the new data
        # Add legend not working with difftime data for some reason
        if (nrow(d) > 0) {
          lp <- lp |>
            addCircleMarkers(radius = 2, lng = ~longitude, lat = ~latitude,
                             color = ~pal(datecollected),
                             label = ~datecollected) #|>
            #addLegend(position = "bottomleft", pal = pal, values = ~datecollected)
        }
        lp

      })

    }
  )
}
