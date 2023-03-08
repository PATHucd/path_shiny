
library(shiny)
library(DBI)
library(dbplyr)
library(pool)
library(tidyverse)
library(config)
library(bslib)
library(leaflet)
library(V8)
library(DT)
library(plotly)

# Database connection
args <- config::get("dataconnection")
con <- pool::dbPool(odbc::odbc(),
                 driver = args$driver,
                 database = args$database,
                 uid = args$uid,
                 pwd = args$pwd,
                 server = args$server,
                 port = args$port
)

# Table hooks
all_animals <- tbl(con, in_schema("discovery", "all_animals"))
pre_summary <- tbl(con, in_schema("discovery", "detection_pre_summary"))
stations <- tbl(con, in_schema("discovery", "stations_header"))
species_tbl <- tbl(con, in_schema("discovery", "species_list")) |>
  select(scientificname, commonname) |>
  filter(scientificname %in% species_available) |>
  distinct()

# Available options for the UI
year_range <- pre_summary |>
  summarise(min = lubridate::year(min(min_detectdate, na.rm = TRUE)),
            max = lubridate::year(max(max_detectdate, na.rm = TRUE))) |>
  collect()

projects_available <- tbl(con, in_schema("discovery", "mstr_resources")) |>
  pull(collectioncode) |>
  sort()

locations_available <- pre_summary |>
  select(station) |>
  distinct() |>
  pull(station) |>
  sort()

species_available <- all_animals |>
  select(scientificname) |>
  distinct() |>
  pull(scientificname) |>
  sort()

species <- tbl(con, in_schema("discovery", "species_list")) |>
  select(scientificname, commonname) |>
  filter(scientificname %in% species_available) |>
  distinct() |>
  collect()

common_names <- species_tbl |>
  pull(commonname)

# Update leaflet providers to get some of the newer maps
leaflet.providers::use_providers(leaflet.providers::get_providers())


# Shutdown chores
onStop(function() {
  poolClose(con)
})
