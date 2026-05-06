# ==============================================================================
# modules/explorer/_viz_helpers.R
#
# Shared helpers for the Data explorer variable cards. Every card uses the
# same pattern (toggle in header, donut/hbar/vbar render below), so the
# repeating bits live here instead of being duplicated across ten files.
#
# What this file exports:
#   CATEGORICAL_PALETTE      stable brand palette, ordered by visual weight
#   chart_type_toggle_ui()   the three-button toggle for the card_header
#   chart_type_reactive()    reactive() resolving to "donut" / "hbar" / "vbar"
#   count_categorical()      counts for a single-value categorical column
#   count_multivalue()       counts for a `;`-separated multi-value column
#   render_categorical_viz() plotly renderer that branches on chart_type
#
# The toggle is wired to a Shiny input via JS in ui.R (single global handler
# scoped to the .chart-type-toggle group). Each module reads input$chart_type
# automatically because the namespaced id is set on `data-input-id`.
# ==============================================================================


# ------------------------------------------------------------------------------
# Brand palette (mirrors the values in global.R / style guide). The first
# colour is assigned to the largest category so cards lead with brand blue.
# ------------------------------------------------------------------------------
CATEGORICAL_PALETTE <- c(
  "#006AB4",   # TP_BLUE     (brand primary)
  "#f1ae2a",   # TP_GOLD     (warm accent)
  "#002F62",   # TP_NAVY     (dark anchor)
  "#12b878",   # TP_GREEN    (cool accent)
  "#009EE3",   # TP_CYAN     (brand)
  "#db4b68",   # TP_CORAL    (warm contrast)
  "#363c42"    # TP_CHARCOAL (off-brand catch-all)
)


# ------------------------------------------------------------------------------
# UI: three-button toggle to drop into a card_header().
# `ns` is the module's NS function. The actual chart type is computed
# server-side by chart_type_reactive(); the buttons just push the user's
# click intent into Shiny via the JS handler in ui.R.
#
# Icons:
#   chart-pie     donut
#   chart-bar     horizontal bars (FA's chart-bar IS left-anchored)
#   chart-column  vertical bars   (FA6 vertical column chart)
# ------------------------------------------------------------------------------
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


# ------------------------------------------------------------------------------
# Server: returns reactive() resolving to the current chart type.
#
# Behaviour:
#   - If the user has clicked a button, honour their choice (input$chart_type).
#   - Otherwise default to "donut" for every card.
#
# The donut default keeps the chart-type toggle's visual state (donut active
# by default in chart_type_toggle_ui) consistent with what is actually
# rendered. The `counts` and `threshold` arguments are kept for backward
# compatibility with existing callers but are no longer used.
# ------------------------------------------------------------------------------
chart_type_reactive <- function(input, counts = NULL, threshold = 5) {
  reactive({
    ct <- input$chart_type
    if (!is.null(ct) && nzchar(ct)) return(ct)
    "donut"
  })
}




# ------------------------------------------------------------------------------
# Counts helper: single-value categorical column.
# Drops NA / empty strings, counts, sorts desc, sentence-cases the labels.
# Returns a tibble with columns `<col>` and `n`.
# ------------------------------------------------------------------------------
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


# ------------------------------------------------------------------------------
# Counts helper: semicolon-separated multi-value column (e.g. data_types).
# Tokenises, trims, drops empties, counts. Note that totals add up to MORE
# than the project count because each project can contribute to several
# tokens, so percentages on a donut are visually misleading: for these
# columns we still allow the donut view, but bar charts are more honest.
# ------------------------------------------------------------------------------
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


# ------------------------------------------------------------------------------
# Plotly renderer. Returns the plot object (callers wrap in renderPlotly).
#
# Args:
#   d           tibble with columns `<label_col>` and `<count_col>`, sorted
#               desc by count (count_categorical / count_multivalue do this).
#   label_col   name of the categorical column.
#   count_col   name of the count column (default "n").
#   chart_type  "donut" / "hbar" / "vbar".
#   palette     vector of hex colours, in priority order.
#   empty_msg   shown if `d` is empty.
# ------------------------------------------------------------------------------
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

  # Stable colour map: assign palette by descending count rank, so the same
  # category gets the same colour in donut, hbar and vbar.
  d <- d |> dplyr::arrange(dplyr::desc(.data[[count_col]]))
  color_lookup <- setNames(palette[seq_len(nrow(d))], d[[label_col]])

  # Recycle palette if there are more categories than colours (rare but
  # cheap insurance against NA fill colours).
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
      sort      = FALSE,           # already sorted by count
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
        # Generous margins on all sides so outside "label+percent" lead
        # lines aren't clipped: small slices that land at the top or
        # bottom were getting their labels cut off at the card edge.
        margin = list(l = 60, r = 60, t = 60, b = 60),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor  = "rgba(0,0,0,0)"
      ) |>
      plotly::config(displayModeBar = FALSE)

  } else if (chart_type == "hbar") {

    # Ascending order so the largest bar sits at the top of the chart.
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
        # Lock category order to our ascending sort (otherwise plotly
        # re-sorts alphabetically).
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
