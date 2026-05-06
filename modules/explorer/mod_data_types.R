# ==============================================================================
# modules/explorer/mod_data_types.R (Data types distribution)
#
# `data_types` is a `;`-separated multi-value column: a project can list
# several data types. The counts here are over tokens, not rows: a project
# with "Satellite; In-situ" contributes one to each token's bar.
#
# Note: because totals across tokens exceed the project count, the donut
# view's percentages are "share of token mentions", not "share of projects".
# In practice the auto-default rule (>5 categories -> vbar) usually picks
# bars for this card anyway, which is the more honest view.
# ==============================================================================

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

    # Tokenised counts (split on ";", trim, drop empties).
    counts <- reactive({
      count_multivalue(data(), "data_types", sep = ";")
    })

    chart_type <- chart_type_reactive(input, counts = counts)

    output$plot <- plotly::renderPlotly({
      render_categorical_viz(
        d          = counts(),
        label_col  = "data_types",
        chart_type = chart_type(),
        empty_msg  = "No data types information in the current selection"
      )
    })

  })
}
