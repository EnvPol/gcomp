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
        card_header(tags$h5("About GCOMP", class = "mb-0")),
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
            
            # --- Header ---
            tags$dt(class = "col-sm-3", "Variable"),
            tags$dt(class = "col-sm-3", "Response categories"),
            tags$dt(class = "col-sm-6", "Explanation"),
            tags$hr(class = "mb-2"),
            
            # --- Rows ---
            tags$dt(class = "col-sm-3", "Project name"),
            tags$dd(class = "col-sm-3", "open"),
            tags$dd(class = "col-sm-6", "Project name"),
            
            tags$dt(class = "col-sm-3", "Institutions"),
            tags$dd(class = "col-sm-3", "open"),
            tags$dd(class = "col-sm-6", "Name(s) of all institution(s) or organization(s) that develop(s) or host(s) the project"),
            
            tags$dt(class = "col-sm-3", "Head institutions"),
            tags$dd(class = "col-sm-3", "open"),
            tags$dd(class = "col-sm-6", "Name(s) of all head institution(s) or organization(s)"),
            
            tags$dt(class = "col-sm-3", "Countries"),
            tags$dd(class = "col-sm-3", "Country name (browser)/ISO2 values (raw data)"),
            tags$dd(class = "col-sm-6", "Country names/ISO2 codes of all affiliation countries linked to the institutions or organizations"),
            
            tags$dt(class = "col-sm-3", "Public value framing"),
            tags$dd(class = "col-sm-3", "open"),
            tags$dd(class = "col-sm-6", "A project’s self-description of the public value it creates; includes several sentences taken from each project’s homepage or other documents."),
            
            tags$dt(class = "col-sm-3", "Public value labels"),
            tags$dd(class = "col-sm-3", "'basic research' OR 'better decision-making' OR ... [truncated for brevity]"),
            tags$dd(class = "col-sm-6", "Categories of public value created by the project; assigned by researchers based on the project’s self-description"),
            
            tags$dt(class = "col-sm-3", "Technical objectives"),
            tags$dd(class = "col-sm-3", "open"),
            tags$dd(class = "col-sm-6", "A project's self-described technical objectives, enabling it to create public value"),
            
            tags$dt(class = "col-sm-3", "Public/private funding"),
            tags$dd(class = "col-sm-3", "public OR private"),
            tags$dd(class = "col-sm-6", "Whether the project is primarily publicly or privately funded"),
            
            tags$dt(class = "col-sm-3", "Funding sources"),
            tags$dd(class = "col-sm-3", "open"),
            tags$dd(class = "col-sm-6", "Name(s) of the funder(s)"),
            
            tags$dt(class = "col-sm-3", "Operational status"),
            tags$dd(class = "col-sm-3", "development OR pilot OR operational"),
            tags$dd(class = "col-sm-6", "The development and application stage of a project"),
            
            tags$dt(class = "col-sm-3", "Open access"),
            tags$dd(class = "col-sm-3", "fully OR partially OR no"),
            tags$dd(class = "col-sm-6", "Whether a project's models, data, methods, and results are freely available to the public without financial, legal, or technical barriers"),
            
            tags$dt(class = "col-sm-3", "Scope"),
            tags$dd(class = "col-sm-3", "global OR regional OR national OR local"),
            tags$dd(class = "col-sm-6", "The general scope of processes or areas represented by the modelling project"),
            
            tags$dt(class = "col-sm-3", "Geographic coverage"),
            tags$dd(class = "col-sm-3", "open"),
            tags$dd(class = "col-sm-6", "Which self-described geographic areas are represented by the modelling project"),
            
            tags$dt(class = "col-sm-3", "Data types"),
            tags$dd(class = "col-sm-3", "oceanographic OR social OR biological OR spatial OR multimedia"),
            tags$dd(class = "col-sm-6", "Indicative types of data used in each project"),
            
            tags$dt(class = "col-sm-3", "Data collection methods"),
            tags$dd(class = "col-sm-3", "citizen science OR remote sensing OR in-situ OR desk research"),
            tags$dd(class = "col-sm-6", "Indicative types of data collection methods in each project"),
            
            tags$dt(class = "col-sm-3", "TK from IPLCs"),
            tags$dd(class = "col-sm-3", "yes OR no"),
            tags$dd(class = "col-sm-6", "Whether any knowledge or information from Indigenous People and/or local communities is integrated or used in the project"),
            
            tags$dt(class = "col-sm-3", "User interface"),
            tags$dd(class = "col-sm-3", "yes OR no"),
            tags$dd(class = "col-sm-6", "Whether the project (aims to) have an interactive user interface"),
            
            tags$dt(class = "col-sm-3", "Real-time data"),
            tags$dd(class = "col-sm-3", "yes OR no OR periodic"),
            tags$dd(class = "col-sm-6", "Whether the project (aims to) involve a real-time or close to-real time update of data"),
            
            tags$dt(class = "col-sm-3", "What-if modelling"),
            tags$dd(class = "col-sm-3", "yes OR no"),
            tags$dd(class = "col-sm-6", "Whether the project (aims to) incorporate scenario testing"),
            
            tags$dt(class = "col-sm-3", "Decision support"),
            tags$dd(class = "col-sm-3", "human OR automated OR no"),
            tags$dd(class = "col-sm-6", "Whether the project (aims to) support human or 'human-in-the-loop' decision making, fully automated decision making, or no decision making"),
            
            tags$dt(class = "col-sm-3", "Homepages"),
            tags$dd(class = "col-sm-3", "open"),
            tags$dd(class = "col-sm-6", "Project homepage"),
            
            tags$dt(class = "col-sm-3", "Other relevant sources"),
            tags$dd(class = "col-sm-3", "open"),
            tags$dd(class = "col-sm-6", "Other informational sources on the project"),
            
            tags$dt(class = "col-sm-3", "Notes"),
            tags$dd(class = "col-sm-3", "open"),
            tags$dd(class = "col-sm-6", "Any qualifying comments")
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
          p("For questions about the Global Catalogue of Ocean Modelling Projects or to report corrections,
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
