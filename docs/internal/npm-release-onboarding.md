# npm Release Onboarding

Setup steps the maintainer must complete **once** before
`.github/workflows/release-please.yml` and
`.github/workflows/publish.yml` can actually publish anything.

The two workflows together handle:
- release-please proposes a "chore: release X" PR aggregating Conventional
  Commits across `js/*` packages.
- Merging that PR creates per-package GitHub Releases tagged
  `@luna_ui/<pkg>-v<version>`.
- `publish.yml` reacts to each Release event and runs `npm publish` from
  the matching `js/<pkg>` directory using OIDC Trusted Publishing
  (no NPM_TOKEN needed).

Scope: 9 packages — `@luna_ui/{luna,sol,astra,components,luna-loader,stella,testing,wcr,wcssr}`.

The 3 mooncakes packages (`mizchi/{luna,sol,astra}` MoonBit modules) stay
on the existing `luna/scripts/vup.mjs` flow and are out of scope here.

---

## 1. GitHub App private key secret

We use the existing `mizchi-release-please` GitHub App (app-id `3420845`)
so release-please can open PRs without granting "Allow GitHub Actions to
create and approve pull requests" repo-wide.

1. Visit <https://github.com/settings/installations> → `mizchi-release-please`.
2. **Configure** → Repository access → either **All repositories**, or
   **Only select repositories** with `luna.mbt` added.
3. Generate (or fetch a previously generated) **private key** PEM.
   - GitHub App settings → Private keys → "Generate a private key" yields
     a `.pem` download.
4. Store the **full PEM** (BEGIN/END lines included, NOT base64-encoded)
   as a repo secret:

   ```sh
   gh secret set RELEASE_PLEASE_APP_PRIVATE_KEY \
     --repo mizchi/luna.mbt \
     --body "$(cat ~/Downloads/mizchi-release-please.<timestamp>.private-key.pem)"
   ```

   Or via the web UI: Settings → Secrets and variables → Actions → New
   repository secret → name `RELEASE_PLEASE_APP_PRIVATE_KEY`.

---

## 2. npm Trusted Publisher registration (per package, 9×)

OIDC Trusted Publishing replaces NPM_TOKEN. Each package must be told
which GitHub workflow is allowed to publish it.

For **each** of the 9 packages below:

1. Sign in at <https://www.npmjs.com>.
2. Go to the package page → **Settings** → **Trusted Publisher** → **Add**.
3. Fill in:
   - Provider: **GitHub Actions**
   - Organization or user: `mizchi`
   - Repository: `luna.mbt`
   - Workflow filename: `publish.yml` (filename only — no path, no `.github/workflows/` prefix)
   - Environment name: leave **empty** (we don't gate via GitHub Environments)

Packages:

- `@luna_ui/luna`
- `@luna_ui/sol`
- `@luna_ui/astra`
- `@luna_ui/components`
- `@luna_ui/luna-loader`
- `@luna_ui/stella`
- `@luna_ui/testing`
- `@luna_ui/wcr`
- `@luna_ui/wcssr`

---

## 3. First-time publish (claim the names)

Trusted Publisher cannot be configured for a package that doesn't exist
yet on npm. Packages that have never been published need ONE manual
publish from a local machine to claim the name. After that, OIDC takes
over for subsequent releases.

Check current state:

```sh
for pkg in luna sol astra components luna-loader stella testing wcr wcssr; do
  printf '%s: ' "@luna_ui/${pkg}"
  npm view "@luna_ui/${pkg}" version 2>/dev/null || echo '(not published)'
done
```

For each `(not published)` package, from the package directory:

```sh
cd js/<pkg>
pnpm install
pnpm -r build           # build deps
npm publish --provenance --access public
```

(Use `npm publish` not `pnpm publish` — Trusted Publishing requires
npm 11+ which currently provides the OIDC token exchange.)

Per the table baked into `release-please-config.json`, at the time of
this doc the packages most likely needing first-claim are:
`@luna_ui/sol`, `@luna_ui/astra`, possibly `@luna_ui/components` and
`@luna_ui/testing`. Verify with the loop above.

---

## 4. npm 2FA setting

OIDC publish is rejected when a package has 2FA set to "Authorization
and writes". Switch each package's 2FA to **"Authorization only"**.

Per package on npmjs.com → Settings → Require two-factor authentication
→ choose **Authorization only**.

(Account-level 2FA stays as-is — this is a per-package setting.)

---

## 5. First release dry-run

Once secret + Trusted Publishers + 2FA are set:

```sh
gh workflow run release-please.yml --repo mizchi/luna.mbt
```

This creates a "chore: release X" PR. Review the CHANGELOG diff per
package, then merge. The same workflow re-runs on PR close (guarded by
`if: startsWith(github.event.pull_request.head.ref, 'release-please--')`)
and creates the per-package tags + GitHub Releases. Each Release event
triggers `publish.yml` once, which publishes that one package.

Watch progress:

```sh
gh run list --workflow=release-please.yml --repo mizchi/luna.mbt --limit 5
gh run list --workflow=publish.yml       --repo mizchi/luna.mbt --limit 9
```

---

## Day-to-day operation

Once setup is done, the only manual step is **merging the Release PR**.
Conventional Commits drive everything:

- `feat(luna): ...` → bumps `@luna_ui/luna` minor
- `fix(stella): ...` → bumps `@luna_ui/stella` patch
- `feat(luna)!: ...` or `BREAKING CHANGE:` footer → major bump
- Commits **without** a known scope are ignored — release-please can't
  attribute them to a package and won't include them in the Release PR.

Recognized scopes (from `release-please-config.json` package keys):
`luna`, `sol`, `astra`, `components`, `loader` (publishes as `luna-loader`),
`stella`, `testing`, `wcr`, `wcssr`.
