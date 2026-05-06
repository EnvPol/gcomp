# ==============================================================================
# modules/explorer/mod_public_values.R (Public value labels distribution)
#
# `public_values_labels` is a `;`-separated multi-value column: a project can
# carry several public value labels. Counts are over tokens, not rows, so
# totals exceed the project count. Bar charts are the more honest view here.
# ==============================================================================

public_values_ui <- function(id) {
  ns <- NS(id)

  card(
    full_screen = TRUE,
    card_header(
      class = "d-flex justify-content-between align-items-center",
      tags$span("Public value labels"),
      chart_type_toggle_ui(ns, default = "donut")
    ),
    card_body(
      plotly::plotlyOutput(ns("plot"), height = 340)
    )
  )
}


public_values_server <- function(id, data) {
  moduleServer(id, function(input, output, session) {

    counts <- reactive({
      count_multivalue(data(), "public_values_labels", sep = ";")
    })

    chart_type <- chart_type_reactive(input)

    output$plot <- plotly::renderPlotly({
      render_categorical_viz(
        d          = counts(),
        label_col  = "public_values_labels",
        chart_type = chart_type(),
        empty_msg  = "No public value label information in the current selection"
      )
    })

  })
}
