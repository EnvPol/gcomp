# TwinPolitics GCOMP Dashboard

An interactive R Shiny dashboard cataloguing ocean modelling projects for the [TwinPolitics](https://twinpolitics.eu) project (ERC grant 101124903).

## Structure

```
├── app.R                    Entry point
├── global.R                 Packages, theme, data loading, shared globals
├── server.R                 Reactive logic and module calls
├── ui.R                     Top-level layout
├── data/                    Source Excel files and RDS cache
├── www/
│   └── custom.css           App-wide styles (TwinPolitics theme)
└── modules/
    ├── mod_overview.R              Landing page (hero, stats, map)
    ├── mod_summary_cards.R         Stat cards (updates with filters)
    ├── mod_project_browser.R       Searchable table with downloads
    ├── mod_country_map.R           Leaflet bubble map
    ├── mod_institutional_network.R visNetwork collaboration graph
    ├── mod_documentation.R         Static documentation tab
    └── explorer/
        ├── _viz_helpers.R          Shared palette, toggle UI, chart renderers
        ├── mod_public_values.R
        ├── mod_public_private.R
        ├── mod_operational.R
        ├── mod_open_access.R
        ├── mod_scope.R
        ├── mod_data_types.R
        ├── mod_data_collection.R
        ├── mod_tk.R
        ├── mod_user_interface.R
        ├── mod_real_time.R
        ├── mod_what_if.R
        └── mod_decision_support.R
```

## Data flow

1. **`global.R`** reads two Excel files (`projects.xlsx`, `institutions.xlsx`), cleans column names, and pre-computes shared objects (world centroids, network nodes/edges, country display names). All objects are cached to `.rds` so subsequent startups skip the expensive steps.

2. **`server.R`** exposes `filtered_projects`, a reactive that applies all sidebar filter inputs. Every module receives this reactive as its `data` argument and re-renders automatically when filters change.

3. **Explorer modules** (`modules/explorer/`) each render one variable card using the shared helpers in `_viz_helpers.R`. All cards follow the same structure: a three-button chart-type toggle in the header, and a Plotly output in the body.

## Adding a variable card

1. Create `modules/explorer/mod_<name>.R` with `<name>_ui()` and `<name>_server()`.
2. Source it in `global.R`.
3. Add a toggle button and `conditionalPanel` in `ui.R`.
4. Call `<name>_server("<name>", data = filtered_projects)` in `server.R`.

## Adding a filter

1. Add the widget in `ui.R` sidebar.
2. Add a filter step in `filtered_projects` in `server.R`.
3. Add an `updateSelectizeInput()` call in the `reset_filters` observer in `server.R`.
4. Add the choices to `filter_opts` in `global.R`.

## Updating the data

Replace `data/projects.xlsx` or `data/institutions.xlsx`. The app picks up changes on next startup and invalidates the `.rds` cache automatically. If columns are renamed, update `categorical_cols` and `filter_opts` in `global.R` and any module that references the column directly.

## Theme

Colours and fonts are defined in the `THEME SETTINGS` section of `global.R`. CSS overrides live in `www/custom.css`.
