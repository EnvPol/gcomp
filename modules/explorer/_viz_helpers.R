# ==============================================================================
# modules/explorer/_viz_helpers.R
#
# Shared helpers for variable cards. Exports:
#   CATEGORICAL_PALETTE      brand palette, ordered by visual weight
#   chart_type_toggle_ui()   three-button toggle for card headers
#   chart_type_reactive()    reactive resolving to "donut" / "hbar" / "vbar"
#   count_categorical()      counts for a single-value categorical column
#   count_multivalue()       counts for a semicolon-separated multi-value column
#   render_categorical_viz() plotly renderer that branches on chart type
#
# The toggle is wired to Shiny via a JS handler in ui.R. Each module reads
# input$chart_type via the namespaced id set on data-input-id.
# ==============================================================================


# Brand palette — first colour goes to the largest category.
CATEGORICAL_PALETTE <- c(
  "#006AB4",   # TP_BLUE
  "#f1ae2a",   # TP_GOLD
  "#002F62",   # TP_NAVY
  "#12b878",   # TP_GREEN
  "#009EE3",   # TP_CYAN
  "#db4b68",   # TP_CORAL
  "#363c42"    # TP_CHARCOAL
)


# Three-button toggle for chart_header(). Buttons push the selected type to
# input$chart_type via the JS handler in ui.R.
chart_type_toggle_ui <- function(ns, default = "donut") {

  active_class <- function(t) {
    if (identical(t, default)) "chart-type-btn active" else "chart-type-btn"
  }

  tags$div(
    class = "chart-type-toggle",
    `data-input-id` = ns("chart_type"),

    tags$button(type  = "button",
                class = active_class("donut"),
                `data-chart-type` = "donut",
                title = "Donut",
                `aria-label` = "Donut chart",
                icon("chart-pie")),

    tags$button(type  = "button",
                class = active_class("hbar"),
                `data-chart-type` = "hbar",
                title = "Horizontal bars",
                `aria-label` = "Horizontal bar chart",
                icon("chart-bar")),

    tags$button(type  = "button",
                class = active_class("vbar"),
                `data-chart-type` = "vbar",
                title = "Vertical bars",
                `aria-label` = "Vertical bar chart",
                icon("chart-column"))
  )
}


# Returns the active chart type; falls back to "donut" if none selected.
chart_type_reactive <- function(input) {
  reactive({
    ct <- input$chart_type
    if (!is.null(ct) && nzchar(ct)) return(ct)
    "donut"
  })
}


# Counts for a single-value categorical column.
# Drops NA / empty, counts, sorts descending, sentence-cases labels.
count_categorical <- function(df, col, sentence_case = TRUE) {

  empty <- function() {
    res <- tibble::tibble(label = character(), n = integer())
    names(res)[1] <- col
    res
  }

  if (is.null(df) || nrow(df) == 0 || !(col %in% names(df))) {
    return(empty())
  }

  out <- df |>
    dplyr::filter(!is.na(.data[[col]]) & .data[[col]] != "") |>
    dplyr::count(.data[[col]], name = "n") |>
    dplyr::arrange(dplyr::desc(n))

  if (sentence_case && nrow(out) > 0) {
    out[[col]] <- stringr::str_to_sentence(out[[col]])
  }

  out
}


# Counts for a semicolon-separated multi-value column.
# Totals exceed the project count — each project contributes to multiple tokens.
# Bar charts are more honest than donuts for these columns.
count_multivalue <- function(df, col, sep = ";", sentence_case = TRUE) {

  empty <- function() {
    res <- tibble::tibble(label = character(), n = integer())
    names(res)[1] <- col
    res
  }

  if (is.null(df) || nrow(df) == 0 || !(col %in% names(df))) {
    return(empty())
  }

  vals <- df[[col]]
  vals <- vals[!is.na(vals)]
  vals <- unlist(stringr::str_split(vals, sep), use.names = FALSE)
  vals <- stringr::str_trim(vals)
  vals <- vals[nzchar(vals)]

  if (length(vals) == 0) return(empty())

  if (sentence_case) vals <- stringr::str_to_sentence(vals)

  res <- as.data.frame(table(vals), stringsAsFactors = FALSE,
                       responseName = "n")
  names(res)[1] <- col
  res <- tibble::as_tibble(res)
  res |> dplyr::arrange(dplyr::desc(n))
}


