# ==============================================================================
# server.R — Reactive server logic
#
# Key reactive objects:
#   filtered_projects  applies sidebar filters; consumed by all modules
#   filter_active      TRUE when any filter narrows the full dataset
#
# To add a module: call its *_server() in the MODULE CALLS section below,
#   passing filtered_projects as data.
# To add a filter: add a widget in ui.R, a filter step here in
#   filtered_projects, and an updateSelectizeInput() in reset_filters.
# ==============================================================================

server <- function(input, output, session) {

  # ============================================================================
  # FILTERED DATASET
  # Applies all active sidebar filters. All modules receive this reactive.
  # ============================================================================

  filtered_projects <- reactive({

    df <- projects

    # TRUE when a selectizeInput has at least one value selected.
    active <- function(x) !is.null(x) && length(x) > 0

    # Keeps rows where any selected value appears in a semicolon-separated column.
    filter_multivalue <- function(df, col, selected) {
      sel_lower <- tolower(selected)
      keep <- purrr::map_lgl(df[[col]], function(s) {
        if (is.na(s)) return(FALSE)
        toks <- str_trim(tolower(str_split(s, ";")[[1]]))
        any(sel_lower %in% toks)
      })
      df[keep, , drop = FALSE]
    }

    # Country: convert display names to ISO2 codes before matching
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

    if (active(input$filter_institutions)) {
      df <- filter_multivalue(df, "institutions_clean", input$filter_institutions)
    }

    if (active(input$filter_head_institutions)) {
      df <- filter_multivalue(df, "head_institutions", input$filter_head_institutions)
    }

    if (active(input$filter_public_values_labels)) {
      df <- filter_multivalue(df, "public_values_labels", input$filter_public_values_labels)
    }

    if (active(input$filter_public_private)) {
      df <- df |> filter(public_private %in% input$filter_public_private)
    }

    if (active(input$filter_operational)) {
      df <- df |> filter(operational_status %in% input$filter_operational)
    }

    if (active(input$filter_open_access)) {
      df <- df |> filter(open_access %in% input$filter_open_access)
    }

    if (active(input$filter_scope)) {
      df <- df |> filter(scope %in% input$filter_scope)
    }

    if (active(input$filter_data_types)) {
      df <- filter_multivalue(df, "data_types", input$filter_data_types)
    }

    if (active(input$filter_data_collection_methods)) {
      df <- filter_multivalue(df, "data_collection_methods", input$filter_data_collection_methods)
    }

    if (active(input$filter_tk_from_iplcs)) {
      df <- df |> filter(tk_from_iplcs %in% input$filter_tk_from_iplcs)
    }

    if (active(input$filter_user_interface)) {
      df <- df |> filter(user_interface %in% input$filter_user_interface)
    }

    if (active(input$filter_real_time_data)) {
      df <- df |> filter(real_time_data %in% input$filter_real_time_data)
    }

    if (active(input$filter_what_if_modelling)) {
      df <- df |> filter(what_if_modelling %in% input$filter_what_if_modelling)
    }

    if (active(input$filter_decision_support_function)) {
      df <- df |> filter(decision_support_function %in% input$filter_decision_support_function)
    }

    df
  })


  # TRUE when any filter narrows the result; used by the project browser to
  # update download button labels and filename suffixes.
  filter_active <- reactive({
    nrow(filtered_projects()) < nrow(projects)
  })


  # ============================================================================
  # RESET FILTERS
  # ============================================================================

  observeEvent(input$reset_filters, {
    clr <- character(0)
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
  # MODULE CALLS
  # Instance IDs must match the corresponding *_ui() calls in ui.R.
  # ============================================================================

  overview_server("overview")

  # Capture bubble clicks to pre-apply the country filter and switch tabs.
  overview_map_click <- country_map_server(
    "overview_map",
    data             = reactive(projects),
    selected_country = reactive("all")
  )

  observeEvent(overview_map_click(), {
    cn <- overview_map_click()$country
    if (is.null(cn) || !nzchar(cn)) return()
    # Skip if the country is not among the known filter choices.
    if (!cn %in% filter_opts$country) return()
    updateSelectizeInput(session, "filter_country", selected = cn)
    nav_select(id = "main_navbar", selected = "Data explorer")
  })

  # ---- Data explorer ---------------------------------------------------------

  summary_cards_server("summary", data = filtered_projects)

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

  # Project browser shares sidebar filters; filter_active drives download labels.
  project_browser_server("project_browser",
                         data          = filtered_projects,
                         filter_active = filter_active)

  institutional_network_server("inst_net")

  documentation_server("docs")

}
