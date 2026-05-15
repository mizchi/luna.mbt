---
title: Release
description: A sol release, rendered from the monorepo CHANGELOG.md.
---

<article>

# sol release

<div class="release-meta">
<a href="/">← All releases</a>
<span>·</span>
<a href="https://github.com/mizchi/luna.mbt/blob/main/sol/CHANGELOG.md">source</a>
</div>

This is a placeholder body. In a real CHANGELOG viewer the build step would
slice `sol/CHANGELOG.md` per `## <version>` heading and inline the body for
the `version` param resolved from `staticParams`.

## Added

- Static generation of one HTML page per sol release.
- Per-release deep links (`/release/<version>/`) suitable for changelog
  references inside docs and commit messages.

## Changed

- Release index sorts newest-first and links into each version page.

## Notes

The `version` segment is supplied by `docs/release/_version_/page.json`'s
`staticParams` array, which mirrors the `## <version>` headings of
`sol/CHANGELOG.md`.

</article>

<footer>
Built with <a href="https://github.com/mizchi/luna.mbt">mizchi/astra</a> · MIT
</footer>
