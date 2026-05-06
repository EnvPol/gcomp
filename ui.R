# ==============================================================================
# ui.R — Top-level layout
#
# Structure:
#   page_navbar
#   ├── Overview            landing page + map, no sidebar
#   ├── Data explorer       shared sidebar across two sub-tabs:
#   │   ├── Visualisations  summary cards + variable card grid
#   │   └── Project browser searchable table + downloads
#   ├── Institutional network
#   └── Documentation
#
# The sidebar and both sub-tabs share one layout_sidebar so filter inputs
# are rendered once and apply to both sub-tabs without duplicate ID errors.
#
# To add a variable card: create the module, source it in global.R, add a
# toggle button and conditionalPanel below, and register its server call.
# ==============================================================================

ui <- page_navbar(

  # id enables server-side tab switching via nav_select()
  id           = "main_navbar",

  title        = tags$span(
    class   = "gcomp-brand",
    style   = "cursor: pointer;",
    onclick = "$(\"a[data-value='Overview']\").tab('show'); return false;",
    tags$img(
      src   = "twinpolitics-logo-color.png",
      alt   = "TwinPolitics",
      class = "gcomp-brand-logo"
    )
  ),
  window_title = "TwinPolitics GCOMP",
  theme        = app_theme,
  fillable     = FALSE,
  lang         = "en",

  header = tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
  ),


  # ============================================================================
  # TAB 1: OVERVIEW (landing page + map — no sidebar)
  # ============================================================================
  nav_panel(
    title = "Overview",
    icon  = icon("house"),

    overview_ui("overview")
  ),


  # ============================================================================
  # TAB 2: DATA EXPLORER (with shared sidebar across two sub-tabs)
  # The sidebar lives at the top of layout_sidebar so its filter inputs are
  # rendered exactly once. The two sub-tabs (Visualisations / Project browser)
  # both consume the same filtered_projects reactive on the server side.
  # ============================================================================
  nav_panel(
    title = "Data explorer",
    icon  = icon("chart-bar"),

    div(class = "container-fluid py-3",

      layout_sidebar(
        fillable = FALSE,

        # ------------------------------------------------------------------
        # SIDEBAR -- Filter widgets (shared across both sub-tabs)
        # ------------------------------------------------------------------
        sidebar = sidebar(
          width = 210,
          open  = "open",
          class = "sidebar-compact",

          tags$h6(
            class = "fw-bold text-uppercase mb-1 d-flex align-items-center gap-1",
            style = "letter-spacing: 0.05em; font-size: 0.7rem;",
            "Filter projects",
            tags$span(
              icon("left-right", style = "font-size: 0.8rem;"),
              class = "text-muted",
              style = "cursor: default;",
              title = "Drag the sidebar edge to resize"
            )
          ),

          actionButton("reset_filters", "Reset filters",
                       icon  = icon("rotate-left"),
                       class = "btn-outline-secondary btn-sm w-100 mt-0 mb-2"),

          tags$hr(class = "my-1"),

          selectizeInput("filter_country",                   "Country",
                         choices = filter_opts$country, multiple = TRUE,
                         selected = NULL,
                         options = list(placeholder = "All")),

          selectizeInput("filter_institutions",              "Institution",
                         choices = filter_opts$institutions, multiple = TRUE,
                         selected = NULL,
                         options = list(placeholder = "All")),
          selectizeInput("filter_head_institutions",         "Head institution",
                         choices = filter_opts$head_institutions, multiple = TRUE,
                         selected = NULL,
                         options = list(placeholder = "All")),

          tags$hr(class = "my-1"),

          selectizeInput("filter_public_values_labels",      "Public value labels",
                         choices = filter_opts$public_values_labels, multiple = TRUE,
                         selected = NULL,
                         options = list(placeholder = "All")),
          selectizeInput("filter_public_private",            "Public / Private",
                         choices = filter_opts$public_private, multiple = TRUE,
                         selected = NULL,
                         options = list(placeholder = "All")),
          selectizeInput("filter_operational",               "Operational status",
                         choices = filter_opts$operational_status, multiple = TRUE,
                         selected = NULL,
                         options = list(placeholder = "All")),
          selectizeInput("filter_open_access",               "Open access",
                         choices = filter_opts$open_access, multiple = TRUE,
                         selected = NULL,
                         options = list(placeholder = "All")),
          selectizeInput("filter_scope",                     "Scope",
                         choices = filter_opts$scope, multiple = TRUE,
                         selected = NULL,
                         options = list(placeholder = "All")),
          selectizeInput("filter_data_types",                "Data types",
                         choices = filter_opts$data_types, multiple = TRUE,
                         selected = NULL,
                         options = list(placeholder = "All")),
          selectizeInput("filter_data_collection_methods",   "Data collection",
                         choices = filter_opts$data_collection_methods, multiple = TRUE,
                         selected = NULL,
                         options = list(placeholder = "All")),
          selectizeInput("filter_tk_from_iplcs",             "TK from IPLCs",
                         choices = filter_opts$tk_from_iplcs, multiple = TRUE,
                         selected = NULL,
                         options = list(placeholder = "All")),
          selectizeInput("filter_user_interface",            "User interface",
                         choices = filter_opts$user_interface, multiple = TRUE,
                         selected = NULL,
                         options = list(placeholder = "All")),
          selectizeInput("filter_real_time_data",            "Real-time data",
                         choices = filter_opts$real_time_data, multiple = TRUE,
                         selected = NULL,
                         options = list(placeholder = "All")),
          selectizeInput("filter_what_if_modelling",         "What-if modelling",
                         choices = filter_opts$what_if_modelling, multiple = TRUE,
                         selected = NULL,
                         options = list(placeholder = "All")),
          selectizeInput("filter_decision_support_function", "Decision support",
                         choices = filter_opts$decision_support_function, multiple = TRUE,
                         selected = NULL,
                         options = list(placeholder = "All"))
        ),

        # Sub-tabs share the sidebar above; filters apply to whichever is active.
        navset_underline(
          id = "explorer_subtabs",

          # Sub-tab A: Visualisations
          nav_panel(
            title = "Visualisations",
            icon  = icon("chart-bar"),

            tags$div(class = "mt-3"),

            summary_cards_ui("summary"),

            tags$div(class = "mt-3"),

            # Toggle bar: buttons show/hide individual cards. Active set is
            # pushed to input$viz_visible; each card's conditionalPanel reads it.
            # To add a card: add a button here, a conditionalPanel below,
            # and a *_server() call in server.R.
            div(class = "viz-toggle-bar",
              tags$span(class = "viz-toggle-bar-label", "Show:"),
              tags$button(type = "button", class = "viz-toggle-all", "Show all"),
              tags$button(type = "button", class = "viz-toggle", `data-var` = "public_values",    "Public value labels"),
              tags$button(type = "button", class = "viz-toggle", `data-var` = "public_private",   "Public / Private"),
              tags$button(type = "button", class = "viz-toggle", `data-var` = "operational",      "Operational status"),
              tags$button(type = "button", class = "viz-toggle", `data-var` = "open_access",      "Open access"),
              tags$button(type = "button", class = "viz-toggle", `data-var` = "scope",            "Scope"),
              tags$button(type = "button", class = "viz-toggle", `data-var` = "data_types",       "Data types"),
              tags$button(type = "button", class = "viz-toggle", `data-var` = "data_collection",  "Data collection"),
              tags$button(type = "button", class = "viz-toggle", `data-var` = "tk",               "TK from IPLCs"),
              tags$button(type = "button", class = "viz-toggle", `data-var` = "user_interface",   "User interface"),
              tags$button(type = "button", class = "viz-toggle", `data-var` = "real_time",        "Real-time data"),
              tags$button(type = "button", class = "viz-toggle", `data-var` = "what_if",          "What-if modelling"),
              tags$button(type = "button", class = "viz-toggle", `data-var` = "decision_support", "Decision support")
            ),

            tags$div(class = "mt-3"),

            # Variable cards — 2-column grid, each gated by conditionalPanel.
            div(class = "viz-grid",
              conditionalPanel(
                condition = "input.viz_visible && input.viz_visible.indexOf('public_values') > -1",
                public_values_ui("public_values")
              ),
              conditionalPanel(
                condition = "input.viz_visible && input.viz_visible.indexOf('public_private') > -1",
                public_private_ui("public_private")
              ),
              conditionalPanel(
                condition = "input.viz_visible && input.viz_visible.indexOf('operational') > -1",
                operational_ui("operational")
              ),
              conditionalPanel(
                condition = "input.viz_visible && input.viz_visible.indexOf('open_access') > -1",
                open_access_ui("open_access")
              ),
              conditionalPanel(
                condition = "input.viz_visible && input.viz_visible.indexOf('scope') > -1",
                scope_ui("scope")
              ),
              conditionalPanel(
                condition = "input.viz_visible && input.viz_visible.indexOf('data_types') > -1",
                data_types_ui("data_types")
              ),
              conditionalPanel(
                condition = "input.viz_visible && input.viz_visible.indexOf('data_collection') > -1",
                data_collection_ui("data_collection")
              ),
              conditionalPanel(
                condition = "input.viz_visible && input.viz_visible.indexOf('tk') > -1",
                tk_ui("tk")
              ),
              conditionalPanel(
                condition = "input.viz_visible && input.viz_visible.indexOf('user_interface') > -1",
                user_interface_ui("user_interface")
              ),
              conditionalPanel(
                condition = "input.viz_visible && input.viz_visible.indexOf('real_time') > -1",
                real_time_ui("real_time")
              ),
              conditionalPanel(
                condition = "input.viz_visible && input.viz_visible.indexOf('what_if') > -1",
                what_if_ui("what_if")
              ),
              conditionalPanel(
                condition = "input.viz_visible && input.viz_visible.indexOf('decision_support') > -1",
                decision_support_ui("decision_support")
              )
            )
          ), # end Visualisations sub-tab

          # Sub-tab B: Project browser
          nav_panel(
            title = "Project browser",
            icon  = icon("table"),

            tags$div(class = "mt-3"),

            project_browser_ui("project_browser")
          ) # end Project browser sub-tab

        ), # end navset_underline

        # JS: variable toggle bar (input$viz_visible) and per-card chart-type
        # toggle (input$chart_type, namespaced via data-input-id attribute).
        tags$script(HTML(
          "function syncShowAllLabel() {
             var $all      = $('.viz-toggle');
             var $active   = $('.viz-toggle.active');
             var allActive = $all.length > 0 && $active.length === $all.length;
             $('.viz-toggle-all').text(allActive ? 'Hide all' : 'Show all');
           }
           function pushVizVisible() {
             var active = $('.viz-toggle.active').map(function() {
               return $(this).attr('data-var');
             }).get();
             Shiny.setInputValue('viz_visible', active, {priority: 'event'});
           }
           $(document).on('click', '.viz-toggle', function() {
             $(this).toggleClass('active');
             pushVizVisible();
             syncShowAllLabel();
           });
           $(document).on('click', '.viz-toggle-all', function() {
             var $all      = $('.viz-toggle');
             var allActive = $all.filter('.active').length === $all.length;
             if (allActive) {
               $all.removeClass('active');
             } else {
               $all.addClass('active');
             }
             pushVizVisible();
             syncShowAllLabel();
           });
           $(document).on('shiny:connected', function() {
             // Start with all cards visible.
             $('.viz-toggle').addClass('active');
             pushVizVisible();
             syncShowAllLabel();
           });
           $(document).on('click', '.chart-type-toggle .chart-type-btn', function() {
             var $btn   = $(this);
             var $group = $btn.closest('.chart-type-toggle');
             $group.find('.chart-type-btn').removeClass('active');
             $btn.addClass('active');
             var inputId = $group.attr('data-input-id');
             if (inputId) {
               Shiny.setInputValue(inputId, $btn.attr('data-chart-type'),
                                   {priority: 'event'});
             }
           });

           // Sync project browser card height to the sidebar.
           // BROWSER_CARD_CHROME_PX is the non-scrollable UI chrome within the card.
           var BROWSER_CARD_CHROME_PX = 240;

           function syncBrowserHeight() {
             var $sidebar = $('.sidebar-compact').first();
             var $card    = $('.project-browser-card').first();
             if (!$sidebar.length || !$card.length) return;
             var h = $sidebar.outerHeight();
             if (h <= 0) return;

             $card.css('height', h + 'px');

             var bodyH = Math.max(150, h - BROWSER_CARD_CHROME_PX);
             $card.find('.dataTables_scrollBody').css({
               'max-height': bodyH + 'px',
               'height':     bodyH + 'px'
             });

             // Reflow DT column widths to the new size.
             var $tbl = $card.find('table.dataTable');
             if ($tbl.length && $.fn.dataTable && $.fn.dataTable.isDataTable($tbl)) {
               $tbl.DataTable().columns.adjust();
             }
           }

           $(document).on('shiny:connected', function() {
             setTimeout(syncBrowserHeight, 150);
           });
           $(window).on('resize', function() {
             // Debounce resize events.
             clearTimeout(window.__browserHeightTimer);
             window.__browserHeightTimer = setTimeout(syncBrowserHeight, 100);
           });
           $(document).on('shown.bs.tab', function() {
             setTimeout(syncBrowserHeight, 50);
           });
           $(document).on('shiny:value', function(e) {
             if (e && e.name && e.name.indexOf('project_browser-table') !== -1) {
               setTimeout(syncBrowserHeight, 50);
             }
           });"
        ))

      ) # end layout_sidebar
    ) # end container
  ), # end Data explorer


  # ---- Tab 3: Institutional network ------------------------------------------
  nav_panel(
    title = "Institutional network",
    icon  = icon("sitemap"),

    institutional_network_ui("inst_net")
  ),


  # ---- Tab 4: Documentation --------------------------------------------------
  nav_panel(
    title = "Documentation",
    icon  = icon("book-open"),

    div(class = "container-fluid py-3",
      documentation_ui("docs")
    )
  ),


  # ---- Navbar extras ---------------------------------------------------------
  nav_spacer(),

  nav_item(
    tags$a(
      href   = "https://twinpolitics.eu",
      target = "_blank",
      title  = "twinpolitics.eu",
      class  = "nav-link text-white-50",
      icon("arrow-up-right-from-square"),
      tags$span(class = "d-none d-xxl-inline ms-1", "twinpolitics.eu")
    )
  ),

  footer = tags$footer(
    style = "background-color:#e7ecf0; border-top:1px solid #cdd5db; padding:0.2rem 1.5rem 0.3rem; text-align:center;",
    tags$span(
      style = "font-size:0.68rem; color:#9aa4ae; line-height:1.3;",
      "This project has received funding from the European Research Council (ERC) ",
      "under the European Union's Horizon Europe research and innovation programme ",
      "(grant agreement No 101124903 – TwinPolitics – ERC-2023-CoG)."
    )
  )

) # end page_navbar