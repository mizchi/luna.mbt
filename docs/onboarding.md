# Sol Onboarding

This establishes the steps for new members to join development as quickly as possible.

## Prerequisites

- Node.js 24+
- `pnpm`
- `moon` / `sol` commands

## 1. Initial Setup

Run the following after cloning this repository.

```bash
just bootstrap
```

What `just bootstrap` runs internally:

- `pnpm install`
- `moon update`
- `moon install`

## 2. Golden Path (Shortest Flow)

```bash
sol new myapp --user yourname
cd myapp
pnpm install
pnpm dev
sol build
sol deploy --provider cloudflare-workers --dry-run
```

Verification points:

- `http://localhost:7777/` is displayed
- `http://localhost:7777/api/health` returns JSON

## 3. What to Do for Your First Change

1. Add 1 page
2. Add 1 API
3. Update 1 documentation section

## 4. Pre-PR Check

```bash
just verify
```

`just verify` runs the following in order:

- `check`
- `test`
- `test-docs`
- `test-cli-golden`
- `build`

## 5. CI Alignment

The GitHub Actions `check` workflow also runs the same `just bootstrap` and `just verify`.
