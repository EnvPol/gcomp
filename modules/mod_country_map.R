# ==============================================================================
# modules/mod_country_map.R — Bubble map of projects per country
#
# Bubble size scales with project count. Used on the Overview tab and can be
# reused with filtered data elsewhere.
#
# country_map_server() returns an eventReactive that fires on bubble clicks,
# yielding $country (country name) and $.nonce (ensures re-clicks still fire).
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

    empty_counts <- tibble::tibble(
      country_iso2 = character(),
      country_name = character(),
      n_projects   = integer()
    )

    # One row per (project, country) deduplicated, then counted by country.
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

    map_points <- reactive({
      project_counts() |>
        inner_join(world_centroids, by = c("country_iso2" = "iso_a2"))
    })

    # Render base map once; bubbles are redrawn via proxy.
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

    observe({
      pts <- map_points()
      sel <- selected_country()
      if (is.null(sel)) sel <- "all"

      # sqrt scaling with floor and cap keeps bubbles visible but not overwhelming.
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

      # sticky labels work around a hover detection issue on some browsers
      lbl_opts <- leaflet::labelOptions(sticky = TRUE, direction = "auto")

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

      # Selected bubble rendered on top, highlighted.
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

    # Returns country name and a nonce on each click; nonce ensures re-clicks fire.
    eventReactive(input$map_marker_click, {
      list(
        country = input$map_marker_click$id,
        .nonce  = stats::runif(1)
      )
    }, ignoreInit = TRUE)
  })
}
