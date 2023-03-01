fluidPage(
  theme = bs_theme(bootswatch = "solar"),
  titlePanel("Pacific Aquatic Telemetry Hub (PATH) Database Tool"),

  sidebarLayout(
    sidebarPanel(width = 3,
      sliderInput("year", "Years", min = year_range$min, max = year_range$max,
                  value = c(2017, year_range$max),
                  step = 1, dragRange = TRUE, sep = ""),
      selectInput("project", "Projects", choices = projects_available,
                  selected = "UCDHIST", multiple = TRUE),
      selectInput("locations", "Detection Locations",
                  choices = locations_available, multiple = TRUE),
      selectInput("species", "Species", choices = species_available,
                  multiple = TRUE),
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
          tags$style('#dt td {padding: 0 1em}'),
          downloadButton("download"),
          br(), br(),
          DT::dataTableOutput("dt", height = "600px")
          )
        )
      )
    )
)
