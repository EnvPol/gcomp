# ==============================================================================
# modules/mod_summary_cards.R — Summary stat cards (projects, institutions, countries)
# Updates reactively when sidebar filters change.
# ==============================================================================


# --- UI -----------------------------------------------------------------------
summary_cards_ui <- function(id) {
  ns <- NS(id)

  layout_columns(
    col_widths = c(4, 4, 4),
    fill = FALSE,

    value_box(
      title = "Number of projects",
      value = textOutput(ns("n_projects")),
      theme = "primary"
    ),

    value_box(
      title = "Involved institutions",
      value = textOutput(ns("n_institutions")),
      theme = "primary"
    ),

    value_box(
      title = "Involved countries",
      value = textOutput(ns("n_countries")),
      theme = "primary"
    )
  )
}


# --- SERVER -------------------------------------------------------------------
summary_cards_server <- function(id, data) {
  moduleServer(id, function(input, output, session) {

    output$n_projects <- renderText({
      nrow(data())
    })

    # Split semicolon-separated institution_ids and count unique values.
    output$n_institutions <- renderText({
      data() |>
        pull(institution_ids) |>
        paste(collapse = ";") |>
        str_split(";") |>
        unlist() |>
        str_trim() |>
        (\(x) x[!is.na(x) & x != ""])() |>
        unique() |>
        length()
    })

    # Split semicolon-separated ISO2 codes and count unique countries.
    output$n_countries <- renderText({
      data() |>
        pull(countries_iso2) |>
        na.omit() |>
        strsplit(";") |>
        unlist() |>
        str_trim() |>
        (\(x) x[x != ""])() |>
        unique() |>
        length()
    })

  })
}
