fluidPage(
  theme = bs_theme(bootswatch = "solar"), # pick a theme at https://bootswatch.com/
  titlePanel("Pacific Aquatic Telemetry Hub (PATH) Database Tool"),

  sidebarLayout(
    sidebarPanel(width = 3,
      selectInput("species", "Species", choices = common_names,
                             multiple = TRUE),
      sliderInput("year", "Years", min = year_range$min, max = year_range$max,
                  value = c(2017, year_range$max),
                  step = 1, dragRange = TRUE, sep = ""),
      selectInput("locations", "Detection Locations",
                  choices = locations_available, multiple = TRUE),
      selectInput("project", "Projects", choices = projects_available,
                  selected = "UCDHIST", multiple = TRUE),
      actionButton("tags", "Tag Codes")
    ),

    mainPanel(width = 9,
      tabsetPanel(
        id = "tabs",
        tabPanel(
          title = "Map",
          leafletOutput("map", height = "500px"),
          plotlyOutput("selected")
          ),
        tabPanel(
          title = "Data",
          # Set padding on the datatable cells
          tags$style('#dt td {padding: 0 1em}'),
          downloadButton("download"),
          br(), br(),
          DT::dataTableOutput("dt", height = "600px")
          )
        )
      )
    )
)
