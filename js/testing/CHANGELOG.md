# Changelog

## [0.22.1](https://github.com/mizchi/luna.mbt/compare/testing-v0.22.0-npm...testing-v0.22.1-npm) (2026-05-15)


### Bug Fixes

* publish npm peer dependency without the workspace protocol

## [0.22.0](https://github.com/mizchi/luna.mbt/compare/testing-v0.20.0...testing-v0.22.0-npm) (2026-05-15)


### Features

* publish the npm testing package alongside the 0.22 release


### Bug Fixes

* point package exports at the generated `.mjs` and `.d.mts` files


### Dependencies

* The following workspace dependencies were updated
  * peerDependencies
    * @luna_ui/luna bumped to 0.22.0

## [0.20.0](https://github.com/mizchi/luna.mbt/compare/testing-v0.17.0...testing-v0.20.0) (2026-05-10)


### Bug Fixes

* align all [@luna](https://github.com/luna)_ui npm package versions at 0.20.0 ([0d5f727](https://github.com/mizchi/luna.mbt/commit/0d5f7273fd5c3daa1f6f0854ae0cb04c4eee84fd))
* align all [@luna](https://github.com/luna)_ui npm package versions at 0.20.0 ([87d6672](https://github.com/mizchi/luna.mbt/commit/87d6672038730544716ff07406368c0a61070c02))


### Dependencies

* The following workspace dependencies were updated
  * peerDependencies
    * @luna_ui/luna bumped to 0.20.0

## [0.17.0](https://github.com/mizchi/luna.mbt/compare/testing-v0.1.0...testing-v0.17.0) (2026-05-06)


### ⚠ BREAKING CHANGES

* **core:** Attr[E] is now Attr[E, A] with two type parameters

### Features

* **core:** make Attr type generic for environment-specific attributes ([#14](https://github.com/mizchi/luna.mbt/issues/14)) ([7c5c665](https://github.com/mizchi/luna.mbt/commit/7c5c665ad9ed4a0c52d4defc11d411ff98b55fba))
* **testing:** add [@luna](https://github.com/luna)_ui/testing library ([b0edd7b](https://github.com/mizchi/luna.mbt/commit/b0edd7bf6ba5e6a66f6fa2df081c7ae61826985e))


### Dependencies

* The following workspace dependencies were updated
  * peerDependencies
    * @luna_ui/luna bumped to 0.17.0
