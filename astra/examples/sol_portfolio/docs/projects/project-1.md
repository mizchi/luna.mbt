---
title: Aurora Notes
description: Local-first markdown editor with CRDT sync.
layout: doc
sidebar: false
---

<div class="project-detail">

[&larr; Back to portfolio](/)

![Aurora Notes screenshot](/projects/project-1.svg)

# Aurora Notes

<p class="meta">2024 &middot; rust &middot; crdt &middot; tauri</p>

A local-first markdown editor that syncs notebooks across devices without a central server. Each note is a Yjs document; conflict resolution is automatic and offline writes always reconcile.

## What I built

- Tauri shell wrapping a custom CodeMirror 6 setup.
- Yjs document per note, persisted with `y-indexeddb` and synced via `y-webrtc`.
- File-system bridge so notes appear as plain `.md` files for git workflows.

## What I learned

CRDT debugging is fundamentally different from event-sourced debugging. Tooling around `Y.Doc` inspection paid back its cost within a week. Tauri's IPC boundary needs a clear contract; ad-hoc JSON message types regress fast.

</div>
