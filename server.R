# ==============================================================================
# server.R — Reactive server logic
#
# STRUCTURE:
#   server <- function(input, output, session) {
#
#     filtered_projects    ← reactive: applies sidebar filters, used by all modules
#     filter_status        ← output: shows "X of Y projects" in sidebar
#     reset_filters        ← observer: resets all inputs to "all"
#
#     Module server calls  ← one *_server() call per module
#   }
#
# HOW TO ADD A NEW MODULE:
#   Call its *_server() function here, passing filtered_projects as the data argument.
#   Example: my_module_server("my_id", data = filtered_projects)
#
# HOW TO ADD A NEW FILTER:
#   1. Add the filter widget in ui.R → sidebar
#   2. Add a filter() step in the filtered_projects reactive below
#   3. Add an updateSelectInput() call in the reset_filters observer
# ==============================================================================

server <- function(input, output, session) {

  # ============================================================================
  # REACTIVE FILTERED DATASET
  # This reactive applies all sidebar filters and returns a filtered data frame.
  # All dashboard modules receive this reactive as their data input, so every
  # module automatically updates when the user changes a filter.
  #
  # TO ADD A NEW FILTER: add another if() + filter() block following the pattern below.
  # ============================================================================

  filtered_projects <- reactive({

    df <- projects   # start with the full cleaned dataset

    # Helper: TRUE when a selectizeInput has at least one value selected.
    active <- function(x) !is.null(x) && length(x) > 0

    # Helper: multi-value column match (semicolon-separated).
    # Keeps rows where ANY of the selected values appears among the tokens.
    filter_multivalue <- function(df, col, selected) {
      sel_lower <- tolower(selected)
      keep <- purrr::map_lgl(df[[col]], function(s) {
        if (is.na(s)) return(FALSE)
        toks <- str_trim(tolower(str_split(s, ";")[[1]]))
        any(sel_lower %in% toks)
      })
      df[keep, , drop = FALSE]
    }

    # ----- Filters in sidebar/data column order --------------------------------

    # Filter: Country (multi-select; converts names to ISO2 codes first)
    if (active(input$filter_country)) {
      target_iso2 <- suppressWarnings(
        countrycode::countrycode(input$filter_country,
                                 origin      = "country.name",
                                 destination = "iso2c",
                                 warn        = FALSE)
      )
      target_iso2 <- na.omit(target_iso2)
      if (length(target_iso2) == 0) {
        df <- df[0, ]
      } else {
        keep <- purrr::map_lgl(df$countries_iso2, function(s) {
          if (is.na(s)) return(FALSE)
          codes <- str_trim(str_split(s, ";")[[1]])
          any(target_iso2 %in% codes)
        })
        df <- df[keep, , drop = FALSE]
      }
    }

    # Filter: Institution (semicolon-separated multi-value column)
    if (active(input$filter_institutions)) {
      df <- filter_multivalue(df, "institutions_clean", input$filter_institutions)
    }

    # Filter: Head institution (semicolon-separated multi-value column)
    if (active(input$filter_head_institutions)) {
      df <- filter_multivalue(df, "head_institutions", input$filter_head_institutions)
    }

    # Filter: Public value labels
    if (active(input$filter_public_values_labels)) {
      df <- filter_multivalue(df, "public_values_labels", input$filter_public_values_labels)
    }

    # Filter: Public / Private
    if (active(input$filter_public_private)) {
      df <- df |> filter(public_private %in% input$filter_public_private)
    }

    # Filter: Operational status
    if (active(input$filter_operational)) {
      df <- df |> filter(operational_status %in% input$filter_operational)
    }

    # Filter: Open access
    if (active(input$filter_open_access)) {
      df <- df |> filter(open_access %in% input$filter_open_access)
    }

    # Filter: Scope
    if (active(input$filter_scope)) {
      df <- df |> filter(scope %in% input$filter_scope)
    }

    # Filter: Data types
    if (active(input$filter_data_types)) {
      df <- filter_multivalue(df, "data_types", input$filter_data_types)
    }

    # Filter: Data collection methods
    if (active(input$filter_data_collection_methods)) {
      df <- filter_multivalue(df, "data_collection_methods", input$filter_data_collection_methods)
    }

    # Filter: TK from IPLCs
    if (active(input$filter_tk_from_iplcs)) {
      df <- df |> filter(tk_from_iplcs %in% input$filter_tk_from_iplcs)
    }

    # Filter: User interface
    if (active(input$filter_user_interface)) {
      df <- df |> filter(user_interface %in% input$filter_user_interface)
    }

    # Filter: Real-time data
    if (active(input$filter_real_time_data)) {
      df <- df |> filter(real_time_data %in% input$filter_real_time_data)
    }

    # Filter: What-if modelling
    if (active(input$filter_what_if_modelling)) {
      df <- df |> filter(what_if_modelling %in% input$filter_what_if_modelling)
    }

    # Filter: Decision support function
    if (active(input$filter_decision_support_function)) {
      df <- df |> filter(decision_support_function %in% input$filter_decision_support_function)
    }

    df   # return the filtered data frame
  })


  # ============================================================================
  # FILTER ACTIVE FLAG
  # TRUE when any sidebar filter is non-default (i.e. the filtered set is a
  # strict subset of the full dataset). Consumed by the project browser module
  # to swap download button labels to "Download filtered..." and to suffix
  # output filenames with "_filtered".
  # ============================================================================

  filter_active <- reactive({
    nrow(filtered_projects()) < nrow(projects)
  })


  # ============================================================================
  # RESET FILTERS
  # Resets all filter inputs back to "All" when the reset button is clicked.
  # TO ADD A NEW FILTER: add an updateSelectInput() call here matching its inputId.
  # ============================================================================

  observeEvent(input$reset_filters, {
    clr <- character(0)   # empty selection = "All" for selectizeInput
    updateSelectizeInput(session, "filter_country",                       selected = clr)
    updateSelectizeInput(session, "filter_institutions",                  selected = clr)
    updateSelectizeInput(session, "filter_head_institutions",             selected = clr)
    updateSelectizeInput(session, "filter_public_values_labels",          selected = clr)
    updateSelectizeInput(session, "filter_public_private",                selected = clr)
    updateSelectizeInput(session, "filter_operational",                   selected = clr)
    updateSelectizeInput(session, "filter_open_access",                   selected = clr)
    updateSelectizeInput(session, "filter_scope",                         selected = clr)
    updateSelectizeInput(session, "filter_data_types",                    selected = clr)
    updateSelectizeInput(session, "filter_data_collection_methods",       selected = clr)
    updateSelectizeInput(session, "filter_tk_from_iplcs",                 selected = clr)
    updateSelectizeInput(session, "filter_user_interface",                selected = clr)
    updateSelectizeInput(session, "filter_real_time_data",                selected = clr)
    updateSelectizeInput(session, "filter_what_if_modelling",             selected = clr)
    updateSelectizeInput(session, "filter_decision_support_function",     selected = clr)
  })


  # ============================================================================
  # MODULE SERVER CALLS
  # Each module's server function is called here.
  # The "summary" etc. strings are module instance IDs — they must match the
  # IDs used in the corresponding *_ui() calls in ui.R.
  #
  # TO ADD A NEW MODULE: add its *_server() call here.
  # ============================================================================

  # Overview landing page (static counts + map of full catalogue)
  overview_server("overview")

  # The country map returns an eventReactive that fires on every bubble click
  # with $country + a random $.nonce. We capture it so we can navigate the
  # user to the Data explorer with the clicked country filter pre-applied.
  overview_map_click <- country_map_server(
    "overview_map",
    data             = reactive(projects),
    selected_country = reactive("all")
  )

  # On bubble click: apply the country filter and switch to Data explorer.
  # The country_name layerId set in mod_country_map.R is exactly the value
  # filter_opts$country lists, so updateSelectInput finds the right choice.
  observeEvent(overview_map_click(), {
    cn <- overview_map_click()$country
    if (is.null(cn) || !nzchar(cn)) return()

    # Defensive guard: only apply if the clicked country is among the known
    # filter choices. Prevents an unexpected layerId silently breaking the
    # selectInput state.
    if (!cn %in% filter_opts$country) return()

    updateSelectizeInput(session, "filter_country", selected = cn)
    nav_select(id = "main_navbar", selected = "Data explorer")
  })

  # ---- Data explorer ---------------------------------------------------------

  # Summary stat cards (respond to filters)
  summary_cards_server("summary", data = filtered_projects)

  # Variable cards (order matches data column order)
  public_values_server    ("public_values",     data = filtered_projects)
  public_private_server   ("public_private",    data = filtered_projects)
  operational_server      ("operational",       data = filtered_projects)
  open_access_server      ("open_access",       data = filtered_projects)
  scope_server            ("scope",             data = filtered_projects)
  data_types_server       ("data_types",        data = filtered_projects)
  data_collection_server  ("data_collection",   data = filtered_projects)
  tk_server               ("tk",                data = filtered_projects)
  user_interface_server   ("user_interface",    data = filtered_projects)
  real_time_server        ("real_time",         data = filtered_projects)
  what_if_server          ("what_if",           data = filtered_projects)
  decision_support_server ("decision_support",  data = filtered_projects)

  # ---- Other tabs ------------------------------------------------------------

  # Project browser (now lives as a sub-tab under Data explorer and shares the
  # same sidebar filters, so we hand it filtered_projects rather than the full
  # dataset. filter_active drives the dynamic download button labels.)
  # The module returns the active row count (sidebar filters + text search
  # combined) so the sidebar counter below stays in sync with the browser header.
  n_browser_shown <- project_browser_server("project_browser",
                                            data          = filtered_projects,
                                            filter_active = filter_active)

  # Institutional network
  institutional_network_server("inst_net",
                               institutions_path = "institutions.xlsx",
                               projects_path     = "projects.xlsx")

  # Documentation (static — no data needed)
  documentation_server("docs")

}
