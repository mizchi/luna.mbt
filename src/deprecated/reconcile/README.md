# reconcile (experimental)

This module contains an experimental VNode diff/patch reconciliation algorithm extracted from the legacy `proto_vdom` implementation.

## Status: NOT FOR PRODUCTION USE

This module is provided as a reference implementation only. The current ui.mbt system uses **fine-grained reactivity with signals**, which does not require traditional VDOM reconciliation.

## When to use this

You should **NOT** use this module unless:

- You are researching VDOM diff algorithms
- You need keyed list reconciliation as a reference
- You are building a separate rendering system outside the signal-based architecture

## Architecture

- `vnode.mbt` - VNode type definitions (separate from `@ui.Node`)
- `diff.mbt` - Diff algorithm that generates `Patch` operations
- `patch.mbt` - Applies patches to the DOM

## Why this exists

The original proto_vdom was a React-style VDOM implementation. When migrating to fine-grained reactivity (Solid.js-style), the reconciliation logic became unnecessary for the main use case. However, the diff algorithm is preserved here for future reference or specialized use cases.