# Plotly renderer for categorical data. Returns a plot object.
#
# Args:
#   d          tibble with columns <label_col> and <count_col>, sorted desc
#   label_col  name of the label column
#   count_col  name of the count column (default "n")
#   chart_type "donut" / "hbar" / "vbar"
#   palette    hex colour vector in priority order
#   empty_msg  message shown when d is empty
render_categorical_viz <- function(d, label_col,
                                   count_col  = "n",
                                   chart_type = "donut",
                                   palette    = CATEGORICAL_PALETTE,
                                   empty_msg  = "No data in the current selection") {

  if (is.null(d) || nrow(d) == 0) {
    return(plotly::plotly_empty(type = "pie") |>
             plotly::layout(
               title = list(text = empty_msg, font = list(size = 13))
             ))
  }

  # Assign colours by descending count rank for consistency across chart types.
  d <- d |> dplyr::arrange(dplyr::desc(.data[[count_col]]))
  color_lookup <- setNames(palette[seq_len(nrow(d))], d[[label_col]])

  # Recycle palette if needed.
  if (anyNA(color_lookup)) {
    color_lookup[is.na(color_lookup)] <-
      palette[((which(is.na(color_lookup)) - 1) %% length(palette)) + 1]
  }

  if (chart_type == "donut") {

    plotly::plot_ly(
      labels    = d[[label_col]],
      values    = d[[count_col]],
      type      = "pie",
      hole      = 0.55,
      sort      = FALSE,
      direction = "clockwise",
      marker    = list(
        colors = unname(color_lookup[d[[label_col]]]),
        line   = list(color = "#ffffff", width = 1.5)
      ),
      textinfo      = "label+percent",
      textposition  = "outside",
      hovertemplate = "<b>%{label}</b><br>%{value} projects (%{percent})<extra></extra>"
    ) |>
      plotly::layout(
        showlegend = FALSE,
        # Generous margins prevent outside labels from being clipped.
        margin = list(l = 60, r = 60, t = 60, b = 60),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor  = "rgba(0,0,0,0)"
      ) |>
      plotly::config(displayModeBar = FALSE)

  } else if (chart_type == "hbar") {

    # Ascending so the largest bar appears at the top.
    d_h <- d |> dplyr::arrange(.data[[count_col]])

    plotly::plot_ly(
      x           = d_h[[count_col]],
      y           = d_h[[label_col]],
      type        = "bar",
      orientation = "h",
      marker      = list(color = unname(color_lookup[d_h[[label_col]]])),
      hovertemplate = "<b>%{y}</b><br>%{x} projects<extra></extra>"
    ) |>
      plotly::layout(
        showlegend = FALSE,
        margin = list(l = 110, r = 20, t = 20, b = 40),
        xaxis  = list(title = "Projects",
                      gridcolor = "#e7ecf0",
                      zerolinecolor = "#cdd5db"),
        # Fix order; plotly otherwise sorts alphabetically.
        yaxis  = list(title = "",
                      categoryorder = "array",
                      categoryarray = d_h[[label_col]]),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor  = "rgba(0,0,0,0)"
      ) |>
      plotly::config(displayModeBar = FALSE)

  } else {  # "vbar"

    plotly::plot_ly(
      x           = d[[label_col]],
      y           = d[[count_col]],
      type        = "bar",
      marker      = list(color = unname(color_lookup[d[[label_col]]])),
      hovertemplate = "<b>%{x}</b><br>%{y} projects<extra></extra>"
    ) |>
      plotly::layout(
        showlegend = FALSE,
        margin = list(l = 50, r = 20, t = 20, b = 80),
        xaxis  = list(title = "",
                      categoryorder = "array",
                      categoryarray = d[[label_col]],
                      tickangle = -25),
        yaxis  = list(title = "Projects",
                      gridcolor = "#e7ecf0",
                      zerolinecolor = "#cdd5db"),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor  = "rgba(0,0,0,0)"
      ) |>
      plotly::config(displayModeBar = FALSE)
  }
}
