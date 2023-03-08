function(input, output, session) {

  # Dynamic UI ----

  observeEvent(input$tags, {

    if (is.null(tag_code_list())) {
      input_text <- ""
    } else {
      input_text <- paste(tag_code_list(), collapse = "\n")
    }

    showModal(modalDialog(
      title = "Specify Tag Codes",
      size = "l",
      textAreaInput("tag_codes", "Enter or copy tag codes here, separated by commas or whitespace",
                    value = input_text,
                    placeholder = "A69-1206-776\nA69-1303-17245",
                    width = "100%",
                    rows = 6),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("tag_ok", "OK")
      )
    ))

  })

  # Data reactives ----

  data_query <- reactive({

    dfq <- pre_summary |>
      left_join(select(all_animals, catalognumber, collectioncode, scientificname),
                by = c("relatedcatalogitem"="catalognumber",
                       "collectioncode"="collectioncode")) |>
      left_join(select(stations, station_name, latitude, longitude, depth),
                by = c("station"="station_name")) |>
      left_join(species_tbl, by = "scientificname")

    dt_from <- as.Date(paste(input$year[1], "01", "01", sep = "-"))
    dt_to <- as.Date(paste(input$year[2], "12", "31", sep = "-"))
    dfq <- dfq |>
      filter(min_detectdate >= dt_from,
             max_detectdate <= dt_to)

    if (!is.null(input$project)) {
      dfq <- dfq |>
        filter(collectioncode %in% !!input$project)
    }

    if (!is.null(input$locations)) {
      dfq <- dfq |>
        filter(station %in% !!input$locations)
    }

    if (!is.null(input$species)) {
      dfq <- dfq |>
        filter(commonname %in% !!input$species)
    }

    if (!is.null(tag_code_list())) {
      if (length(tag_code_list()) > 1) {
        dfq <- dfq |>
          filter(fieldnumber %in% !!tag_code_list())
      } else if (tag_code_list() != "") {
        dfq <- dfq |>
          filter(fieldnumber %in% !!tag_code_list())
      }
    }

    dfq
  })

  station_data <- reactive({

    df <- data_query() |>
      group_by(station, commonname) |>
      summarise(detection_count = sum(detection_count, na.rm = TRUE),
                latitude = max(latitude, na.rm = TRUE),
                longitude = max(longitude, na.rm = TRUE),
                .groups = "drop") |>
      collect()
    df
  })



  tag_code_list <- reactiveVal(NULL)
  observeEvent(input$tag_ok, {

    removeModal()
    # extract the tag codes
    tag_code_list(str_split_1(input$tag_codes, pattern = "\\s+|,\\s*"))

  })

  # Map tab ----

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
    if (input$tabs != "Map") {
      return(NULL)
    }

    d <- station_data()
    if (is.null(d)) {
      return(NULL)
    }

    # Clear out the previous data
    lp <- leafletProxy("map", session = session, data = d) |>
      clearMarkers() |>
      clearControls() |>
      clearMarkerClusters()

    # Add the new data
    if (nrow(d) > 0) {
      lp <- lp |>
        addCircleMarkers(radius = 2, lng = ~longitude, lat = ~latitude,
                         color = ~pal(detection_count),
                         label = ~station,
                         layerId = ~station) |>
        addLegend(position = "bottomleft", pal = pal, values = ~detection_count)
    }
    lp

  })

  # A plot to display when a station on the map is clicked
  output$selected <- renderPlotly({

    click <- input$map_marker_click
    validate(need(!is.null(click), "Select a point"))

    id <- click$id

    df <- data_query() |>
      filter(station == id) |>
      collect() |>
      mutate(detection_count = as.numeric(detection_count),
             commonname = if_else(is.na(commonname), " Not Listed",
                                      commonname))

    g <- ggplot(df, aes(x = min_detectdate, y = commonname,
                   color = detection_count)) +
      geom_point() +
      scale_color_viridis_c() +
      scale_x_datetime(labels = scales::label_date_short()) +
      labs(title = id,
           x = "detection date",
           color = "detection count") +
      theme(axis.title.y = element_blank())

    ggplotly(g)

  })

  # Data tab ----

  output$dt <- DT::renderDataTable({
    df <- data_query() |>
      collect()
    datatable(df, class = "compact stripe hover nowrap",
              rownames = FALSE,
              fillContainer = TRUE,
              options = list(
                pageLength = 30,
                dom = "ftpi"
                )
              )

  })

  output$download <- downloadHandler(
    filename = function() {
      paste0("PATH_extract_", Sys.Date(), ".csv")
    },
    content = function(filename) {
      df <- data_query() |>
        collect()
      write_csv(df, filename)
    }
  )

}
