# Hot Reload Common Design (sol / mars)

## Purpose

- Unify the "environment variable resolution", "client script generation", and "HTML injection" of Hot Reload
- Separate from `sol`-specific responsibilities (routing/SSR) so that `mars` alone can use the same contract

## Contract

- The following WebSocket message types are accepted:
  - `update`
  - `reload`
  - `full-reload`
  - `error`
- `update` / `reload` / `full-reload` execute `location.reload()`
- `error` outputs to the console

## API

`mizchi/sol/hot_reload`:

- `default_hmr_port(app_port, offset?)`
- `resolve_app_port(app_port~, default_port?)`
- `app_port_from_env(app_port_env?, default_port?)`
- `resolve_hmr_port(hmr_port~, app_port~, default_port?, offset?)`
- `hmr_port_from_env(hmr_port_env?, app_port_env?, default_port?, offset?)`
- `is_dev_mode(flag_env?, expected?)`
- `client_script_hostname(port)`
- `client_script_localhost(port)`
- `client_script_with_host_expr(port, host_expr)`
- `client_script_from_env(...)`
- `inject_script(html, script)`

## Usage on the sol Side

- runtime: `src/runtime_env_mount.mbt`
- router: `src/router/route_rendering.mbt`, `src/router/sol_routes.mbt`
- ssg dev server: `src/cli/ssg.mbt`

This eliminated duplication of script string definitions and port resolution logic.

## Application Strategy for the mars Side

- On the `mars` side, use `client_script_*` + `inject_script` wherever HTML is returned
- Dev detection can use a different env key, such as `is_dev_mode(flag_env="MARS_DEV")`
- In the future, this package will be extracted to `mizchi/hot_reload`, unifying `sol` and `mars` to reference the same module
