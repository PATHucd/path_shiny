fluidPage(
  theme = bs_theme(bootswatch = "solar"), # pick a theme at https://bootswatch.com/
  titlePanel("Pacific Aquatic Telemetry Hub (PATH) Database Tool"),

  sidebarLayout(
    sidebarPanel(width = 3,
                 sharedUI("shared")
    ),
    mainPanel(width = 9,
              tabsetPanel(
                id = "tabs",
                tabPanel("Stations", stationsUI("stations")),
                tabPanel("Summary", summaryUI("summary"))
              )
    )

  )
)
