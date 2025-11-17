# Load packages
library(shiny)
library(bslib)
library(querychat)
library(tidyverse)
library(leaflet)
library(datamods)

#### Setup

### Datasets

## Hospitals
hospitals <-
  read_csv(
    file = "https://data.cms.gov/provider-data/sites/default/files/resources/893c372430d9d71a1c52737d01239d47_1753409109/Hospital_General_Information.csv",
    guess_max = 10000
  )

## Mortality rates
mortality <-
  read_csv(
    file = "https://data.cms.gov/provider-data/sites/default/files/resources/6af7c44d77436e5a1caac3ce39a83fe9_1752732311/Complications_and_Deaths-Hospital.csv",
    guess_max = 10000,
    na = c("", "Not Available", "Not Applicable", "NA", "N/A")
  )

## Zip codes (OH)
options(tigris_use_cache = TRUE)

# Extract zip codes for OH
zips_oh <- tigris::zctas(year = 2010, state = "OH")

# Make zip code centroids
zips_oh_centroids <-
  zips_oh |>

  # Get the centroid
  sf::st_centroid() |>

  # Pluck the coordinates
  sf::st_coordinates() |>

  # Make a tibble
  as_tibble() |>

  # Add identifying column
  add_column(
    Zip = zips_oh$ZCTA5CE10
  ) |>

  # Rename columns
  rename(
    lon = X,
    lat = Y
  )

# Master data set
master_dat <-
  hospitals |>

  # Filter to OH hospitals
  filter(State == "OH") |>

  # Keep a few pieces of information
  select(
    FacilityID = `Facility ID`,
    FacilityName = `Facility Name`,
    Address,
    City = `City/Town`,
    County = `County/Parish`,
    Zip = `ZIP Code`
  ) |>

  # Join to get the centroid for the hospital's zip code
  inner_join(
    y = zips_oh_centroids,
    by = "Zip"
  ) |>

  # Join to get measures
  inner_join(
    y = mortality |>

      # Filter to mortality measures
      filter(str_detect(`Measure ID`, "^MORT_")) |>

      # Keep a few columns
      transmute(
        FacilityID = `Facility ID`,
        Cohort = str_remove(`Measure ID`, "^MORT_30_"),
        Denominator,
        Score,
        Lower = `Lower Estimate`,
        Upper = `Higher Estimate`
      ) |>

      # Remove missing rows
      na.omit(),
    by = "FacilityID"
  ) |>

  # Add random jitter to coordinates
  mutate(
    across(
      c(lat, lon),
      \(x) jitter(x, amount = 0.05)
    )
  )

### Build base map

# OH state outlines
state_outline <-
  maps::map(
    database = "state",
    regions = "ohio",
    fill = TRUE,
    plot = FALSE
  )

# County outlines
county_outlines <-
  tigris::counties(cb = TRUE) %>%
  filter(
    STATE_NAME == "Ohio"
  )

# Base map
base_map <-
  leaflet() %>%

  # Add geographic tiles
  addTiles() %>%

  # Add WI state outline
  addPolygons(
    data = state_outline,
    fillColor = "gray",
    stroke = FALSE
  ) |>

  # Add county outlines
  addPolygons(
    data = county_outlines,
    color = "black",
    fillColor = "white",
    weight = 1,
    opacity = .5,
    fillOpacity = .35,
    highlightOptions = highlightOptions(
      color = "black",
      weight = 3,
      bringToFront = FALSE
    ),
    label = ~NAME
  )

# Configure the chat object
querychat_config <-
  querychat_init(
    data_source = querychat_data_source(
      master_dat,
      tbl_name = "HospitalMortality"
    ),
    create_chat_func = purrr::partial(ellmer::chat_gemini), # <- Assumes GOOGLE_API_KEY is set in ENV variables (usethis::edit_r_environ())
    greeting = "Ask me a question about hospital mortality in Ohio",
    data_description = readLines("02shiny-ai/data_description.md")
  )

