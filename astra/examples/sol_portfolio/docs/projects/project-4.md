---
title: Pulsar Lint
description: ast-grep rule pack for TypeScript codebases.
layout: doc
sidebar: false
---

<div class="project-detail">

[&larr; Back to portfolio](/)

![Pulsar Lint screenshot](/projects/project-4.svg)

# Pulsar Lint

<p class="meta">2025 &middot; ast-grep &middot; typescript &middot; lint</p>

A curated ast-grep rule pack for TypeScript codebases. Catches the patterns ESLint either misses or only flags via heavy custom rules: stale closures in `useEffect`, accidental `any` returns from `JSON.parse`, missing `await` on tagged promises.

## What I built

- ~40 rules organized into "react", "promise", and "type-safety" groups.
- A test harness that runs each rule against a positive and negative fixture and asserts the fix output.
- A GitHub Action that posts annotated rule hits as PR review comments.

## What I learned

ast-grep's `transform` step is more powerful than the docs let on; most "needs a custom JS plugin" problems can be solved with a `rewrite` rule. The ROI of a lint rule is dominated by its false-positive rate, not its catch rate.

</div>
