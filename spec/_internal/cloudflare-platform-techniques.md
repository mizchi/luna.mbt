# Cloudflare Platform 技術メモ

## 概要

Cloudflare ブログで紹介されている技術のうち、Sol に関連しそうなものをまとめる。

## 1. Vite Plugin v1.0 (Full-Stack on Workers)

**参考**: https://blog.cloudflare.com/full-stack-development-on-cloudflare-with-vite/

- Workers ランタイム内で Vite 開発サーバーを実行
- HMR 対応、開発体験の向上
- `wrangler.jsonc` で設定

```jsonc
{
  "name": "my-worker",
  "main": "./src/index.ts",
  "compatibility_date": "2025-12-11"
}
```

### Sol への適用可能性

- 現在の Sol 開発サーバーは独自実装
- Vite Plugin を使えば HMR がより安定する可能性
- ただし MoonBit→WASM のビルドチェーンとの統合が課題

## 2. Durable Objects + WebSocket

**参考**: https://developers.cloudflare.com/durable-objects/

- ステートフルなエッジコンピューティング
- WebSocket コネクション管理
- リアルタイム協調（チャット、共同編集など）

### Sol への適用可能性

- リアルタイム機能が必要な場合に有用
- Island コンポーネントとの組み合わせ
- 現時点では優先度低（SSG/ISR フォーカス）

## 3. Workers AI / Infire

**参考**: https://blog.cloudflare.com/workers-ai-inference/

- エッジでの AI 推論
- Speculative Decoding で 2-4x 高速化
- LLM、画像生成、埋め込みなど

### Sol への適用可能性

- AI 駆動のコンテンツ生成
- 検索の埋め込みベクトル生成
- 現時点では優先度低

## 4. Smart Placement

**参考**: https://developers.cloudflare.com/workers/configuration/smart-placement/

- Worker と D1/KV を自動的に近い場所に配置
- レイテンシ最適化

### Sol への適用可能性

- ISR キャッシュを D1 に保存する場合に有効
- 設定で有効化するだけなので導入コスト低

## 5. Astro / TanStack Start 対応

**参考**: https://blog.cloudflare.com/astro-tanstack-start-on-cloudflare/

- Astro: 静的サイト + Island Architecture
- TanStack Start: フルスタック React フレームワーク

### Sol への適用可能性

- Astro の Island パターンは Sol と類似
- 参考にできる設計パターンあり

## 優先度まとめ

| 技術 | 優先度 | 理由 |
|------|--------|------|
| Service-Binding Microfrontend | 高 | Fragment 応答と相性良い |
| Smart Placement | 中 | 導入コスト低、効果大 |
| Vite Plugin | 中 | 開発体験向上 |
| Durable Objects | 低 | SSG/ISR フォーカスでは不要 |
| Workers AI | 低 | 将来的な拡張 |

## 関連ドキュメント

- [Cloudflare Microfrontend 設計検討](./cloudflare-microfrontend-design.md)
