# ==============================================================================
# modules/explorer/mod_scope.R (Scope distribution)
#
# Donut / horizontal bar / vertical bar of `scope` across the filtered
# projects. NA / empty values are dropped. The chart-type toggle and
# rendering logic come from _viz_helpers.R; this file only specifies the
# column to plot.
# ==============================================================================

scope_ui <- function(id) {
  ns <- NS(id)

  card(
    full_screen = TRUE,
    card_header(
      class = "d-flex justify-content-between align-items-center",
      tags$span("Scope"),
      chart_type_toggle_ui(ns, default = "donut")
    ),
    card_body(
      plotly::plotlyOutput(ns("plot"), height = 340)
    )
  )
}


scope_server <- function(id, data) {
  moduleServer(id, function(input, output, session) {

    counts <- reactive({
      count_categorical(data(), "scope")
    })

    chart_type <- chart_type_reactive(input, counts = counts)

    output$plot <- plotly::renderPlotly({
      render_categorical_viz(
        d          = counts(),
        label_col  = "scope",
        chart_type = chart_type(),
        empty_msg  = "No scope data in the current selection"
      )
    })

  })
}
