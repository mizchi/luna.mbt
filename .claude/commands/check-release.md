# Release Pre-check

リリース前の確認を行います。すべてのチェックをパスしてからリリースしてください。

## 禁止事項

**AIは以下のコマンドを絶対に実行してはいけません：**
- `moon publish` - MoonBit パッケージの公開
- `npm publish` - NPM パッケージの公開

publish は人間が手動で実行する必要があります。

## チェックリスト

以下を順番に確認してください：

### 1. フォーマットチェック

```bash
moon info
moon fmt
```

変更があれば差分を確認し、コミットが必要か判断してください。

### 2. 型チェック

```bash
moon check
```

エラーがあれば修正してください。

### 3. テスト実行

```bash
just test
```

すべてのテストがパスすることを確認してください。

### 4. パッケージ情報確認

```bash
moon info
```

バージョン情報が正しいことを確認してください。

### 5. CHANGELOG 生成

```bash
just changelog
```

CHANGELOG.md が最新のコミットを反映しているか確認してください。

### 6. CI 確認

GitHub の CI ステータスを確認してください：

```bash
gh run list --limit 5
```

最新の run がパスしていることを確認してください。

### 7. Git 状態確認

```bash
git status
git log --oneline -5
```

コミット漏れがないことを確認してください。

## リリース手順（人間が実行）

チェックがすべてパスしたら、人間が以下を実行します：

1. **MoonBit パッケージ**
   ```bash
   moon publish
   ```

2. **NPM パッケージ**
   ```bash
   (cd js/luna && npm publish --access public)
   (cd js/sol && npm publish --access public)
   ```

3. **Git タグ**
   ```bash
   git tag vX.Y.Z
   git push origin --tags
   ```
