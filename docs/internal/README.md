# Luna Specifications

Architecture Decision Records (ADRs) for the Luna UI Library ecosystem.

## Structure

```
spec/
├── luna/           # Core UI library specifications
├── astra/          # Static Site Generator specifications
├── sol/            # SSR Framework specifications
├── stella/         # Island Shard specifications
├── internal/       # Development logs and proposals
│   ├── done/       # Completed implementation records
│   └── deprecated/ # Superseded designs
└── TEMPLATE.md     # ADR template
```

## ADR Index

### Luna (Core UI Library)

| ADR | Title | Status |
|-----|-------|--------|
| [001](luna/001-signal-system.md) | Fine-Grained Reactive Signal System | Accepted |
| [002](luna/002-css-utilities.md) | Atomic CSS Utilities with Deduplication | Accepted |
| [003](luna/003-vnode-abstraction.md) | Virtual Node Multi-Target Rendering | Accepted |
| [004](luna/004-hydration.md) | Progressive Hydration with Triggers | Accepted |
| [005](luna/005-web-components.md) | Web Components with Declarative Shadow DOM | Accepted |

### Astra (Static Site Generator)

| ADR | Title | Status |
|-----|-------|--------|
| [001](astra/001-ssg-pipeline.md) | Static Site Generation Pipeline | Accepted |
| [002](astra/002-meta-files.md) | Optional Meta File Generation | Accepted |
| [003](astra/003-mdx-components.md) | MDX and Custom Component Integration | Accepted |

### Sol (SSR Framework)

| ADR | Title | Status |
|-----|-------|--------|
| [001](sol/001-ssr-framework.md) | SSR Framework with Hono Integration | Accepted |
| [002](sol/002-server-actions.md) | Server Actions with Progressive Enhancement | Accepted |
| [003](sol/003-routing.md) | URLPattern-Based Type-Safe Routing | Accepted |

### Stella (Island Shards)

| ADR | Title | Status |
|-----|-------|--------|
| [001](stella/001-shard-generation.md) | Shard Generation for Island Hydration | Accepted |
| [002](stella/002-serialization-security.md) | Secure State Serialization | Accepted |

## ADR Format

Each ADR follows this structure:

```markdown
# ADR-XXX: Title

## Status
Accepted | Proposed | Deprecated | Superseded by ADR-YYY

## Context
What problem are we solving?

## Decision
What did we decide to do?

## Consequences
What are the trade-offs?
```

## Contributing

1. Copy `TEMPLATE.md` to appropriate module directory
2. Use next available number (e.g., `004-feature.md`)
3. Fill in all sections
4. Submit for review
