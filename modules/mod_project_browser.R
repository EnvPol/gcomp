# ==============================================================================
# modules/mod_project_browser.R (Interactive data table with download)
#
# Displays all project columns as a searchable, sortable table. Lives as a
# sub-tab under Data explorer and consumes the same filtered_projects reactive
# as the visualisations, so the table reflects whatever sidebar filters are
# active.
#
# Search: a single compact freetext input in the card header that searches
# across every column in the display table (case-insensitive substring match).
# All DT built-in column filters have been removed.
#
# Downloads: export the currently filtered + searched set. Button labels say
# "Download filtered..." whenever the sidebar filters OR the search have
# narrowed the results.
#
# HOW TO MODIFY:
#   - Change visible columns:  edit the select() call in display_data
#   - Column widths:           edit the columnDefs list in the datatable call
#   - Rows per page:           edit pageLength in datatable options
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

    # ---- Build display data (all columns, country names converted) -----------
    # country_display is pre-computed in global.R — no per-session countrycode
    # call needed here.
    display_data <- reactive({
      data() |>
        select(
          # Column order follows the source data, with Country kept second (after
          # project name) as the sole exception to the data order rule.
          "Project name"          = project_name,        # col 0
          "Country"               = country_display,     # col 4 (exception)
          "Institutions"          = institutions_clean,  # col 1
          "Head institutions"     = head_institutions,   # col 3
          "Public value framing"  = public_value_framing,# col 5
          "Public value labels"   = public_values_labels,# col 6
          "Technical objectives"  = technical_objectives,# col 7
          "Public/private"        = public_private,      # col 8
          "Funding sources"       = funding_sources,     # col 9
          "Operational"           = operational_status,  # col 10
          "Open access"           = open_access,         # col 11
          "Scope"                 = scope,               # col 12
          "Geographic coverage"   = geographic_coverage, # col 13
          "Data types"            = data_types,          # col 14
          "Data collection"       = data_collection_methods, # col 15
          "TK from IPLCs"         = tk_from_iplcs,       # col 16
          "User interface"        = user_interface,      # col 17
          "Real-time data"        = real_time_data,      # col 18
          "What-if modelling"     = what_if_modelling,   # col 19
          "Decision support"      = decision_support_function, # col 20
          "Homepage"              = homepages,           # col 21
          "Other sources"         = other_relevant_sources,   # col 22
          "Notes"                 = notes                # col 23
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

    # ---- TRUE when sidebar filters OR search have narrowed results -----------
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

      # Column index reference (0-based, matches data source order):
      #  0  Project name         — wide, wrapping     200px
      #  1  Country              — clipped            110px
      #  2  Institutions         — clipped            110px
      #  3  Head institutions    — clipped            110px
      #  4  Public value framing — wider clip         150px
      #  5  Public value labels  — wider clip         150px
      #  6  Technical objectives — wider clip         150px
      #  7  Public/private       — clipped            110px
      #  8  Funding sources      — clipped            110px
      #  9  Operational          — clipped            110px
      # 10  Open access          — clipped            110px
      # 11  Scope                — clipped            110px
      # 12  Geographic coverage  — clipped            110px
      # 13  Data types           — clipped            110px
      # 14  Data collection      — clipped            110px
      # 15  TK from IPLCs        — clipped            110px
      # 16  User interface       — clipped            110px
      # 17  Real-time data       — clipped            110px
      # 18  What-if modelling    — clipped            110px
      # 19  Decision support     — clipped            110px
      # 20  Homepage             — narrow             100px
      # 21  Other sources        — clipped            110px
      # 22  Notes                — clipped            110px

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
          # No global search box (f removed); show entries (l) left, table (t),
          # info (i) and pagination (p) at the bottom.
          dom = "<'d-flex align-items-center justify-content-between pt-1 pb-0 px-3'<''l>>t<'d-flex align-items-center justify-content-between pt-0 pb-1 px-3'ip>",
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

    # ---- Reactive header count -----------------------------------------------
    # Always shows the combined result of sidebar filters + text search,
    # so it stays identical to the sidebar counter at all times.
    output$header_count <- renderText({
      n_total <- nrow(projects)
      n_shown <- nrow(searched_data())

      if (n_shown < n_total) {
        paste0("(", n_shown, " of ", n_total, " projects)")
      } else {
        paste0("(", n_total, " projects)")
      }
    })

    # ---- Dynamic download buttons (label reflects filter + search state) ----
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
