# ==============================================================================
# global.R — Libraries, data loading, theme, and shared utilities
#
# This file runs ONCE when the app starts. It is the right place for:
#   - library() calls
#   - Data loading and cleaning
#   - Theme / colour settings
#   - Shared helper functions
#   - source() calls for module files
#
# KEY LOCATIONS FOR COMMON CHANGES:
#   Colours / fonts     -> "THEME SETTINGS" section below
#   Data file paths     -> "DATA LOADING" section below
#   Add new module      -> add source() call in "LOAD MODULES" section
#   Add new filter      -> add entry in "FILTER OPTIONS" section
# ==============================================================================


# ------------------------------------------------------------------------------
# PACKAGES
# ------------------------------------------------------------------------------

library(shiny)
library(bslib)
library(dplyr)
library(readxl)
library(DT)
library(ggplot2)
library(plotly)
library(stringr)
library(purrr)
library(tidyr)
library(leaflet)
library(countrycode)
library(rnaturalearth)
library(rnaturalearthdata)
library(sf)
library(writexl)


# ------------------------------------------------------------------------------
# LOAD MODULES
# ------------------------------------------------------------------------------

source("modules/mod_overview.R")
source("modules/mod_summary_cards.R")
source("modules/mod_project_browser.R")
source("modules/mod_documentation.R")

source("modules/mod_institutional_network.R")
source("modules/mod_country_map.R")

source("modules/explorer/_viz_helpers.R")

source("modules/explorer/mod_public_values.R")
source("modules/explorer/mod_public_private.R")
source("modules/explorer/mod_operational.R")
source("modules/explorer/mod_open_access.R")
source("modules/explorer/mod_scope.R")
source("modules/explorer/mod_data_types.R")
source("modules/explorer/mod_data_collection.R")
source("modules/explorer/mod_tk.R")
source("modules/explorer/mod_user_interface.R")
source("modules/explorer/mod_real_time.R")
source("modules/explorer/mod_what_if.R")
source("modules/explorer/mod_decision_support.R")


# ==============================================================================
# THEME SETTINGS (TwinPolitics colour palette)
# ==============================================================================

TP_BLUE_LIGHT  <- "#00BADE"
TP_CYAN        <- "#009EE3"
TP_BLUE_MID    <- "#007BC3"
TP_BLUE        <- "#006AB4"
TP_NAVY        <- "#002F62"

TP_GOLD        <- "#f1ae2a"
TP_GREEN       <- "#12b878"
TP_CORAL       <- "#db4b68"
TP_GOLD_DARK   <- "#c8851d"

TP_WHITE       <- "#ffffff"
TP_CHARCOAL    <- "#363c42"
TP_GREY_LIGHT  <- "#e7ecf0"
TP_DARK        <- "#212326"
TP_NEAR_BLACK  <- "#141617"

THEME_PRIMARY    <- TP_BLUE
THEME_SECONDARY  <- TP_GREY_LIGHT
THEME_ACCENT     <- TP_CYAN
THEME_TEXT       <- TP_DARK
THEME_HEADING    <- TP_NAVY
THEME_LIGHT      <- TP_WHITE
THEME_BORDER     <- "#cdd5db"

THEME_FONT_BODY    <- "Open Sans"
THEME_FONT_HEADING <- "Inter"

# font_google() makes an HTTP request to Google on every app load to discover
# the font URL. Since custom.css already loads both fonts via @import, we pass
# plain strings instead — bslib sets the CSS variables without any network call.
app_theme <- bs_theme(
  version      = 5,
  primary      = THEME_PRIMARY,
  secondary    = THEME_SECONDARY,
  success      = TP_GREEN,
  info         = TP_CYAN,
  warning      = TP_GOLD,
  danger       = TP_CORAL,
  fg           = THEME_TEXT,
  bg           = THEME_LIGHT,

  base_font    = THEME_FONT_BODY,
  heading_font = THEME_FONT_HEADING,

  "navbar-bg"          = TP_WHITE,
  "navbar-fg"          = TP_NEAR_BLACK,
  "navbar-brand-color" = TP_NAVY,

  "card-border-color"  = THEME_BORDER,
  "card-bg"            = THEME_LIGHT,
  "card-cap-bg"        = THEME_SECONDARY,

  "link-color"         = TP_BLUE,
  "link-hover-color"   = TP_NAVY,

  "border-radius"      = "6px"
)


# ==============================================================================
# DATA LOADING
# RDS caching: on first run, reads Excel and saves a .rds sidecar file.
# On subsequent runs, loads the .rds directly (10-50x faster than read_excel).
# The cache is invalidated automatically whenever the source .xlsx is newer.
# ==============================================================================

