# ==============================================================================
# modules/mod_institutional_network.R — Institutional collaboration network
#
# Renders a visNetwork graph where nodes are head institutions and edges
# represent co-occurrence on the same project. Node size reflects degree.
# Nodes and edges are pre-computed in global.R as inst_nodes / inst_edges.
# ==============================================================================

# --- UI -----------------------------------------------------------------------
institutional_network_ui <- function(id) {
  ns <- NS(id)

  layout_sidebar(
    style = "height: calc(100vh - 120px);",

    sidebar = sidebar(
      width = 270,
      open  = "open",

      tags$h6("Institutional network", class = "fw-bold text-uppercase mb-3",
              style = "letter-spacing: 0.05em; font-size: 0.75rem;"),
      tags$p(class = "text-muted small",
             "Each node represents an institution (aggregated at the head unit level). Edges represent institutions that collaborate on the same project. Node size reflects the number of collaborations."),
      tags$p(class = "text-muted small",
             "Hover over a node to see institution details. Click to highlight its direct connections."),
    ),

    visNetwork::visNetworkOutput(ns("network"), height = "100%")
  )
}


# --- SERVER -------------------------------------------------------------------
institutional_network_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    # ── Nodes and edges are pre-computed in global.R as inst_nodes / inst_edges.
    # No per-session computation needed.

    # ── Render ─────────────────────────────────────────────────────────────
    output$network <- visNetwork::renderVisNetwork({
      visNetwork::visNetwork(inst_nodes, inst_edges) |>
        visNetwork::visNodes(
          shape = "dot",
          scaling = list(
            min   = 8,
            max   = 40,
            label = list(
              enabled      = TRUE,
              min          = 11,
              max          = 30,
              maxVisible   = 30,
              # Labels are hidden until the rendered font size exceeds this
              # threshold in pixels — zooming in progressively reveals them.
              drawThreshold = 6
            )
          ),
          font  = list(
            size        = 20,
            strokeWidth = 3,
            strokeColor = "#ffffff"   # white halo keeps labels readable on busy bg
          ),
          color = list(
            background = "#009EE3",   # TP_CYAN
            border     = "#006AB4",   # TP_BLUE
            highlight  = list(
              background = "#f1ae2a", # TP_GOLD
              border     = "#c8851d"  # TP_GOLD_DARK
            )
          )
        ) |>
        visNetwork::visEdges(
          color  = list(color = "rgba(150,150,150,0.18)", highlight = "#f1ae2a"),
          smooth = list(enabled = TRUE, type = "curvedCW", roundness = 0.1)
          # width comes from the edges$width column set above
        ) |>
        visNetwork::visOptions(
          highlightNearest = list(enabled = TRUE, degree = 1, hover = TRUE)
        ) |>
        visNetwork::visPhysics(
          solver           = "forceAtlas2Based",
          forceAtlas2Based = list(
            gravitationalConstant = -130,
            springLength          = 130,
            springConstant        = 0.05,
            avoidOverlap          = 0.3
          ),
          stabilization = list(iterations = 300)
        ) |>
        visNetwork::visEvents(
          stabilizationIterationsDone = "function() { this.setOptions({ physics: false }); }"
        ) |>
        visNetwork::visLayout(randomSeed = 42)
    })

  })
}
