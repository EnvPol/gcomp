# ==============================================================================
# modules/explorer/mod_real_time.R (Real-time data distribution)
#
# Donut / hbar / vbar of `real_time_data` across the filtered projects.
# Toggle and rendering logic come from _viz_helpers.R.
# ==============================================================================

real_time_ui <- function(id) {
  ns <- NS(id)

  card(
    full_screen = TRUE,
    card_header(
      class = "d-flex justify-content-between align-items-center",
      tags$span("Real-time data"),
      chart_type_toggle_ui(ns, default = "donut")
    ),
    card_body(
      plotly::plotlyOutput(ns("plot"), height = 340)
    )
  )
}


real_time_server <- function(id, data) {
  moduleServer(id, function(input, output, session) {

    counts <- reactive({
      count_categorical(data(), "real_time_data")
    })

    chart_type <- chart_type_reactive(input, counts = counts)

    output$plot <- plotly::renderPlotly({
      render_categorical_viz(
        d          = counts(),
        label_col  = "real_time_data",
        chart_type = chart_type(),
        empty_msg  = "No real-time data information in the current selection"
      )
    })

  })
}
