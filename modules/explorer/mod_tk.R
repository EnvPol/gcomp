# ==============================================================================
# modules/explorer/mod_tk.R (TK from IPLCs distribution)
#
# Donut / hbar / vbar of `tk_from_iplcs` across the filtered projects.
# Toggle and rendering logic come from _viz_helpers.R.
# ==============================================================================

tk_ui <- function(id) {
  ns <- NS(id)

  card(
    full_screen = TRUE,
    card_header(
      class = "d-flex justify-content-between align-items-center",
      tags$span("TK from IPLCs"),
      chart_type_toggle_ui(ns, default = "donut")
    ),
    card_body(
      plotly::plotlyOutput(ns("plot"), height = 340)
    )
  )
}


tk_server <- function(id, data) {
  moduleServer(id, function(input, output, session) {

    counts <- reactive({
      count_categorical(data(), "tk_from_iplcs")
    })

    chart_type <- chart_type_reactive(input)

    output$plot <- plotly::renderPlotly({
      render_categorical_viz(
        d          = counts(),
        label_col  = "tk_from_iplcs",
        chart_type = chart_type(),
        empty_msg  = "No TK / IPLCs data in the current selection"
      )
    })

  })
}
