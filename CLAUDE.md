# CLAUDE.md — TwinPolitics GCOMP Dashboard

Shiny dashboard for the TwinPolitics GCOMP (Global Comparison) project. Displays and filters a dataset of digital twin / government data projects worldwide. Built with R, Shiny, bslib, and Plotly.

---

## Tech stack

- **R** with dplyr/tidyverse conventions throughout
- **Shiny** (modular, using `moduleServer`)
- **bslib** (Bootstrap 5 theme, `page_navbar`, `card`, `layout_sidebar`)
- **Plotly** for all variable charts (donut / hbar / vbar toggle)
- **DT** for the project browser table
- **leaflet** for the country bubble map
- **visNetwork** for the institutional network graph
- **countrycode** for ISO2 <-> country name conversions
- **rnaturalearth** for world geometry / centroids
- **writexl** for Excel downloads

---

## Directory structure

```
to_github/
  app.R                         # entry point (sources global.R, ui.R, server.R)
  global.R                      # packages, theme, data loading, pre-computed globals, filter opts
  ui.R                          # top-level layout (page_navbar + sidebar + sub-tabs)
  server.R                      # filtered_projects reactive, filter reset, module calls
  data/
    projects.xlsx               # primary dataset (one row per project)
    institutions.xlsx           # institution lookup table
    *_cache.rds                 # auto-generated RDS caches (gitignored)
  modules/
    mod_overview.R              # landing page summary
    mod_summary_cards.R         # top-row KPI cards in the explorer
    mod_project_browser.R       # searchable DT table + CSV/Excel downloads
    mod_country_map.R           # leaflet bubble map (overview + click-to-filter)
    mod_institutional_network.R # visNetwork graph
    mod_documentation.R         # documentation tab
    explorer/
      _viz_helpers.R            # shared palette, toggle UI, count_* and render_* helpers
      mod_public_values.R
      mod_public_private.R
      mod_operational.R
      mod_open_access.R
      mod_scope.R
      mod_data_types.R
      mod_data_collection.R
      mod_tk.R
      mod_user_interface.R
      mod_real_time.R
      mod_what_if.R
      mod_decision_support.R
  www/
    custom.css
    favicon.png                 # square-padded crop of twinpolitics-logo-color.png
    twinpolitics-logo-color.png
    twinpolitics-logo-white.png
    univie_logo.jpg
    erc_eu_logo.jpg
```

---

## Data model

### projects.xlsx

One row per project. Column names are snake_cased at load time via `clean_col_name()` in global.R. Key columns:

| Column | Type | Notes |
|---|---|---|
| `project_name` | string | display name |
| `countries_iso2` | string | semicolon-separated ISO2 codes (e.g. `AT;DE`) |
| `country_display` | string | pre-computed readable names, added in global.R |
| `institutions_clean` | string | semicolon-separated institution names |
| `head_institutions` | string | semicolon-separated head unit names |
| `institution_ids` | string | semicolon-separated integer IDs linking to institutions.xlsx |
| `public_values_labels` | string | semicolon-separated (multi-value) |
| `data_types` | string | semicolon-separated (multi-value) |
| `data_collection_methods` | string | semicolon-separated (multi-value) |
| `public_private` | string | single-value categorical |
| `operational_status` | string | single-value categorical |
| `open_access` | string | single-value categorical |
| `scope` | string | single-value categorical |
| `tk_from_iplcs` | string | single-value categorical |
| `user_interface` | string | single-value categorical |
| `real_time_data` | string | single-value categorical |
| `what_if_modelling` | string | single-value categorical |
| `decision_support_function` | string | single-value categorical |

Single-value categoricals are lowercased and trimmed at load time.

### institutions.xlsx

Lookup table. Key columns after snake_casing:

| Column | Notes |
|---|---|
| `inst_id` | integer, joins to `institution_ids` in projects |
| `cleaned_institution_name` | display name |
| `head_unit` | parent organisation (used for network nodes) |
| `country_iso2` | single ISO2 code |
| `country_name` | pre-computed in global.R via countrycode |
| `homepage` | URL |

---

## Architecture

### Startup (global.R)

Everything in global.R runs once at startup and is shared across sessions. This includes:

- **RDS caching**: `projects.xlsx` and `institutions.xlsx` are read via `.load_cached()`, which writes `.rds` files next to the source and re-reads them if the cache is newer. Cache files are gitignored.
- **`world_centroids`**: pre-computed from rnaturalearth and cached as `data/world_centroids_cache.rds`. Used by `mod_country_map.R`.
- **`inst_nodes` / `inst_edges`**: pre-computed visNetwork objects for the institutional network. Computed from the full institutions + projects data. All intermediate objects are `rm()`-ed after.
- **`country_display` column**: added to `projects` by mapping `countries_iso2` through `countrycode` once, rather than per-render.
- **`filter_opts`**: named list of filter choices for every sidebar selectizeInput. Multi-value columns are split on `;` and deduplicated.

### Reactive data flow

```
projects (global)
    |
    v
filtered_projects (server.R reactive)   <-- all sidebar filters applied here
    |
    +-> summary_cards_server()
    +-> [all explorer variable modules]
    +-> project_browser_server()

projects (unfiltered) --> country_map_server()  (overview map always shows full data)
inst_nodes / inst_edges (global) --> institutional_network_server()
```

### Filter pattern (server.R)

```r
active <- function(x) !is.null(x) && length(x) > 0

# Single-value: direct %in% match
if (active(input$filter_scope)) {
  df <- df |> filter(scope %in% input$filter_scope)
}

# Multi-value: semicolon-split membership check
filter_multivalue <- function(df, col, selected) { ... }
if (active(input$filter_data_types)) {
  df <- filter_multivalue(df, "data_types", input$filter_data_types)
}

# Country: display name -> ISO2 conversion before matching
```

