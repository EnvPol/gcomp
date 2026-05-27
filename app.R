# ==============================================================================
# app.R — Entry point for the GCOMP Shiny dashboard
# ==============================================================================

source("global.R")
source("ui.R")
source("server.R")

shinyApp(ui = ui, server = server)