.load_cached <- function(xlsx_path, rds_path) {
  if (file.exists(rds_path) &&
      file.mtime(rds_path) >= file.mtime(xlsx_path)) {
    readRDS(rds_path)
  } else {
    df <- read_excel(xlsx_path)
    saveRDS(df, rds_path)
    df
  }
}

projects_raw     <- .load_cached("data/projects.xlsx",      "data/projects_cache.rds")
institutions_raw <- .load_cached("data/institutions.xlsx",  "data/institutions_cache.rds")


# ==============================================================================
# DATA CLEANING
# ==============================================================================

clean_col_name <- function(x) {
  x |>
    tolower() |>
    str_replace_all("[^a-z0-9]+", "_") |>
    str_remove_all("_+$") |>
    str_remove_all("^_+")
}

projects <- projects_raw |>
  rename_with(clean_col_name)

institutions <- institutions_raw |>
  rename_with(clean_col_name)

categorical_cols <- c(
  "public_private", "operational_status", "open_access", "scope",
  "real_time_data", "what_if_modelling", "decision_support_function",
  "user_interface", "tk_from_iplcs"
)

cols_to_clean <- intersect(categorical_cols, names(projects))

projects <- projects |>
  mutate(across(all_of(cols_to_clean), ~ str_trim(tolower(.x))))

institutions <- institutions |>
  mutate(
    country_name = suppressWarnings(
      countrycode::countrycode(country_iso2,
                               origin      = "iso2c",
                               destination = "country.name",
                               warn        = FALSE)
    )
  )


# ==============================================================================
# PRE-COMPUTED COUNTRY DISPLAY NAMES
# Converts each project's semicolon-separated ISO2 codes to readable country
# names once at startup. mod_project_browser.R uses this column directly
# instead of running countrycode() on every session and filter change.
# ==============================================================================

.iso2_to_display <- function(x) {
  if (is.na(x) || !nzchar(x)) return(NA_character_)
  codes <- str_trim(str_split(x, ";")[[1]])
  names <- suppressWarnings(
    countrycode::countrycode(codes, "iso2c", "country.name", warn = FALSE)
  )
  paste(na.omit(names), collapse = "; ")
}

projects <- projects |>
  mutate(country_display = sapply(countries_iso2, .iso2_to_display))


# ==============================================================================
# WORLD CENTROIDS (for country map)
# Computed once and cached as .rds. After the first run, sf / rnaturalearth
# are not needed for the map — only the cached tibble is loaded.
# ==============================================================================

.centroids_rds <- "data/world_centroids_cache.rds"

if (file.exists(.centroids_rds)) {
  world_centroids <- readRDS(.centroids_rds)
} else {
  .world <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")
  suppressWarnings({
    .cent <- sf::st_centroid(sf::st_geometry(.world))
  })
  .coords <- sf::st_coordinates(.cent)
  world_centroids <- tibble::tibble(
    iso_a2 = .world$iso_a2,
    lng    = .coords[, 1],
    lat    = .coords[, 2]
  ) |>
    filter(!is.na(iso_a2), iso_a2 != "-99")
  saveRDS(world_centroids, .centroids_rds)
  rm(.world, .cent, .coords)
}


# ==============================================================================
# INSTITUTIONAL NETWORK — pre-computed nodes and edges
# This computation ran per-session inside mod_institutional_network.R.
# Moving it here means it runs once at startup and all sessions reuse the result.
# ==============================================================================

# 1. Lookup: inst_id -> head_unit
.inst_to_head <- institutions |>
  filter(!is.na(head_unit), !is.na(inst_id)) |>
  select(inst_id, head_unit)

# 2. Base nodes: one row per head_unit
.nodes_raw <- institutions |>
  filter(!is.na(head_unit)) |>
  group_by(head_unit) |>
  summarise(
    country = first(na.omit(country_name)),
    .groups = "drop"
  ) |>
  mutate(id = head_unit) |>
  rename(label = head_unit) |>
  select(id, label, country)

# 3. Per-head-unit tooltip links (one named <a> per sub-institution)
.inst_links <- institutions |>
  filter(!is.na(head_unit), !is.na(homepage), nzchar(homepage)) |>
  distinct(head_unit, cleaned_institution_name, homepage) |>
  group_by(head_unit) |>
  summarise(
    links_html = paste(
      paste0(
        "<a href='", homepage, "' target='_blank' ",
        "title='", htmltools::htmlEscape(cleaned_institution_name), "' ",
        "style='color:#006AB4; text-decoration:none; display:block; ",
        "white-space:nowrap; overflow:hidden; text-overflow:ellipsis;'>",
        htmltools::htmlEscape(cleaned_institution_name), "</a>"
      ),
      collapse = ""
    ),
    .groups = "drop"
  )

