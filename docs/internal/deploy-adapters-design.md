# Deploy Adapters Design

静的サイトのデプロイアダプタ設計。

## 対応プラットフォーム

| Platform | Priority | 状態 | 生成ファイル |
|----------|----------|------|-------------|
| Cloudflare Pages | Primary | 実装済み | `_routes.json` |
| Deno Deploy | High | 設計中 | (なし or `deno.json`) |
| Vercel | Medium | 設計中 | `vercel.json` |
| GitHub Pages | Medium | 設計中 | `.nojekyll`, `CNAME` |
| Netlify | Low | 設計中 | `_headers`, `_redirects` |

## 共通インターフェース

```moonbit
/// デプロイアダプタの共通インターフェース
pub trait DeployAdapter {
  /// アダプタ名
  name(Self) -> String

  /// ビルド後のファイル生成
  generate(Self, BuildContext) -> Unit

  /// 必要な追加ファイルのリスト
  files(Self) -> Array[GeneratedFile]
}

pub struct GeneratedFile {
  path : String      // 出力パス (output_dir からの相対)
  content : String   // ファイル内容
}
```

## プラットフォーム別要件

### 1. Cloudflare Pages (実装済み)

**生成ファイル**: `_routes.json`

```json
{
  "version": 1,
  "include": ["/api/*"],      // Worker で処理
  "exclude": ["/*"]           // 静的ファイル
}
```

**特徴**:
- 静的ファイルは自動で配信
- 動的ルートは Worker fallback が必要
- `_routes.json` で静的/動的を制御

### 2. Deno Deploy

**生成ファイル**: 基本的になし（静的ファイルはそのまま配信）

**オプション**:
- `deno.json` - import map やタスク定義
- カスタムエントリーポイント `main.ts` for SSR

**特徴**:
- 静的ファイルは `Deno.serve` + `Deno.readFile` or deploy 設定
- 純粋な静的サイトならファイル配置のみ
- SSR が必要な場合は `main.ts` を生成

```typescript
// main.ts (SSR用、静的のみなら不要)
import { serveDir } from "jsr:@std/http/file-server";

Deno.serve((req) => serveDir(req, { fsRoot: "." }));
```

**SPA fallback**:
```typescript
// 404 時に index.html を返す
Deno.serve(async (req) => {
  const res = await serveDir(req, { fsRoot: "." });
  if (res.status === 404) {
    return new Response(await Deno.readFile("index.html"), {
      headers: { "content-type": "text/html" },
    });
  }
  return res;
});
```

### 3. Vercel

**生成ファイル**: `vercel.json`

```json
{
  "trailingSlash": true,
  "cleanUrls": true,
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "X-Frame-Options", "value": "DENY" }
      ]
    }
  ],
  "rewrites": [
    { "source": "/(.*)", "destination": "/index.html" }
  ]
}
```

**特徴**:
- `trailingSlash`: URL末尾の `/` 制御
- `cleanUrls`: `.html` 拡張子の省略
- `headers`: セキュリティヘッダー
- `rewrites`: SPA fallback

**推奨設定**:
```json
{
  "trailingSlash": true,
  "cleanUrls": true,
  "headers": [
    {
      "source": "/assets/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
      ]
    }
  ]
}
```

### 4. GitHub Pages

**生成ファイル**:
- `.nojekyll` - Jekyll 処理を無効化
- `CNAME` - カスタムドメイン（オプション）
- `404.html` - 既存で生成済み

**特徴**:
- `.nojekyll` は `_` で始まるファイルを配信するために必須
- SPA routing は `404.html` で対応
- カスタムドメインは `CNAME` ファイル

**.nojekyll**:
空ファイル。`_luna/` ディレクトリを配信するために必要。

**SPA fallback**:
GitHub Pages は 404 時に `404.html` を返す。
`404.html` に JS で SPA routing を実装：

```html
<!-- 404.html -->
<script>
  // Redirect to index with path info
  const path = location.pathname;
  if (path !== '/') {
    sessionStorage.setItem('redirectPath', path);
    location.href = '/';
  }
</script>
```

### 5. Netlify

**生成ファイル**:
- `_headers` - HTTP ヘッダー設定
- `_redirects` - リダイレクト/リライト設定
- または `netlify.toml`

**_headers**:
```
/assets/*
  Cache-Control: public, max-age=31536000, immutable

/*
  X-Frame-Options: DENY
  X-Content-Type-Options: nosniff
```

**_redirects**:
```
# SPA fallback
/*  /index.html  200

# または 404 fallback
/*  /404.html  404
```

**netlify.toml** (より詳細な設定):
```toml
[build]
  publish = "dist"

[[headers]]
  for = "/assets/*"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

## 実装方針

### Phase 1: DeployTarget 拡張

```moonbit
pub(all) enum DeployTarget {
  Static          // 汎用静的ファイル
  Cloudflare      // Cloudflare Pages
  Deno            // Deno Deploy
  Vercel          // Vercel
  GithubPages     // GitHub Pages
  Netlify         // Netlify
} derive(Eq, Show)
```

### Phase 2: Adapter モジュール構成

```
src/astra/adapters/
├── mod.mbt           # 共通インターフェース
├── cloudflare.mbt    # 既存の cloudflare.mbt を移動
├── deno.mbt
├── vercel.mbt
├── github_pages.mbt
└── netlify.mbt
```

### Phase 3: 設定オプション

```moonbit
pub(all) struct DeployConfig {
  target : DeployTarget
  // Platform-specific options
  custom_domain : String?          // GitHub Pages CNAME
  spa_fallback : Bool              // SPA routing fallback
  cache_assets : Bool              // Asset caching headers
  security_headers : Bool          // Security headers (X-Frame-Options, etc.)
}
```

## sol.config.json 設定例

```json
{
  "deploy": {
    "target": "github-pages",
    "customDomain": "docs.example.com",
    "spaFallback": true,
    "cacheAssets": true,
    "securityHeaders": true
  }
}
```

## 優先順位と実装順序

1. **GitHub Pages** - `.nojekyll` だけで基本動作、実装が簡単
2. **Vercel** - `vercel.json` 生成、機能豊富
3. **Netlify** - `_headers` + `_redirects` 生成
4. **Deno Deploy** - 基本は設定不要、SSR 時のみ `main.ts`

## 次のステップ

- [ ] `DeployTarget` enum を拡張
- [ ] `src/astra/adapters/` ディレクトリ作成
- [ ] GitHub Pages adapter 実装 (`.nojekyll` 生成)
- [ ] Vercel adapter 実装 (`vercel.json` 生成)
- [ ] Netlify adapter 実装 (`_headers`, `_redirects` 生成)
- [ ] Deno Deploy adapter 実装
- [ ] sol.config.json のパース対応
