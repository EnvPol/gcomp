# ==============================================================================
# modules/mod_summary_cards.R — Summary statistics cards
#
# Displays four key-number cards at the top of the Dashboard tab.
# These update reactively when sidebar filters are applied.
#
# Current cards: Total projects | Operational | Institutions | Countries
#
# HOW TO MODIFY:
#   - Change a stat: edit the renderText() block for that output in the server section
#   - Add a card:    add a value_box() in the UI and a renderText() in the server
#   - Remove a card: delete the value_box() and its renderText(), adjust col_widths
#   - Change icons:  update icon("...") — use names from fontawesome.com/icons
#   - Change colours: update theme = "..." — options: primary, secondary, success,
#                     info, warning, danger, or a hex colour string
# ==============================================================================


# --- UI -----------------------------------------------------------------------
summary_cards_ui <- function(id) {
  ns <- NS(id)   # ns() namespaces all outputIds so multiple instances don't clash

  layout_columns(
    col_widths = c(4, 4, 4),   # Four equal columns; change to c(4,4,4) for three
    fill = FALSE,

    # Card 1: Total projects matching current filters
    value_box(
      title    = "Number of projects",
      value    = textOutput(ns("n_projects")),
      theme    = "primary"
    ),

    # Card 2: Unique institutions across filtered projects
    value_box(
      title    = "Institutions",
      value    = textOutput(ns("n_institutions")),
      theme    = "primary"
    ),

    # Card 3: Unique countries (via institutions lookup)
    value_box(
      title    = "Countries",
      value    = textOutput(ns("n_countries")),
      theme    = "primary"
    )
  )
}


# --- SERVER -------------------------------------------------------------------
summary_cards_server <- function(id, data) {
  # data: a reactive expression returning the filtered projects data frame

  moduleServer(id, function(input, output, session) {

    # Total number of projects matching current filters
    output$n_projects <- renderText({
      nrow(data())
    })

    # Count of unique institutions across filtered projects.
    # institution_ids stores semicolon-separated numeric IDs; we split and count
    # distinct values — no text matching needed.
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

    # Count unique countries across filtered projects.
    # Countries_ISO2 is pre-computed per project; we split, collect unique ISO2
    # codes, and count them directly — no join to institutions needed.
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
