# Hot Reload 共通設計（sol / mars）

## 目的

- Hot Reload の「環境変数解決」「クライアント script 生成」「HTML への注入」を共通化する
- `sol` 固有責務（ルーティング/SSR）と分離し、`mars` 単体でも同じ契約で使えるようにする

## 契約

- WebSocket message type は以下を受理する
  - `update`
  - `reload`
  - `full-reload`
  - `error`
- `update` / `reload` / `full-reload` は `location.reload()` を実行
- `error` はコンソールへ出力

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

## sol 側の利用

- runtime: `src/runtime_env_mount.mbt`
- router: `src/router/route_rendering.mbt`, `src/router/sol_routes.mbt`
- ssg dev server: `src/cli/ssg.mbt`

これにより script 文字列定義と port 解決ロジックの重複を削除した。

## mars 側への適用方針

- `mars` 側では HTML を返す箇所で `client_script_*` + `inject_script` を利用する
- dev 判定は `is_dev_mode(flag_env="MARS_DEV")` のように env key を差し替えて使える
- 将来的にはこの package を `mizchi/hot_reload` へ切り出し、`sol` と `mars` から同一モジュール参照に統一する
