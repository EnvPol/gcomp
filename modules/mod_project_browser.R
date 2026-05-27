# ==============================================================================
# modules/mod_project_browser.R — Searchable project table with downloads
#
# Shares the sidebar filters via filtered_projects. A freetext header search
# filters across all columns on top of the sidebar filters. Downloads export
# the current combined result.
#
# To change visible columns: edit the select() call in display_data.
# ==============================================================================


# --- UI -----------------------------------------------------------------------
project_browser_ui <- function(id) {
  ns <- NS(id)

  card(
    class = "project-browser-card",

    # Header: title + search input + download buttons all in one compact row.
    card_header(
      class = "project-browser-header d-flex align-items-center gap-2",

      # Title / row count (left)
      div(class = "d-flex align-items-center text-nowrap",
        tags$span("Projects dataset", class = "fw-bold me-1"),
        tags$span(class = "text-muted",
          textOutput(ns("header_count"), inline = TRUE)
        )
      ),

      # Single global search input (fixed width, does not grow)
      tags$input(
        id          = ns("search_all"),
        type        = "search",
        class       = "form-control form-control-sm project-browser-search",
        placeholder = "Search all columns...",
        oninput     = sprintf(
          "Shiny.setInputValue('%s', this.value, {priority: 'event'})",
          ns("search_all")
        )
      ),

      # Download buttons (pushed to the right)
      div(
        class = "d-flex flex-shrink-0 gap-1 ms-auto",
        uiOutput(ns("download_csv_btn"),   inline = TRUE),
        uiOutput(ns("download_excel_btn"), inline = TRUE)
      )
    ),

    card_body(
      class = "p-0",
      style = "overflow: hidden;",
      DT::dataTableOutput(ns("table"))
    )
  )
}


# --- SERVER -------------------------------------------------------------------
project_browser_server <- function(id, data, filter_active = reactive(FALSE)) {
  moduleServer(id, function(input, output, session) {

    ns <- session$ns

    # country_display is pre-computed in global.R.
    display_data <- reactive({
      data() |>
        select(
          "Project name"          = project_name,
          "Institutions"          = institutions_clean,
          "Head institutions"     = head_institutions,
          "Country"               = country_display,
          "Public value framing"  = public_value_framing,
          "Public value labels"   = public_values_labels,
          "Technical objectives"  = technical_objectives,
          "Public/private"        = public_private,
          "Funding sources"       = funding_sources,
          "Operational status"    = operational_status,
          "Open access"           = open_access,
          "Scope"                 = scope,
          "Geographic coverage"   = geographic_coverage,
          "Data types"            = data_types,
          "Data collection"       = data_collection_methods,
          "TK from IPLCs"         = tk_from_iplcs,
          "User interface"        = user_interface,
          "Real-time data"        = real_time_data,
          "What-if modelling"     = what_if_modelling,
          "Decision support"      = decision_support_function,
          "Homepage"              = homepages,
          "Other sources"         = other_relevant_sources
        )
    })

    # ---- Apply global text search across all columns -------------------------
    searched_data <- reactive({
      df  <- display_data()
      q   <- str_trim(if (!is.null(input$search_all)) input$search_all else "")
      if (!nzchar(q)) return(df)

      pattern <- fixed(str_to_lower(q))

      # Convert every cell to lowercase string; keep rows where any cell matches.
      keep <- apply(df, 1, function(row) {
        any(str_detect(str_to_lower(coalesce(as.character(row), "")), pattern))
      })
      df[keep, , drop = FALSE]
    })

    # TRUE when sidebar filters or search have narrowed the result set.
    any_active <- reactive({
      isTRUE(filter_active()) || nrow(searched_data()) < nrow(projects)
    })

    # ---- Render the DT -------------------------------------------------------
    output$table <- DT::renderDataTable({

      # Tooltip spans for column headers (truncate long names with ellipsis).
      header_style <- paste0(
        "display:block;max-width:100%;overflow:hidden;",
        "text-overflow:ellipsis;white-space:nowrap;padding-right:14px;"
      )
      col_labels  <- names(searched_data())
      col_escaped <- htmltools::htmlEscape(col_labels)
      col_headers <- paste0(
        '<span class="dt-col-header" title="', col_escaped,
        '" style="', header_style, '">',
        col_escaped, '</span>'
      )

      DT::datatable(
        searched_data(),
        filter    = "none",
        rownames  = FALSE,
        escape    = FALSE,
        colnames  = col_headers,
        selection = "none",
        options   = list(
          pageLength = 25,
          scrollY        = "300px",
          scrollCollapse = FALSE,
          scrollX        = TRUE,
          autoWidth      = FALSE,
          columnDefs = list(
            list(targets = 0,         className = "dt-col-name",   width = "200px"),
            list(targets = 20,        className = "dt-col-narrow", width = "100px"),
            list(targets = c(4, 5, 6),className = "dt-col-clip",   width = "150px"),
            list(targets = c(1:3, 7:19, 21:22), className = "dt-col-clip", width = "110px")
          ),
          dom ="<'d-flex align-items-center justify-content-between pt-1 pb-0 px-3'<''l>>t<'d-flex align-items-center justify-content-between pt-0 pb-1 px-3'ip>",
          language = list(search = ""),
          # Set each cell's title attribute to its text so the browser native
          # tooltip shows the full content on hover (useful for clipped cells).
          createdRow = JS(
            "function(row) {",
            "  $(row).find('td').each(function() {",
            "    var txt = $(this).text().trim();",
            "    if (txt) $(this).attr('title', txt);",
            "  });",
            "}"
          )
        ),
        class = "stripe hover compact"
      )
    })

    output$header_count <- renderText({
      n_total <- nrow(projects)
      n_shown <- nrow(searched_data())

      if (n_shown < n_total) {
        paste0("(", n_shown, " of ", n_total, " projects)")
      } else {
        paste0("(", n_total, " projects)")
      }
    })

    # Download button labels change when filters or search are active.
    output$download_csv_btn <- renderUI({
      label <- if (isTRUE(any_active())) "Download filtered CSV" else "Download CSV"
      downloadButton(
        ns("download_csv"),
        label = label,
        icon  = icon("file-csv"),
        class = "btn-sm btn-outline-primary"
      )
    })

    output$download_excel_btn <- renderUI({
      label <- if (isTRUE(any_active())) "Download filtered Excel" else "Download Excel"
      downloadButton(
        ns("download_excel"),
        label = label,
        icon  = icon("file-excel"),
        class = "btn-sm btn-outline-primary"
      )
    })

    # ---- Download handlers ---------------------------------------------------
    output$download_csv <- downloadHandler(
      filename = function() {
        suffix <- if (isTRUE(any_active())) "_filtered" else ""
        paste0("twinpolitics_gcomp_", Sys.Date(), suffix, ".csv")
      },
      content = function(file) write.csv(searched_data(), file, row.names = FALSE)
    )

    output$download_excel <- downloadHandler(
      filename = function() {
        suffix <- if (isTRUE(any_active())) "_filtered" else ""
        paste0("twinpolitics_gcomp_", Sys.Date(), suffix, ".xlsx")
      },
      content = function(file) write_xlsx(searched_data(), file)
    )

    # ---- Return the active row count ----------------------------------------
    # Returned to server.R so the sidebar counter can stay in sync with the
    # combined sidebar + text search result shown in the browser header.
    reactive(nrow(searched_data()))

  })
}
