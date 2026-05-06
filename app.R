# ==============================================================================
# app.R — Entry point for the DTO Tracker Shiny dashboard
#
# This file simply loads the other files and starts the app.
# You should NEVER need to edit this file.
#
# To run the app:
#   1. Open RStudio and set working directory to the dto_dashboard/ folder
#   2. Click "Run App" in RStudio, or run: shiny::runApp()
# ==============================================================================

source("global.R")   # Libraries, data, theme, shared utilities
source("ui.R")       # User interface layout
source("server.R")   # Reactive server logic

shinyApp(ui = ui, server = server)
