# ==============================================================================
# modules/explorer/mod_open_access.R (Open access distribution)
#
# Donut / hbar / vbar of `open_access` across the filtered projects.
# Toggle and rendering logic come from _viz_helpers.R.
# ==============================================================================

open_access_ui <- function(id) {
  ns <- NS(id)

  card(
    full_screen = TRUE,
    card_header(
      class = "d-flex justify-content-between align-items-center",
      tags$span("Open access"),
      chart_type_toggle_ui(ns, default = "donut")
    ),
    card_body(
      plotly::plotlyOutput(ns("plot"), height = 340)
    )
  )
}


open_access_server <- function(id, data) {
  moduleServer(id, function(input, output, session) {

    counts <- reactive({
      count_categorical(data(), "open_access")
    })

    chart_type <- chart_type_reactive(input)

    output$plot <- plotly::renderPlotly({
      render_categorical_viz(
        d          = counts(),
        label_col  = "open_access",
        chart_type = chart_type(),
        empty_msg  = "No open access data in the current selection"
      )
    })

  })
}
