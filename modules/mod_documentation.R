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
      
      # --- Download data ---
      card(
        class = "mb-4",
        card_header(tags$h5("Download data", class = "mb-0")),
        card_body(

          # Full project dataset
          div(class = "doc-download-row",
            div(class = "doc-download-info",
              tags$h6("Full project dataset"),
              tags$p(class = "text-muted small mb-0",
                "Catalogue of all ", textOutput(ns("n_total"), inline = TRUE), " ocean modelling projects.")
            ),
            div(class = "doc-download-btns",
              downloadButton(ns("download_full_csv"),   label = "CSV",   icon = icon("file-csv"),   class = "btn-sm btn-outline-primary me-1"),
              downloadButton(ns("download_full_excel"), label = "Excel", icon = icon("file-excel"), class = "btn-sm btn-outline-primary")
            )
          ),

          tags$hr(class = "my-1"),

          # Institution dictionary
          div(class = "doc-download-row",
            div(class = "doc-download-info",
              tags$h6("Institution dictionary"),
              tags$p(class = "text-muted small mb-0",
                "Lookup table of all institutions in the catalogue, including head institution, country, and website.")
            ),
            div(class = "doc-download-btns",
              downloadButton(ns("download_inst_csv"),   label = "CSV",   icon = icon("file-csv"),   class = "btn-sm btn-outline-primary me-1"),
              downloadButton(ns("download_inst_excel"), label = "Excel", icon = icon("file-excel"), class = "btn-sm btn-outline-primary")
            )
          ),

          tags$hr(class = "my-1"),

          # GitHub link
          div(class = "doc-download-row align-items-center",
            div(class = "doc-download-info",
              tags$h6("Source code"),
              tags$p(class = "text-muted small mb-0", "Data collection and processing code (Python).")
            ),
            div(class = "doc-download-btns",
              tags$a(
                href   = "#",   # placeholder: add GitHub URL here
                target = "_blank",
                class  = "btn btn-sm btn-outline-secondary",
                icon("github"), tags$span(class = "ms-1", "View on GitHub")
              )
            )
          )

        )
      ),
      
      # --- Methods section ---
      card(
        class = "mb-4",
        card_header(tags$h5("Methods", class = "mb-0")),
        card_body(
          
          p("The project database was compiled through a systematic literature search in The Lens,
            an open-access scholarly database, combining modelling-related terms
            (e.g. \"digital twin\", \"virtual representation\") with ocean-related terminology.
            The initial corpus of 5,016 publications was imported into Zotero for deduplication
            and screening, removing duplicates and non-primary literature. This process yielded 3,510
            unique entries, which formed the basis for the systematic identification of ocean modelling projects."),
          
          p("The literature entries were divided among eight researchers who systematically reviewed them to identify
            digital ocean model projects, entering relevant projects into a matrix guided by a joint codebook.
            Only projects meeting a defined set of inclusion criteria were documented: digital ocean models with a
            significant level of institutionalization and at least some potential to create public value,
            while weather-related models and purely private-benefit projects were excluded.
            For each project, the researchers coded a range of variables based on the literature entries and project websites.
            Variables such as public value and technical objectives were collected from the projects own descriptions, to stay
            close to their own presentation rather than interpretation by the researchers.")
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
            
          )
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
      ),
      
      # --- Funding ---
      card(
        class = "mb-4",
        card_header(tags$h5("Funding", class = "mb-0")),
        card_body(
          p("The TwinPolitics project has received funding from the European Research Council (ERC)
            under the European Union's Horizon Europe research and innovation programme
            (grant agreement No 101124903 – TwinPolitics – ERC-2023-CoG).")
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

    # ---- Full dataset downloads ----------------------------------------------
    output$download_full_csv <- downloadHandler(
      filename = function() paste0("twinpolitics_gcomp_", Sys.Date(), ".csv"),
      content  = function(file) write.csv(projects, file, row.names = FALSE)
    )

    output$download_full_excel <- downloadHandler(
      filename = function() paste0("twinpolitics_gcomp_", Sys.Date(), ".xlsx"),
      content  = function(file) writexl::write_xlsx(projects, file)
    )

    # ---- Institution dictionary downloads ------------------------------------
    output$download_inst_csv <- downloadHandler(
      filename = function() paste0("twinpolitics_gcomp_institutions_", Sys.Date(), ".csv"),
      content  = function(file) write.csv(institutions, file, row.names = FALSE)
    )

    output$download_inst_excel <- downloadHandler(
      filename = function() paste0("twinpolitics_gcomp_institutions_", Sys.Date(), ".xlsx"),
      content  = function(file) writexl::write_xlsx(institutions, file)
    )

  })
}
