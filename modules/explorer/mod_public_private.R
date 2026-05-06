# ==============================================================================
# modules/explorer/mod_public_private.R (Public / Private distribution)
#
# Donut / hbar / vbar of `public_private` across the filtered projects.
# Toggle and rendering logic come from _viz_helpers.R.
# ==============================================================================

public_private_ui <- function(id) {
  ns <- NS(id)

  card(
    full_screen = TRUE,
    card_header(
      class = "d-flex justify-content-between align-items-center",
      tags$span("Public / Private"),
      chart_type_toggle_ui(ns, default = "donut")
    ),
    card_body(
      plotly::plotlyOutput(ns("plot"), height = 340)
    )
  )
}


public_private_server <- function(id, data) {
  moduleServer(id, function(input, output, session) {

    counts <- reactive({
      count_categorical(data(), "public_private")
    })

    chart_type <- chart_type_reactive(input)

    output$plot <- plotly::renderPlotly({
      render_categorical_viz(
        d          = counts(),
        label_col  = "public_private",
        chart_type = chart_type(),
        empty_msg  = "No public/private data in the current selection"
      )
    })

  })
}
