# ==============================================================================
# modules/explorer/mod_decision_support.R (Decision support distribution)
#
# Donut / hbar / vbar of `decision_support_function` across the filtered
# projects. Toggle and rendering logic come from _viz_helpers.R.
# ==============================================================================

decision_support_ui <- function(id) {
  ns <- NS(id)

  card(
    full_screen = TRUE,
    card_header(
      class = "d-flex justify-content-between align-items-center",
      tags$span("Decision support"),
      chart_type_toggle_ui(ns, default = "donut")
    ),
    card_body(
      plotly::plotlyOutput(ns("plot"), height = 340)
    )
  )
}


decision_support_server <- function(id, data) {
  moduleServer(id, function(input, output, session) {

    counts <- reactive({
      count_categorical(data(), "decision_support_function")
    })

    chart_type <- chart_type_reactive(input)

    output$plot <- plotly::renderPlotly({
      render_categorical_viz(
        d          = counts(),
        label_col  = "decision_support_function",
        chart_type = chart_type(),
        empty_msg  = "No decision support data in the current selection"
      )
    })

  })
}
