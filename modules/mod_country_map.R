# ==============================================================================
# modules/mod_country_map.R -- Bubble map of projects per country
#
# Each bubble represents a country; its size is proportional to the number of
# projects that have at least one participating institution from that country.
#
# Used in two places:
#   - Overview tab  (id "overview_map"):  always visible, full catalogue, no filter
#   - (future)      if added back to Data Explorer, would respond to filters
#
# Data flow:
#   projects data frame
#     -> split Countries_ISO2 on ";" (pre-computed per project in source data)
#     -> deduplicate to (project_id, iso2) pairs
#     -> count distinct projects per ISO2 code
#     -> look up display name via countrycode
#     -> join to country centroids from rnaturalearth on iso_a2
#     -> render bubbles sized by sqrt(n_projects)
#
# Arguments to *_server():
#   id               -- module ID matching the UI call
#   data             -- reactive returning the projects data frame to map
#   selected_country -- reactive returning the selected country name string,
#                       or "all" / NA when nothing is selected (used for
#                       highlighting). Pass reactive("all") when there is no
#                       sidebar filter on the host tab.
#
# Returns:
#   An eventReactive that fires whenever a bubble is clicked. The value is a
#   list with $country (the country_name layerId of the clicked bubble) and
#   $.nonce (a per-click random value so observers fire even when the user
#   re-clicks the same bubble). Callers can ignore the return value if they
#   do not need to react to clicks.
# ==============================================================================


# --- UI -----------------------------------------------------------------------
country_map_ui <- function(id) {
  ns <- NS(id)

  card(
    full_screen = TRUE,
    card_header(
      class = "d-flex align-items-baseline",
      tags$span("Projects by country", class = "fw-bold me-2"),
      tags$small("Click a bubble to browse projects", class = "text-muted")
      ),
    card_body(
      padding = 0,
      leaflet::leafletOutput(ns("map"), height = 500)
    )
  )
}


# --- SERVER -------------------------------------------------------------------
country_map_server <- function(id, data, selected_country = reactive("all")) {
  moduleServer(id, function(input, output, session) {

    # ---- Project counts per country ------------------------------------------
    # Countries_ISO2 is pre-computed per project in the source data: no join to
    # institutions needed. We split on ";", trim whitespace, deduplicate to one
    # row per (project, ISO2 code), then count projects per country.
    empty_counts <- tibble::tibble(
      country_iso2 = character(),
      country_name = character(),
      n_projects   = integer()
    )

    project_counts <- reactive({
      df <- data()
      if (is.null(df) || nrow(df) == 0) return(empty_counts)

      df |>
        mutate(project_id = row_number()) |>
        select(project_id, countries_iso2) |>
        filter(!is.na(countries_iso2)) |>
        mutate(iso2 = str_split(countries_iso2, ";")) |>
        tidyr::unnest(iso2) |>
        mutate(iso2 = str_trim(iso2)) |>
        filter(iso2 != "") |>
        # One row per (project, country): deduplicate before counting.
        distinct(project_id, iso2) |>
        count(iso2, name = "n_projects") |>
        mutate(
          country_name = suppressWarnings(
            countrycode::countrycode(iso2, "iso2c", "country.name", warn = FALSE)
          )
        ) |>
        filter(!is.na(country_name)) |>
        rename(country_iso2 = iso2)
    })

    # ---- Join counts to centroids --------------------------------------------
    map_points <- reactive({
      project_counts() |>
        inner_join(world_centroids, by = c("country_iso2" = "iso_a2"))
    })

    # ---- Render base map once ------------------------------------------------
    output$map <- leaflet::renderLeaflet({
      leaflet::leaflet(options = leaflet::leafletOptions(
        minZoom = 1, worldCopyJump = TRUE
      )) |>
        leaflet::addProviderTiles(
          leaflet::providers$CartoDB.PositronNoLabels,
          options = leaflet::providerTileOptions(noWrap = FALSE)
        ) |>
        leaflet::addProviderTiles(
          leaflet::providers$CartoDB.PositronOnlyLabels
        ) |>
        leaflet::setView(lng = 10, lat = 25, zoom = 2)
    })

    # ---- Redraw bubbles whenever data or selected country changes ------------
    observe({
      pts <- map_points()
      sel <- selected_country()
      if (is.null(sel)) sel <- "all"

      # sqrt scaling: keeps large-count countries from dwarfing small ones.
      # Floor at 7px so every country is visible; cap at 45px.
      radius_fun <- function(n) pmin(pmax(sqrt(n) * 6, 7), 45)

      proxy <- leaflet::leafletProxy("map") |>
        leaflet::clearGroup("bubbles") |>
        leaflet::clearGroup("selected")

      if (nrow(pts) == 0) return(invisible())

      pts <- pts |>
        mutate(
          is_selected = sel != "all" & country_name == sel,
          popup_html  = paste0(
            "<div style='font-family:sans-serif;line-height:1.5'>",
            "<b>", htmltools::htmlEscape(country_name), "</b><br/>",
            n_projects, " project", ifelse(n_projects == 1, "", "s"),
            "</div>"
          )
        )

      # Label options: sticky = TRUE forces the tooltip to follow the cursor,
      # working around a Leaflet bug on Chrome/Mac where trackpad touch detection
      # disables hover labels.
      lbl_opts <- leaflet::labelOptions(sticky = TRUE, direction = "auto")

      # Unselected bubbles
      pts_unsel <- pts |> filter(!is_selected)
      if (nrow(pts_unsel) > 0) {
        proxy <- proxy |>
          leaflet::addCircleMarkers(
            data         = pts_unsel,
            lng          = ~lng,
            lat          = ~lat,
            radius       = ~radius_fun(n_projects),
            layerId      = ~country_name,
            group        = "bubbles",
            stroke       = TRUE,
            color        = "#006AB4",
            weight       = 1,
            opacity      = 0.9,
            fillColor    = "#006AB4",
            fillOpacity  = 0.50,
            label        = ~paste0(country_name, ": ", n_projects,
                                   " project", ifelse(n_projects == 1, "", "s")),
            labelOptions = lbl_opts,
            popup        = ~popup_html
          )
      }

      # Selected bubble on top, highlighted in cyan
      pts_sel <- pts |> filter(is_selected)
      if (nrow(pts_sel) > 0) {
        proxy |>
          leaflet::addCircleMarkers(
            data         = pts_sel,
            lng          = ~lng,
            lat          = ~lat,
            radius       = ~radius_fun(n_projects) + 3,
            layerId      = ~country_name,
            group        = "selected",
            stroke       = TRUE,
            color        = "#002F62",
            weight       = 3,
            opacity      = 1,
            fillColor    = "#009EE3",
            fillOpacity  = 0.85,
            label        = ~paste0(country_name, ": ", n_projects,
                                   " project", ifelse(n_projects == 1, "", "s")),
            labelOptions = lbl_opts,
            popup        = ~popup_html
          )
      }
    })

    # ---- Click events --------------------------------------------------------
    # Emit a value every time the user clicks a bubble. The .nonce ensures the
    # parent observer fires even when the same bubble is clicked twice in a
    # row (the country string would otherwise be unchanged and observeEvent
    # would skip the second event).
    eventReactive(input$map_marker_click, {
      list(
        country = input$map_marker_click$id,
        .nonce  = stats::runif(1)
      )
    }, ignoreInit = TRUE)
  })
}
