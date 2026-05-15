---
title: Quasar Feed
description: RSS reader with on-device summarization.
layout: doc
sidebar: false
---

<div class="project-detail">

[&larr; Back to portfolio](/)

![Quasar Feed screenshot](/projects/project-5.svg)

# Quasar Feed

<p class="meta">2025 &middot; cloudflare &middot; workers &middot; llm</p>

A self-hosted RSS reader that runs as a single Cloudflare Worker. Articles are summarized on-device using Workers AI; full text is cached in R2 with content-addressed keys.

## What I built

- Hono-based Worker with Durable Objects for per-user feed state.
- Background polling via Cloudflare Cron Triggers, batched per 64 feeds per invocation.
- A minimal reader UI rendered server-side; client JS is &lt;5kB gzip.

## What I learned

Workers AI's `@cf/meta/llama-3.1-8b-instruct` summary quality is good enough for headline-grade output and obviously not good enough to replace a real model. Pick the bar deliberately. R2 + content-addressed keys is the right default for any "cache the whole article" pattern.

</div>
