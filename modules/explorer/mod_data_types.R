# modules/explorer/mod_data_types.R — Data types distribution (multi-value)
# Counts are over tokens, not rows; totals exceed the project count.

data_types_ui <- function(id) {
  ns <- NS(id)

  card(
    full_screen = TRUE,
    card_header(
      class = "d-flex justify-content-between align-items-center",
      tags$span("Data types"),
      chart_type_toggle_ui(ns, default = "donut")
    ),
    card_body(
      plotly::plotlyOutput(ns("plot"), height = 340)
    )
  )
}


data_types_server <- function(id, data) {
  moduleServer(id, function(input, output, session) {

    counts <- reactive({
      count_multivalue(data(), "data_types", sep = ";")
    })

    chart_type <- chart_type_reactive(input)

    output$plot <- plotly::renderPlotly({
      render_categorical_viz(
        d          = counts(),
        label_col  = "data_types",
        chart_type = chart_type(),
        empty_msg  = "No data types data in the current selection"
      )
    })
    
  })
}
