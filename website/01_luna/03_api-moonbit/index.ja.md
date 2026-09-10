---
title: MoonBit API
---

# MoonBit API リファレンス

インポートするパッケージごとに 1 ページずつ、計 4 ページです。掲載しているシグネチャはすべて、このリポジトリの生成済み `.mbti` と突き合わせて確認しています。Client DOM ページはさらに一歩進んでいて、`.mbt.md` なのでサンプルコードが `moon check` でコンパイルされ `moon test` で実行されます。

| ページ | パッケージ | エイリアス |
|--------|-----------|-----------|
| [Signals](./signals) | `mizchi/luna/js/resource` | `@resource` |
| [Islands](./islands) | `mizchi/sol` + `mizchi/luna` | `@sol`, `@luna` |
| [Render](./render) | `mizchi/luna/dom/static` | `@server_dom` |
| [Client DOM](./client-dom) | `mizchi/luna/dom` | `@element` |

## リアクティブプリミティブ

| 関数 | 説明 |
|------|------|
| [`signal`](./signals#signal) | リアクティブな Signal を作成 |
| [`effect`](./signals#effect) | 副作用を作成 |
| [`memo` / `computed`](./signals#memo-computed) | キャッシュ付き派生値(同一性カットオフ) |
| [`memo_eq`](./signals#memo-eq) | キャッシュ付き派生値(`Eq` カットオフ) |
| [`batch`](./signals#batch) | 更新をまとめる |
| [`untracked`](./signals#untracked) | 追跡せずに実行 |
| [`on_cleanup`](./signals#on-cleanup) | effect のクリーンアップを登録 |
| [購読 API](./signals) | `on` / `watch` / `previous` |
| [コンビネータ](./signals) | `combine2/3/4` / `all` / `any` / `switch_` / `select` / `flatten` |
| [オーナー / スコープ](./signals) | `create_root` / `get_owner` / `on_mount` |
| [Context API](./signals#context-api) | `create_context` / `provide` / `use_context` |
| [Resource API](./signals#resource-api) | loading / error 付きの非同期状態 |

## Island レンダリング

| 関数 | 説明 |
|------|------|
| [`@sol.island`](./islands) | 型付き `ComponentRef` から Island を作成(推奨) |
| [`@sol.island_raw`](./islands) | 生の文字列から Island を作成(低レベル) |
| [`@luna.wc_island`](./islands) | Web Component Island(低レベル) |
| [`Trigger`](./islands#trigger) | ハイドレーションのタイミング |

## クライアントサイドレンダリング

| 関数 | 説明 |
|------|------|
| [`render_to`](./client-dom#ツリーをマウントする) | 要素を空にしてノードをマウント |
| [`mount_to`](./client-dom#ツリーをマウントする) | 要素にノードを追加 |
| [`events`](./client-dom#イベントハンドラ) | 型付きイベントハンドラを要素にチェーン |
| [`portal_to_body` / `portal_to`](./client-dom#ポータル) | children をドキュメントの別の場所へ描画 |
| [JS との違い](./client-dom#javascript-api-との違い) | JavaScript API が受け付けて MoonBit では不要な形 |

## サーバーサイドレンダリング

| 関数 | 説明 |
|------|------|
| [`render`](./render#render) | ノードツリーを HTML 文字列に描画 |
| [`render_document`](./render#render-document) | DOCTYPE 付きで描画 |
| [`render_with_preloads`](./render#render-with-preloads) | 描画 + Island の preload URL |
| [`document`](./render#document) | ドキュメント全体のノードを作成 |
| [`div` / `p` / `span` …](./render) | HTML 要素ヘルパー |
| [`text`](./render#text) | テキストノード(エスケープ済み) |
| [`attr`](./render#attr) | 属性値 |
| [ノード型](./render) | `Node[E, A]` / `Attr[E, A]` / `render_to_string` |

## セクション

- [Signals](./signals) — リアクティブな状態管理
- [Islands](./islands) — サーバーサイド Island 描画とハイドレーショントリガー
- [Render](./render) — SSR 要素ヘルパーとレンダラ
- [Client DOM](./client-dom) — ブラウザでのマウント・イベント・ポータル・context
