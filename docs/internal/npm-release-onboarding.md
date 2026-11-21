# npm Release

How the `@luna_ui/*` npm packages are released: bump the version, generate
the changelog section, commit, tag, push the tag.
`.github/workflows/publish.yml` publishes on the tag push through npm Trusted
Publishing (OIDC) and creates the GitHub Release. There is no release PR, no
GitHub App and no `NPM_TOKEN`.

Scope: 8 packages, each with its own version.

| npm package            | directory       | tag                            |
| ---------------------- | --------------- | ------------------------------ |
| `@luna_ui/luna`        | `js/luna`       | `luna-npm-v<version>`          |
| `@luna_ui/sol`         | `js/sol`        | `sol-npm-v<version>`           |
| `@luna_ui/astra`       | `js/astra`      | `astra-npm-v<version>`         |
| `@luna_ui/components`  | `js/components` | `components-npm-v<version>`    |
| `@luna_ui/luna-loader` | `js/loader`     | `luna-loader-npm-v<version>`   |
| `@luna_ui/stella`      | `js/stella`     | `stella-npm-v<version>`        |
| `@luna_ui/testing`     | `js/testing`    | `testing-npm-v<version>`       |
| `@luna_ui/wcr`         | `js/wcr`        | `wcr-npm-v<version>`           |

The tag is `<component>-npm-v<version>`, where `<component>` is the npm name
without the `@luna_ui/` scope. The `-npm` infix keeps these tags apart from
the mooncakes tags (`luna-v0.26.0`, `sol-v0.24.0`, ...), which never publish
to npm.

(`@luna_ui/wcssr` is `private: true`; the workflow refuses its tag. To release
it, remove `"private": true` from `js/wcssr/package.json`, add `js/wcssr` to
`publicPackages` in `tests/integration/npm-workspace.test.js` and to
`just changelog-npm`, then do the one-time setup below for it.)

The mooncakes packages (`mizchi/{luna,luna_components,sol,sol_adapter_cloudflare,sol_adapter_node,astra}`)
stay on the `luna/scripts/vup.mjs` flow and are out of scope here.

---

## Releasing a package

Example: `@luna_ui/luna` 0.24.3. Work on an up-to-date `main`.

```sh
# 1. bump the version (npm versions are independent of moon.mod)
(cd js/luna && npm version 0.24.3 --no-git-tag-version)

# 2. add the "## 0.24.3 (date)" section to js/luna/CHANGELOG.md, then read it
#    against `git log luna-npm-v0.24.2..HEAD -- js/luna luna` and edit if needed
just changelog-npm luna 0.24.3

# 3. commit
git commit -am "chore(release): @luna_ui/luna 0.24.3"

# 4. tag and push (lightweight tags must be named explicitly)
git tag luna-npm-v0.24.3
git push origin main luna-npm-v0.24.3

# 5. watch the publish
gh run watch --exit-status "$(gh run list --workflow=publish.yml --limit 1 --json databaseId --jq '.[0].databaseId')"
```

Notes:

- **Push at most three tags per `git push`.** GitHub creates no push event
  when more than three tags are pushed at once, so nothing would be published.
- **Release dependencies first.** `@luna_ui/stella` depends on `@luna_ui/wcr`
  and `@luna_ui/testing` on `@luna_ui/luna` through `workspace:^`; pnpm writes
  the dependency's current version into the tarball. Push the dependency's
  tag, wait for its run to finish, then push the dependent's tag.
- Several packages can share one release commit: bump and run
  `just changelog-npm` for each, commit once, then create one tag per package.
- A version containing `-` (`0.25.0-rc.0`, tag `luna-npm-v0.25.0-rc.0`) is
  published under the `next` dist-tag and its GitHub Release is marked as a
  pre-release.
- The workflow fails before building when the tag's version differs from
  `js/<dir>/package.json`. Fix the version, commit, and recreate the tag:
  `git tag -d <tag> && git push origin :<tag>`, then tag and push again.
  The same applies to any failure before `npm publish`.
- A version that reached npm cannot be published again. If a later step
  failed (for example the GitHub Release), create the release by hand with
  `gh release create <tag> --notes-file <file>`; to change the package, bump
  the patch version.
- The registry lags about a minute behind a successful run; `npm view
  @luna_ui/<component>@<version>` can be 404 during that time. Do not
  recreate the tag.
- With the tag ruleset below, an admin push prints "Bypassed rule violations
  for refs/tags/...". That is success. Only a `GH013` rejection is a failure.

### What `just changelog-npm` runs

```sh
GITHUB_TOKEN=$(gh auth token) npx -y git-cliff@2.14.2 --unreleased \
  --tag luna-npm-v0.24.3 \
  --tag-pattern '^luna-npm-v[0-9]' \
  --include-path 'js/luna/**' --include-path 'luna/**' \
  --prepend js/luna/CHANGELOG.md
```

- `--unreleased --prepend` adds only the new section; everything already in
  the file, including the sections release-please wrote, stays as it is.
