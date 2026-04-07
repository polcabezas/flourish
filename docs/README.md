# flourish Docs

This folder contains all documentation for the flourish macOS application, organized using the [Diataxis](https://diataxis.fr) framework.

## Structure

```
docs/
├── index.md              ← Global hub and entry point
├── README.md             ← This file
├── changelog/            ← User-visible release notes
├── app/                  ← flourish macOS app documentation
│   ├── index.md
│   ├── NAVIGATION_MAP.md
│   ├── tutorials/        ← Guided, hands-on learning paths
│   ├── how-to/           ← Task-focused recipes
│   ├── reference/        ← Factual specifications and lookups
│   ├── explanation/      ← Architecture rationale and concepts
│   └── adr/              ← Architectural Decision Records
├── platform/             ← Cross-cutting security and governance
├── books/                ← Curated reading paths
└── graph/                ← Link graph manifests (catalog, edges, aliases)
```

## Conventions

- Every doc lives in the correct Diataxis folder for its intent.
- Local `index.md` and global `docs/index.md` are updated whenever a significant doc is added.
- ADRs are immutable once merged; add a superseding ADR instead of editing.
- The `graph/` manifests are updated for any major hub-level doc.
