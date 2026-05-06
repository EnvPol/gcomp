# ==============================================================================
# modules/explorer/mod_data_collection.R (Data collection methods distribution)
#
# `data_collection_methods` is a `;`-separated multi-value column: a project
# can employ several collection methods. Counts are over tokens, not rows.
# ==============================================================================

data_collection_ui <- function(id) {
  ns <- NS(id)

  card(
    full_screen = TRUE,
    card_header(
      class = "d-flex justify-content-between align-items-center",
      tags$span("Data collection methods"),
      chart_type_toggle_ui(ns, default = "donut")
    ),
    card_body(
      plotly::plotlyOutput(ns("plot"), height = 340)
    )
  )
}


data_collection_server <- function(id, data) {
  moduleServer(id, function(input, output, session) {

    counts <- reactive({
      count_multivalue(data(), "data_collection_methods", sep = ";")
    })

    chart_type <- chart_type_reactive(input, counts = counts)

    output$plot <- plotly::renderPlotly({
      render_categorical_viz(
        d          = counts(),
        label_col  = "data_collection_methods",
        chart_type = chart_type(),
        empty_msg  = "No data collection method information in the current selection"
      )
    })

  })
}