- `--tag-pattern` restricts git-cliff to that package's tags, so "unreleased"
  means "since the last `luna-npm-v*` tag" and not since another package's tag.
- `--include-path` keeps only commits that touched the package. `luna`, `sol`
  and `astra` also include their MoonBit sources (`luna/`, `sol/`, `astra/`),
  because those npm packages ship the compiled MoonBit output.
- Only `feat`, `fix`, `perf`, `revert` and `docs` commits are listed (see
  `cliff.toml`). Outside contributors are credited with `by @login`; that
  lookup uses the GitHub API. Append `--offline` to skip it.
- The GitHub Release body is the `## <version>` section of
  `js/<dir>/CHANGELOG.md`. If the section is missing or empty, the workflow
  falls back to GitHub's generated notes.

---

## One-time setup

### 1. First publish (claim the name)

A trusted publisher can only be registered for a package that exists on npm.

```sh
for pkg in luna sol astra components luna-loader stella testing wcr; do
  printf '%s: ' "@luna_ui/${pkg}"
  npm view "@luna_ui/${pkg}" version 2>/dev/null || echo '(not published)'
done
```

For each `(not published)` package, from the repository root with your local
npm login:

```sh
pnpm install --frozen-lockfile
pnpm --filter @luna_ui/<component> publish
```

To publish all unpublished workspace versions locally, use `pnpm publish -r`
(`just release-npm`). Run `pnpm publish -r --dry-run` first to preview the
selection. For pending uncommitted changes, append `--no-git-checks` to the
dry run. The eight public packages have `prepack` builds; examples, the root,
`@sol/core`, and `@luna_ui/wcssr` are private. Internal dependencies use
`workspace:^`, which pnpm converts to ordinary semver ranges in the package
artifact. The command does not bump versions and skips versions already on
npm. A local publish carries no provenance; prefer the tag flow for every
release after the first.

### 2. Register the trusted publisher (per package, 8×)

Needs npm 11.15+ and 2FA on the account. Run it in a real terminal: npm asks
for 2FA in the browser and exits with `EOTP` when there is no TTY.

```sh
for pkg in luna sol astra components luna-loader stella testing wcr; do
  npm trust github "@luna_ui/${pkg}" --repo mizchi/luna.mbt --file publish.yml --allow-publish -y
done
npm trust list @luna_ui/luna
```

- `--file` is the workflow filename only. Renaming `publish.yml` means
  registering all eight packages again.
- Registrations made earlier on npmjs.com (Settings → Trusted Publisher,
  workflow `publish.yml`, no environment) stay valid and show up in
  `npm trust list`. Registering the same combination twice is an error.
- Recommended: package Settings → Publishing access → "Require two-factor
  authentication and disallow tokens". Trusted publishing keeps working and a
  leaked token can no longer publish.

### 3. Protect the release tags

Whoever can push a `*-npm-v*` tag can publish. Restrict creating, moving and
deleting these tags to repository admins with a tag ruleset (target
`refs/tags/*-npm-v*`, rules creation / update / deletion, bypass for the
Repository admin role). With the `npm-release` skill:

```sh
scripts/protect-tags.sh --pattern '*-npm-v*' mizchi/luna.mbt
gh api repos/mizchi/luna.mbt/rulesets --jq '.[].name'
```

Also review every pull request that touches `.github/workflows/publish.yml`:
a changed workflow publishes arbitrary code on the next tag.

### 4. Remove what the release-please flow left behind

```sh
gh secret list --repo mizchi/luna.mbt
gh secret delete RELEASE_PLEASE_APP_PRIVATE_KEY --repo mizchi/luna.mbt
gh secret delete NPM_TOKEN --repo mizchi/luna.mbt   # only if it is listed
```

Uninstall the `mizchi-release-please` GitHub App (app-id `3420845`) from this
repository at <https://github.com/settings/installations>; once no repository
uses it, revoke its private keys and delete the App. Close any open
`release-please--branches--main` pull request and delete that branch.

---

## Troubleshooting

| Symptom | Cause | Fix |
| --- | --- | --- |
| No workflow run after pushing tags | More than three tags in one push | Delete the remote tags and push them again, at most three at a time |
| `npm publish` fails with 404 / `ENEEDAUTH` | Trusted publisher missing or registered for another filename | Compare `npm trust list <pkg>` with `publish.yml` |
| `E422` provenance / repository mismatch | `repository.url` in the package differs from this repository | Keep `git+https://github.com/mizchi/luna.mbt.git` (checked by `pnpm test:npm-pack`) |
| Token errors although OIDC is configured | `NODE_AUTH_TOKEN` / `NPM_TOKEN` reached the job | Remove the secret and the env entry |
| "Tag matches package.json version" fails | Tag and `js/<dir>/package.json` differ | Fix the version, commit, recreate the tag |
| Tag push rejected with `GH013` | The ruleset allows only admins to create release tags | Ask an admin to push; do not loosen the rule |
