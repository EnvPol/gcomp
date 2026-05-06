# ==============================================================================
# modules/mod_documentation.R — Documentation tab (static content)
#
# To update content: edit the HTML below, or replace with
# includeMarkdown("docs/documentation.md") for file-based docs.
# ==============================================================================


# --- UI -----------------------------------------------------------------------
documentation_ui <- function(id) {
  ns <- NS(id)

  div(
    class = "row justify-content-center",

    div(
      class = "col-lg-8 col-md-10 col-12",

      # --- About section ---
      card(
        class = "mb-4",
        card_header(tags$h5("About the DTO Tracker", class = "mb-0")),
        card_body(

          p("[PROJECT DESCRIPTION]"),
          
          p("The project is
            part of the ", tags$a("TwinPolitics", href = "https://twinpolitics.eu",
                                  target = "_blank"), " project."),

          p("The dataset currently covers ", tags$strong(textOutput(ns("n_total"),
            inline = TRUE)), " projects and is updated as new projects are identified.")
        )
      ),

      # --- Variable descriptions ---
      card(
        class = "mb-4",
        card_header(tags$h5("Dataset variables", class = "mb-0")),
        card_body(

          tags$dl(
            class = "row",

            tags$dt(class = "col-sm-3", "Project name"),
            tags$dd(class = "col-sm-9", "[DESCRIPTION]"),

            tags$dt(class = "col-sm-3", "Public/private"),
            tags$dd(class = "col-sm-9", "[DESCRIPTION]"),

            tags$dt(class = "col-sm-3", "Operational"),
            tags$dd(class = "col-sm-9", "[DESCRIPTION]"),

            tags$dt(class = "col-sm-3", "Scope"),
            tags$dd(class = "col-sm-9", "[DESCRIPTION]"),

            tags$dt(class = "col-sm-3", "Open access"),
            tags$dd(class = "col-sm-9", "[DESCRIPTION]"),

            tags$dt(class = "col-sm-3", "Data types"),
            tags$dd(class = "col-sm-9", "[DESCRIPTION]"),

            tags$dt(class = "col-sm-3", "Funding sources"),
            tags$dd(class = "col-sm-9", "[DESCRIPTION]"),

            tags$dt(class = "col-sm-3", "Real-time data"),
            tags$dd(class = "col-sm-9", "[DESCRIPTION]"),

            tags$dt(class = "col-sm-3", "What-if modelling"),
            tags$dd(class = "col-sm-9", "[DESCRIPTION]"),

            tags$dt(class = "col-sm-3", "Decision support"),
            tags$dd(class = "col-sm-9", "[DESCRIPTION]"),

            tags$dt(class = "col-sm-3", "TK from IPLCs"),
            tags$dd(class = "col-sm-9", "[DESCRIPTION]"),

            tags$dt(class = "col-sm-3", "Institutions"),
            tags$dd(class = "col-sm-9", "[DESCRIPTION]")
          )
        )
      ),

      # --- Methods section ---
      card(
        class = "mb-4",
        card_header(tags$h5("Data collection methods", class = "mb-0")),
        card_body(
          p(em("Methodology description to be added."))
        )
      ),

      # --- Citation ---
      card(
        class = "mb-4",
        card_header(tags$h5("How to cite", class = "mb-0")),
        card_body(
          p(em("Citation information to be added.")),
          
          p("See also our ", tags$a("data insights paper", href = "https://doi.org", target = "_blank"), "in the Earth System Governance journal.")
        )
      ),

      # --- Contact ---
      card(
        class = "mb-4",
        card_header(tags$h5("Contact", class = "mb-0")),
        card_body(
          p("For questions about the DTO Tracker or to report corrections,
            please contact the project team via ",
            tags$a("twinpolitics.eu", href = "https://twinpolitics.eu",
                   target = "_blank"))
        )
      )

    ) # end col
  ) # end row
}


# --- SERVER -------------------------------------------------------------------
documentation_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    output$n_total <- renderText({
      nrow(projects)
    })

  })
}