#### User Interface
ui <-
  page_sidebar(
    theme = bs_theme(bootswatch = "darkly"),
    title = "30-Day Hospital Mortality in OH",
    window_title = "HRRP Program Results",

    # Sidebar holds configuration
    sidebar = sidebar(
      open = TRUE,
      width = 350,

      h2("Controls", style = "text-align:center"),

      # Toggle between manual and chat mode
      input_switch(
        id = "chat_mode",
        label = "Chat Mode"
      ),

      # Chat input
      conditionalPanel(
        condition = "input.chat_mode",

        # The chat user interface
        querychat_ui(id = "chat")
      ),

      # Manual filtering
      conditionalPanel(
        condition = "!input.chat_mode",

        # Simultaneously filtering on hospital columns
        select_group_ui(
          id = "hospitals",
          params = list(
            list(inputId = "FacilityName", label = "Hospital"),
            list(inputId = "City", label = "City"),
            list(inputId = "County", label = "County"),
            list(inputId = "Zip", label = "Zip")
          ),
          inline = FALSE
        ),

        # Diagnosis category
        selectInput(
          inputId = "diagnosis",
          label = "Diagnosis",
          choices = sort(unique(master_dat$Cohort))
        ),

        # Denominator size
        sliderInput(
          inputId = "denominator",
          label = "Denominator",
          min = 0,
          max = 1000,
          value = c(0, 1000),
          step = 50
        ),

        # Mortality rate
        sliderInput(
          inputId = "mortality_rate",
          label = "30-Day Mortality Rate (%)",
          min = 0,
          max = 25,
          value = c(0, 25),
          step = 1
        )
      )
    ),

    leafletOutput(outputId = "hospital_map")
  )

#### Server
server <-
  function(input, output, session) {
    # Filter to the current hospitals (based on group of location filters)
    current_hospitals_temp <-
      # Filters the dataset at once
      select_group_server(
        id = "hospitals",
        data = reactive(master_dat),
        vars = reactive(c("FacilityName", "City", "County", "Zip"))
      )

    # Make the chat server
    querychat <- querychat_server("chat", querychat_config)

    # Filter to current hospitals (with metric criteria)
    current_hospitals <-
      reactive({
        # Use dataset based on app mode
        if (input$chat_mode) {
          # Get the dataset being returned by the chat
          temp_hospitals <- querychat$df()
        } else {
          # Use the dataset filtered manually
          temp_hospitals <-
            current_hospitals_temp() |>

            # Filter to the specified metric ranges
            filter(
              Cohort == input$diagnosis,
              Denominator >= min(input$denominator),
              Denominator <= max(input$denominator),
              Score >= min(input$mortality_rate),
              Score <= max(input$mortality_rate)
            )
        }

        temp_hospitals
      })

    # Display the map contents
    output$hospital_map <- renderLeaflet({
      base_map
    })

    observe({
      # Set the pallette
      pal <-
        colorNumeric(
          palette = "RdYlGn",
          domain = -1 * sort(unique(current_hospitals()$Score))
        )

      leafletProxy("hospital_map") |>
        clearMarkers() |>

        setView(
          lng = mean(unique(current_hospitals()$lon)),
          lat = mean(unique(current_hospitals()$lat)),
          zoom = 8
        ) |>

        # Add points to map
        addCircleMarkers(
          data = current_hospitals(),
          lng = ~lon,
          lat = ~lat,
          label = ~ paste0(FacilityName, " (click for info)"),
          popup = ~ paste0(
            "Hospital: ",
            FacilityName,
            "<br>Address: ",
            Address,
            "<br>City: ",
            City,
            "<br>County: ",
            County,
            "<br>Zip Code: ",
            Zip,
            "<br>Diagnosis Group: ",
            Cohort,
            "<br>Denominator: ",
            Denominator,
            "<br>Mortality Rate (%): ",
            Score,
            "%",
            "<br>95% CI: (",
            Lower,
            "%, ",
            Upper,
            "%)"
          ),
          color = ~ pal(-1 * Score),
          radius = ~ scale(Score)[, 1] + 8,
          fillOpacity = 1
        )
    })
  }

# Run the app
shinyApp(ui, server)
