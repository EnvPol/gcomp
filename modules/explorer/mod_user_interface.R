# ==============================================================================
# modules/explorer/mod_user_interface.R (User interface distribution)
#
# Donut / hbar / vbar of `user_interface` across the filtered projects.
# Toggle and rendering logic come from _viz_helpers.R.
# ==============================================================================

user_interface_ui <- function(id) {
  ns <- NS(id)

  card(
    full_screen = TRUE,
    card_header(
      class = "d-flex justify-content-between align-items-center",
      tags$span("User interface"),
      chart_type_toggle_ui(ns, default = "donut")
    ),
    card_body(
      plotly::plotlyOutput(ns("plot"), height = 340)
    )
  )
}


user_interface_server <- function(id, data) {
  moduleServer(id, function(input, output, session) {

    counts <- reactive({
      count_categorical(data(), "user_interface")
    })

    chart_type <- chart_type_reactive(input)

    output$plot <- plotly::renderPlotly({
      render_categorical_viz(
        d          = counts(),
        label_col  = "user_interface",
        chart_type = chart_type(),
        empty_msg  = "No user interface data in the current selection"
      )
    })

  })
}
