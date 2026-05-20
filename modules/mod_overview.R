# ==============================================================================
# modules/mod_overview.R -- Landing page (Overview tab)
# ==============================================================================


# --- UI -----------------------------------------------------------------------
overview_ui <- function(id) {
  ns <- NS(id)

  div(class = "overview-page",

    # ---- Hero section --------------------------------------------------------
    div(class = "overview-hero",
      div(class = "overview-hero-inner container-fluid",
        div(class = "row justify-content-center",
          div(class = "col-xl-7 col-lg-9 col-md-11 text-center",

            tags$p(class = "overview-eyebrow", "ERC TwinPolitics Project"),

            tags$h1(class = "overview-title",
              "Global Catalogue of Ocean Modelling Projects"
            ),

            div(class = "overview-cta mt-5",
              tags$a(
                href    = "#",
                class   = "btn btn-light btn-lg me-2 overview-btn-primary",
                onclick = "$(\"a[data-value='Data explorer']\").tab('show'); return false;",
                icon("chart-bar"),
                tags$span(class = "ms-2", "Explore the data")
              ),
              tags$a(
                href    = "#",
                class   = "btn btn-light btn-lg me-2 overview-btn-primary",
                onclick = "$(\"a[data-value='Institutional network']\").tab('show'); return false;",
                icon("sitemap"),
                tags$span(class = "ms-2", "Institutional network")
              ),
              tags$a(
                href    = "#",
                class   = "btn btn-light btn-lg overview-btn-primary",
                onclick = "$(\"a[data-value='Documentation']\").tab('show'); return false;",
                icon("book-open"),
                tags$span(class = "ms-2", "Documentation")
              )
            )

          )
        )
      )
    ), # end hero

    # ---- Stat strip ----------------------------------------------------------
    div(class = "overview-stat-strip",
      div(class = "container-fluid",
        div(class = "row justify-content-center g-0",

          div(class = "col-auto overview-stat-item",
            tags$span(class = "overview-stat-value",
                      textOutput(ns("n_projects"), inline = TRUE)),
            tags$span(class = "overview-stat-label", "projects")
          ),

          div(class = "col-auto overview-stat-sep", tags$span("|")),

          div(class = "col-auto overview-stat-item",
            tags$span(class = "overview-stat-value",
                      textOutput(ns("n_institutions"), inline = TRUE)),
            tags$span(class = "overview-stat-label", "institutions")
          ),

          div(class = "col-auto overview-stat-sep", tags$span("|")),

          div(class = "col-auto overview-stat-item",
            tags$span(class = "overview-stat-value",
                      textOutput(ns("n_countries"), inline = TRUE)),
            tags$span(class = "overview-stat-label", "countries")
          )

        )
      )
    ), # end stat strip

    # ---- Lead text + logo strip ----------------------------------------------
    div(class = "overview-lead-strip",
      div(
        tags$p(class = "overview-subtitle-light mb-1",
          "ERC TwinPolitics Global Catalogue of Ocean Modelling Projects (GCOMP)"
        ),
        tags$p(class = "overview-lead mb-2",
          "The Global Catalogue of Ocean Modelling Projects is a curated dataset designed to improve
          the visibility and accessibility of ocean modelling initiatives worldwide. It compiles
          institutionalized projects that virtually represent ocean-related activities and systematically
          records information on their institutional and national affiliations, public values,
          application domains, and decision-support functions. The catalogue supports research on
          the global ocean modelling landscape and helps identify application gaps, global disparities,
          and opportunities for project integration."
        ),
        tags$p(class = "overview-lead mb-2",
          HTML(paste0(
            "This dashboard provides users with data exploration, filtering, download, and visualization tools. ",
            "A full version of the data can be ",
            "<a href='#' onclick=\"$('a[data-value=&quot;Documentation&quot;]').tab('show'); return false;\">downloaded here</a>",
            ". Filtered data can be downloaded via the ",
            "<a href='#' onclick=\"$('a[data-value=&quot;Data explorer&quot;]').tab('show'); setTimeout(function(){ $('a[data-value=&quot;Project browser&quot;]').tab('show'); }, 150); return false;\">project browser</a>",
            "."
          ))
        ),
        tags$p(class = "overview-lead mb-2",
          "The catalogue is a collective research effort as part of the TwinPolitics project at
          the University of Vienna. The project is funded by the European Research Council (ERC) and led by Prof. Alice Vadrot."
        )
      ),
      div(class = "overview-lead-logos mt-4",
        tags$img(
          src   = "erc_eu_logo.jpg",
          alt   = "European Research Council",
          class = "overview-lead-logo overview-lead-logo-inst"
        ),
        tags$img(
          src   = "twinpolitics-logo-color.png",
          alt   = "TwinPolitics",
          class = "overview-lead-logo"
        ),
        tags$img(
          src   = "univie_logo.jpg",
          alt   = "Universität Wien",
          class = "overview-lead-logo overview-lead-logo-inst"
        )
      )
    ),

    # ---- Country map ---------------------------------------------------------
    div(class = "overview-map-section container-fluid py-4",
      country_map_ui("overview_map")
    )

  ) # end overview-page
}


# --- SERVER -------------------------------------------------------------------
overview_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    output$n_projects <- renderText({
      nrow(projects)
    })

    output$n_institutions <- renderText({
      projects |>
        pull(institution_ids) |>
        paste(collapse = ";") |>
        str_split(";") |>
        unlist() |>
        str_trim() |>
        (\(x) x[!is.na(x) & x != ""])() |>
        unique() |>
        length()
    })

    output$n_countries <- renderText({
      projects |>
        pull(countries_iso2) |>
        na.omit() |>
        strsplit(";") |>
        unlist() |>
        str_trim() |>
        (\(x) x[x != ""])() |>
        unique() |>
        length()
    })

  })
}
