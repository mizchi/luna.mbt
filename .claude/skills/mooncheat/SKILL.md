---
name: mooncheat
description: Moonbit cheatsheet to check syntax and corelibrary usages
allowed-tools: Read, Grep, Glob
---

- See [syntax.mbt.md](./syntax.mbt.md) to check moonbit syntax
- Search builtin APIs
  - Grep `~/.moon/lib/core` to check syntax details.
  - MoonDoc: `moon doc ArrayView`, `moon doc Array*`
- Grep `.mooncakes/` to check library usages.
  - username/pkg/(src/)?pkg.generated.mbti
- Configuration
  - moon.pkg.json
    - See https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html
    - moon.pkg.json's jsonschema https://raw.githubusercontent.com/moonbitlang/moon/71abb232f9b661c079246a85a19ff8fe3421170a/crates/moonbuild/template/pkg.schema.json
  - moon.mod.json
    - See https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
    - moon.mod.json's jsonschema https://raw.githubusercontent.com/moonbitlang/moon/71abb232f9b661c079246a85a19ff8fe3421170a/crates/moonbuild/template/mod.schema.json
  - `moon check` warning and alert configuration
    - Get warning list by `moonc build-package -warn-help`
