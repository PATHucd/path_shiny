fluidPage(
  theme = bs_theme(bootswatch = "solar"),
  titlePanel("Pacific Aquatic Telemetry Hub (PATH) Database Tool"),

  sidebarLayout(
    sidebarPanel(width = 3,
      sliderInput("year", "Years", min = year_range$min, max = year_range$max,
                  value = c(year_range$min, year_range$max),
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
          title = "Data",
          verbatimTextOutput("table")
        ),
        tabPanel(
          title = "Map",
          # selectInput("map_count", "Max number of records to fetch (most recent)",
          #             choices = c("1,000"=1000, "10,000"=10000, "50,000"=50000,
          #                         "100,000"=100000),
          #             selected = 10000),
          leafletOutput("map", height = "600px"),
          verbatimTextOutput("selected")
          )
        )
      )
    )
)