.nodes_raw <- .nodes_raw |>
  left_join(.inst_links, by = c("id" = "head_unit")) |>
  mutate(
    links_html = coalesce(
      links_html,
      "<i style='color:#9aa4ae;'>No homepage available</i>"
    )
  )

# 4. Edges: pairwise head-unit co-occurrences across projects
.inst_edges <- projects |>
  filter(!is.na(institution_ids)) |>
  mutate(
    head_units = map(institution_ids, function(id_str) {
      ids   <- as.integer(str_trim(str_split(id_str, ";")[[1]]))
      heads <- .inst_to_head |>
        filter(inst_id %in% ids) |>
        pull(head_unit)
      unique(na.omit(heads))
    })
  ) |>
  mutate(
    pairs = map(head_units, function(hu) {
      if (length(hu) < 2) return(tibble(from = character(), to = character()))
      combn(hu, 2, simplify = FALSE) |>
        map_dfr(~ tibble(from = .x[1], to = .x[2]))
    })
  ) |>
  select(pairs) |>
  unnest(pairs) |>
  mutate(
    from_norm = pmin(from, to),
    to_norm   = pmax(from, to)
  ) |>
  select(-from, -to) |>
  rename(from = from_norm, to = to_norm) |>
  count(from, to, name = "weight") |>
  filter(from != to) |>
  mutate(width = pmax(0.5, pmin(1 + log(weight) * 1.2, 6)))

# 5. Degree and final nodes with tooltips
.degree_tbl <- bind_rows(
  .inst_edges |> select(id = from),
  .inst_edges |> select(id = to)
) |>
  count(id, name = "degree")

inst_nodes <- .nodes_raw |>
  left_join(.degree_tbl, by = "id") |>
  filter(!is.na(degree) & degree > 0) |>
  mutate(
    value = degree,
    title = paste0(
      "<div style='",
        "font-family:inherit;",
        "width:280px;",
        "padding:8px 10px;",
        "box-sizing:border-box;",
        "word-wrap:break-word;",
        "overflow-wrap:break-word;",
        "white-space:normal;",
      "'>",
      "<div style='",
        "font-weight:600;",
        "color:#002F62;",
        "margin-bottom:2px;",
        "line-height:1.3;",
        "white-space:normal;",
        "word-break:break-word;",
      "'>", htmltools::htmlEscape(label), "</div>",
      "<div style='",
        "font-size:0.82em;",
        "color:#6c757d;",
        "margin-bottom:6px;",
      "'>", htmltools::htmlEscape(coalesce(country, "—")), "</div>",
      "<div style='font-size:0.82em;'>", links_html, "</div>",
      "</div>"
    )
  )

inst_edges <- .inst_edges

# Clean up temporary objects
rm(.inst_to_head, .nodes_raw, .inst_links, .inst_edges, .degree_tbl)


# ==============================================================================
# FILTER OPTIONS
# ==============================================================================

filter_choices <- function(col_name) {
  sort(unique(na.omit(projects[[col_name]])))
}

filter_opts <- list(
  scope                       = filter_choices("scope"),
  public_private              = filter_choices("public_private"),
  operational_status          = filter_choices("operational_status"),
  open_access                 = filter_choices("open_access"),
  real_time_data              = filter_choices("real_time_data"),
  what_if_modelling           = filter_choices("what_if_modelling"),
  decision_support_function   = filter_choices("decision_support_function"),
  user_interface              = filter_choices("user_interface"),
  tk_from_iplcs               = filter_choices("tk_from_iplcs"),
  public_values_labels        = sort(unique(na.omit(
    str_trim(unlist(str_split(na.omit(projects$public_values_labels), ";")))
  ))),
  data_types                  = sort(unique(na.omit(
    str_trim(unlist(str_split(na.omit(projects$data_types), ";")))
  ))),
  data_collection_methods     = sort(unique(na.omit(
    str_trim(unlist(str_split(na.omit(projects$data_collection_methods), ";")))
  ))),
  institutions                = sort(unique(na.omit(
    str_trim(unlist(str_split(na.omit(projects$institutions_clean), ";")))
  ))),
  head_institutions           = sort(unique(na.omit(
    str_trim(unlist(str_split(na.omit(projects$head_institutions), ";")))
  ))),
  country                     = {
    iso2_codes <- projects$countries_iso2 |>
      na.omit() |>
      strsplit(";\\s*") |>
      unlist() |>
      str_trim() |>
      unique()
    names_vec <- suppressWarnings(
      countrycode::countrycode(iso2_codes, "iso2c", "country.name", warn = FALSE)
    )
    sort(unique(na.omit(names_vec)))
  }
)
