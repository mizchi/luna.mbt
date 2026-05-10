# Changelog

## [0.20.0](https://github.com/mizchi/luna.mbt/compare/luna-v0.17.0...luna-v0.20.0) (2026-05-10)


### Bug Fixes

* align all [@luna](https://github.com/luna)_ui npm package versions at 0.20.0 ([0d5f727](https://github.com/mizchi/luna.mbt/commit/0d5f7273fd5c3daa1f6f0854ae0cb04c4eee84fd))
* align all [@luna](https://github.com/luna)_ui npm package versions at 0.20.0 ([87d6672](https://github.com/mizchi/luna.mbt/commit/87d6672038730544716ff07406368c0a61070c02))

## [0.17.0](https://github.com/mizchi/luna.mbt/compare/luna-v0.16.3...luna-v0.17.0) (2026-05-06)


### ⚠ BREAKING CHANGES

* **core:** Attr[E] is now Attr[E, A] with two type parameters
* **apg:** `@radix` module removed, use `@apg` instead
* **luna:** Package paths changed from `mizchi/luna/luna/*` to `mizchi/luna/*`
* **luna:** Show and Match children functions now receive an accessor function instead of the raw value, matching SolidJS behavior.

### Features

* add Resource.pending() and Loading component ([#20](https://github.com/mizchi/luna.mbt/issues/20)) ([14cf349](https://github.com/mizchi/luna.mbt/commit/14cf349d2f98c70408301169135dcae757b5019a))
* add treeshake baseline and signals entrypoint ([aac06f1](https://github.com/mizchi/luna.mbt/commit/aac06f1448e798a962a1c195dd2de842e69698da))
* **apg:** add WAI-ARIA APG compliant components, remove radix ([db2193a](https://github.com/mizchi/luna.mbt/commit/db2193ae1ab3d90ef1e20426bc51b8b5202a7ce7))
* **core:** make Attr type generic for environment-specific attributes ([#14](https://github.com/mizchi/luna.mbt/issues/14)) ([7c5c665](https://github.com/mizchi/luna.mbt/commit/7c5c665ad9ed4a0c52d4defc11d411ff98b55fba))
* extract astra (SSG middleware) from sol ([#23](https://github.com/mizchi/luna.mbt/issues/23)) ([16d54b0](https://github.com/mizchi/luna.mbt/commit/16d54b02ad75c823875d2d591e0c3e28af3d6388))
* **luna:** add CLI for project scaffolding ([d2fd815](https://github.com/mizchi/luna.mbt/commit/d2fd815c12e1522584f3f268239a353a24a2b628))
* **luna:** add composable hydration helpers and refactor demos ([baae0c6](https://github.com/mizchi/luna.mbt/commit/baae0c6d0384d46352923006f479e28f8184615b))
* **luna:** add createElementNS for SVG/MathML support ([1d93f71](https://github.com/mizchi/luna.mbt/commit/1d93f71080e9f9a6c9b448a5444d13e41d755aba))
* **luna:** add CSS splitting and vite plugin virtual modules ([000a3ac](https://github.com/mizchi/luna.mbt/commit/000a3ac752ea9773bafedbe2779b875bdba60fe6))
* **luna:** add CSS static analyzer and co-occurrence optimizer ([d84b2c1](https://github.com/mizchi/luna.mbt/commit/d84b2c14556ca9bfea156c9ad925ebeb1396e6c8))
* **luna:** add CSS utilities with zero-runtime extraction ([3ee08a4](https://github.com/mizchi/luna.mbt/commit/3ee08a48c092823355fed75115dc3d03916feac4))
* **luna:** add dangerouslySetInnerHTML and reactive props support ([e26d7a6](https://github.com/mizchi/luna.mbt/commit/e26d7a6f4cb28c7aba29b9da09e232de4a15d794))
* **luna:** add event-utils module for common event patterns ([2fc152e](https://github.com/mizchi/luna.mbt/commit/2fc152e575c2256d90ec60870a68e418efbece8f))
* **luna:** add experimental CSS optimization to vite-plugin ([224747b](https://github.com/mizchi/luna.mbt/commit/224747b08b115d06eb20f3369aceec68c8c1659f))
* **luna:** add import.meta.env.DEV for runtime DCE ([bdad8bb](https://github.com/mizchi/luna.mbt/commit/bdad8bbd63c9e3491151ba0f4a783bfd07ba3548))
* **luna:** add static content API with innerHTML optimization ([83f1b4f](https://github.com/mizchi/luna.mbt/commit/83f1b4f8ff752cebb82cfca5f304bf6c30187690))
* **luna:** align effect semantics with Solid.js ([f643d05](https://github.com/mizchi/luna.mbt/commit/f643d0575eec0471c6ad114b7f11934a3d51779b))


### Bug Fixes

* **cli:** update scaffold templates to use current API ([#19](https://github.com/mizchi/luna.mbt/issues/19)) ([0207c0e](https://github.com/mizchi/luna.mbt/commit/0207c0e8322e441edf6e80a7337d9390b75185ce)), closes [#12](https://github.com/mizchi/luna.mbt/issues/12)
* **cli:** use correct `moonbit` import from vite-plugin-moonbit ([4fc498e](https://github.com/mizchi/luna.mbt/commit/4fc498eadc6be54e6d55062722cebeb7ec0a763e))
* **js-api:** return undefined for resource errors ([22077eb](https://github.com/mizchi/luna.mbt/commit/22077eb4a073f8bf125f95030ed1ac6d87e02f74))
* **loader:** harden navigation and optimize state extraction ([a2db7c3](https://github.com/mizchi/luna.mbt/commit/a2db7c34a3dbe96078823e67eaa3a68c85e4c42f))
* **luna-cli:** update MoonBit template to use current Luna API ([4d51630](https://github.com/mizchi/luna.mbt/commit/4d516309cc6d9873b2878a66a8a9a7830e7a05ea))
* **luna:** handle DocumentFragment with multiple children in show ([f68950a](https://github.com/mizchi/luna.mbt/commit/f68950ad658fd4aa0c44e5a7ae5420881ffed34d))
* **luna:** make Fragment JSX-compatible and unify child resolution ([5b583ed](https://github.com/mizchi/luna.mbt/commit/5b583eda98a5d8c6ebe1debab1a0d92f61d0b547))
* **luna:** make Switch/Match reactive to signal changes ([ab1dacc](https://github.com/mizchi/luna.mbt/commit/ab1dacc832fd924030511db497ad2cd2a52e6ac1))
* **luna:** prevent duplicate child rendering in Show component ([c07157a](https://github.com/mizchi/luna.mbt/commit/c07157a1666b9ebc93c727a22119c47ae8e5349a))
* **luna:** prevent duplicate child rendering in Show component ([9e615c8](https://github.com/mizchi/luna.mbt/commit/9e615c81376873fc97920d382809ecd324f4275b))
* **luna:** prevent infinite loop in nested Show/For components ([b51ebc5](https://github.com/mizchi/luna.mbt/commit/b51ebc5e6ed303158f8d9d92c74c2b31e757989e))
* **luna:** require function children for control flow components ([78f5417](https://github.com/mizchi/luna.mbt/commit/78f5417a2c94789b2a2c8b4e2bb94723934e5000))
* **luna:** Show/Match children receive accessor function (SolidJS-compatible) ([6d2fe8a](https://github.com/mizchi/luna.mbt/commit/6d2fe8a13602764a5cf46d37db91ac3d64951103))
* **luna:** Switch/Match and Fragment rendering issues ([ec34230](https://github.com/mizchi/luna.mbt/commit/ec342300f9e975eb508711ee803bf81afff52850))
* resolve TypeScript and test errors for CI ([2884d6b](https://github.com/mizchi/luna.mbt/commit/2884d6b6ff2a96828baeee1b4f057ce72067e3f0))
* update luna/js import path in js/luna/src/index.ts ([2ef7603](https://github.com/mizchi/luna.mbt/commit/2ef7603e123d1879f967b8cfedee6473006ca8fa))


### Performance Improvements

* **luna:** add lite/raw entrypoints with split router/resource APIs ([8a58637](https://github.com/mizchi/luna.mbt/commit/8a5863714597665c20b2e3ff2b2d61c8569a5525))
* **luna:** strip moonbit abort location paths from js bundle ([49d17e1](https://github.com/mizchi/luna.mbt/commit/49d17e16e12d22dd3fa31db5e84c3ff5c6be34b3))
* **resource-lite:** replace moonbit resource with tiny ts state machine ([d6b119d](https://github.com/mizchi/luna.mbt/commit/d6b119dacdc1d9fde574934f1d37faae07bab868))
* **router-lite:** replace moonbit router with tiny ts implementation ([e0ce7a6](https://github.com/mizchi/luna.mbt/commit/e0ce7a6387f33626f6e777a9b699fe2ebcf55255))
* **router-lite:** shrink lite wrapper and bump moon to 0.14.0 ([310dae4](https://github.com/mizchi/luna.mbt/commit/310dae4ff5b1a7a25f5ac1b6be4779b47a8aba12))


### Code Refactoring

* **luna:** flatten src/luna/* to src/* ([a4da5bc](https://github.com/mizchi/luna.mbt/commit/a4da5bcdfd2b33766ea30a3ca59174adda48425c))