Sidebar filter order: Institution, Head institution, Country, then all other variables.

### Explorer variable modules

Each variable card follows an identical pattern:

```r
foo_ui <- function(id) {
  ns <- NS(id)
  card(
    card_header(
      tags$span("Label"),
      chart_type_toggle_ui(ns, default = "donut")  # or "hbar"
    ),
    card_body(plotly::plotlyOutput(ns("plot"), height = 340))
  )
}

foo_server <- function(id, data) {
  moduleServer(id, function(input, output, session) {
    counts    <- reactive({ count_categorical(data(), "col_name") })
    # or:     reactive({ count_multivalue(data(), "col_name", sep = ";") })
    chart_type <- chart_type_reactive(input)
    output$plot <- plotly::renderPlotly({
      render_categorical_viz(d = counts(), label_col = "col_name",
                             chart_type = chart_type(), empty_msg = "...")
    })
  })
}
```

Multi-value columns (data_types, data_collection_methods, public_values_labels) use `count_multivalue()` — totals exceed project count. Default chart type for these should be `"hbar"` since donut is misleading when counts overlap.

### Viz helpers (_viz_helpers.R)

- `CATEGORICAL_PALETTE`: 7-colour brand palette, assigned by descending count rank for consistency across chart types.
- `count_categorical(df, col)`: single-value column counts, sorted desc, sentence-cased.
- `count_multivalue(df, col, sep)`: splits on separator, flattens, counts, sentence-cased.
- `render_categorical_viz(d, label_col, chart_type, ...)`: returns a Plotly object for donut / hbar / vbar. All three share the same colour assignment logic.
- Chart type toggle is wired via a JS handler in ui.R that sets `input$chart_type` (namespaced) when a button is clicked.

---

## Visual / style decisions

### Colour palette

| Variable | Hex | Use |
|---|---|---|
| `TP_BLUE` | `#006AB4` | primary, links, chart colour 1 |
| `TP_GOLD` | `#f1ae2a` | warning, chart colour 2 |
| `TP_NAVY` | `#002F62` | headings, hover |
| `TP_GREEN` | `#12b878` | success, chart colour 4 |
| `TP_CYAN` | `#009EE3` | accent, chart colour 5 |
| `TP_CORAL` | `#db4b68` | danger, chart colour 6 |
| `TP_CHARCOAL` | `#363c42` | chart colour 7 |
| `TP_GREY_LIGHT` | `#e7ecf0` | secondary bg, footer, card headers |
| `THEME_BORDER` | `#cdd5db` | borders |

### Fonts

- Body: **Open Sans**, loaded via `@import` in `custom.css`. Passed to bslib as a plain string (not `font_google()`) to avoid network requests at startup.
- Heading: **Inter**, same approach.

### Favicon

`www/favicon.png`: the `twinpolitics-logo-color.png` padded to a square (813x813) with transparent background, then resized to 128x128. Generated with Pillow — do not use the raw logo as favicon (too wide, gets squished).

### Footer

Three-part flex row: logos grouped on the left (Universität Wien, then ERC/EU), funding text right-aligned on the right. Logos at 56px height with `mix-blend-mode: multiply` to blend white backgrounds into the `#e7ecf0` footer. Padding `0.5rem 1.5rem`.

---

## How to add things

### New variable card

1. Create `modules/explorer/mod_foo.R` following the pattern above.
2. `source()` it in global.R.
3. Add a toggle button in ui.R's `viz-toggle-bar` div: `tags$button(..., data-var = "foo", "Label")`.
4. Add a `conditionalPanel` in ui.R's `viz-grid` div.
5. Add `foo_server("foo", data = filtered_projects)` in server.R.
6. Add a sidebar filter in ui.R and a filter step in server.R's `filtered_projects` reactive.
7. Add the filter to the `updateSelectizeInput` block in server.R's reset handler.
8. Add the filter choices to `filter_opts` in global.R.

### New browser column

Edit the `select()` call in `display_data` inside `mod_project_browser.R`. Column indices in `columnDefs` are 0-based and may need updating if you insert before existing columns.

### New data column

Add it to `projects.xlsx`. If it's a categorical, add it to `categorical_cols` in global.R so it gets lowercased/trimmed. If it's multi-value (semicolon-separated), use `count_multivalue()` and `filter_multivalue()`.

---

## Key decisions / gotchas

- **Country filter uses display names in the UI but ISO2 internally.** The filter converts selected names back to ISO2 via `countrycode` before matching against `countries_iso2`. Do not match on display names directly.
- **`institutions_clean` vs `head_institutions`:** `institutions_clean` is the full individual institution name; `head_institutions` is the parent/umbrella organisation. The network graph runs on `head_institutions` (via `inst_id` -> `head_unit` lookup), not on `institutions_clean`.
- **Font loading:** bslib's `font_google()` makes a network call at startup that was causing slow cold starts. Fonts are now loaded via `@import` in `custom.css` and passed to `bs_theme()` as plain strings.
- **RDS caches are gitignored** (`data/*_cache.rds`). On a fresh clone, the first run reads from Excel and writes the caches. Subsequent runs use the caches unless the `.xlsx` is newer.
- **`world_centroids` cache is NOT gitignored** (it has no source file timestamp to compare against and is stable). It's stored as `data/world_centroids_cache.rds`.
- **Plotly `displayModeBar = FALSE`** on all charts — the mode bar was cluttering small cards.
- **Project browser height** is synced to the sidebar height via a JS snippet at the bottom of ui.R's `layout_sidebar`.
