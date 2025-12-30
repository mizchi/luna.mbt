# Changelog

All notable changes to this project will be documented in this file.

## [0.3.4] - 2025-12-30

### Bug Fixes

- **examples**: Use inline style for visible_when in TodoMVC
- **ci**: Remove src/core/routes from playwright workflow
- **ci**: Remove non-existent directory references
- Resolve TypeScript and test errors for CI
- **luna**: Prevent duplicate child rendering in Show component
- **luna**: Prevent duplicate child rendering in Show component
- **sol**: Externalize shiki to reduce bundle size
- **luna**: Wrap initial render in untracked to prevent dependency tracking

### Documentation

- Move deep-dive section to 90_deep-dive
- **luna**: Add doctest examples to signal and vnode modules
- **luna**: Add missing CSS detection usage guide
- **luna**: Update CSS utilities documentation
- Update CHANGELOG for v0.3.2

### Features

- **luna**: Add experimental CSS optimization to vite-plugin
- **luna**: Add CSS static analyzer and co-occurrence optimizer
- **luna**: Add import.meta.env.DEV for runtime DCE
- **luna**: Add CSS splitting and vite plugin virtual modules
- **luna**: Add CSS utilities with zero-runtime extraction
- **luna**: Add dangerouslySetInnerHTML and reactive props support

### Miscellaneous

- Update package exports and generated files
- Remove unused files
- V0.3.2

### Testing

- **luna**: Add tests for Show + render initial mount duplication
- **luna**: Add tests for Show + render initial mount duplication
- **luna**: Add CSS runtime benchmarks and optimizer module
- **luna**: Add CSS runtime missing detection tests
- **luna**: Add exact reproduction tests for issue #5

## [0.3.1] - 2025-12-29

### Bug Fixes

- **luna**: Prevent infinite loop in nested Show/For components
- **luna**: Require function children for control flow components
- **luna**: Add cross-platform support for queue_microtask

### Documentation

- **spec**: Add analysis of astra_worker and generator extraction
- Update examples and changelog for lifecycle hooks
- Translate code comments and READMEs to English

### Features

- **sol**: Add manifest_to_sol_routes for handler injection
- **luna**: Align effect semantics with Solid.js

### Miscellaneous

- Rename build:astra to build:sol
- V0.3.0
- Format code and update CHANGELOG
- V0.2.7
- Format code and update CHANGELOG
- Doc

### Refactor

- **js**: Rename js/astra to js/sol
- **sol**: Move adapters, builder_pool, worker from astra to sol
- **cli**: Unify sol and astra CLI, remove astra/cli
- **content**: Move markdown processor to sol/content/md_render
- **content**: Move markdown types, toc, cst to sol/content
- **content**: Move shiki and frontmatter to sol/content
- **builder**: Extract generic worker pool to sol/builder
- **cli**: Extract shared utilities to sol/cli_common and sol/hmr
- **sol**: Merge core/routes into sol/routes
- **sol**: Extract file scanning infrastructure to sol/routes
- **sol**: Merge core/isr into sol/isr
- **sol**: Move browser_router from luna/dom to sol
- **signal**: Extract with_parent_owner utility for owner context inheritance
- **docs**: Use `using` statement in astra_app SSR component
- **examples**: Use `using` statements for cleaner imports

### WIP

- Astra/sol refactoring in progress

## [0.2.6] - 2025-12-28

### Bug Fixes

- **luna**: Handle DocumentFragment with multiple children in show
- **a11y**: Improve contrast ratio for strategy badges
- **test**: Increase timeout for CLI build test
- Include js/astra build in dev-doc and build-doc
- Restore website path for demo build output
- **astra**: Use direct child selectors for nested accordion styles
- **luna**: Make Fragment JSX-compatible and unify child resolution
- Render inline code
- **luna**: Switch/Match and Fragment rendering issues
- **luna**: Handle moveBefore failures in SVG namespace
- **astra**: Add missing Frontmatter fields
- **astra**: Prevent wiki container overflow
- **luna**: Make Switch/Match reactive to signal changes
- Resolve deprecated syntax and unused variable warnings
- **ci**: Add test and example package builds for browser tests
- **ci**: Exclude astra from browser workflow builds
- **ci**: Specify individual platform/js package paths
- **ci**: Update paths after dom module migration
- **luna-cli**: Update MoonBit template to use current Luna API
- **docs**: Restructure Japanese docs to match English structure
- **docs**: Remove corrupted terminal output from why-luna.md
- **docs**: Correct footer navigation links
- **docs**: Use absolute links in Luna index page
- **astra**: Add proper list indentation in markdown content
- **astra**: Prevent horizontal overflow on mobile
- **astra**: Improve code comment contrast for WCAG compliance
- **astra**: Improve mobile UI responsiveness
- Use code_unit_at instead of deprecated s[idx]
- **ci**: Update docs workflow to use dist-docs directory
- Update shiki css test to match implementation
- Add hono to root devDependencies for E2E tests
- **ci**: Exclude CLI packages from moon test
- Exclude test/example files from TypeScript check
- **astra**: Exclude cli.ts from TypeScript check
- Update .trim() calls to use chars~ parameter
- **luna**: Add TypeScript types for reactive JSX attributes
- **csrf**: Fix Referer prefix match vulnerability
- **middleware**: Fix CORS headers not applied due to JS/MoonBit Map incompatibility
- Resolve deprecation warnings and fix just commands
- **astra**: Use highlighter for initial build in dev server
- **astra**: Resolve dev server exit and HMR broadcast issues
- **sol**: Resolve build errors in sol_app example
- **astra**: Resolve async issues in DocumentTree builder
- **astra**: Avoid @path.join in asset loader to fix async issue
- **e2e**: Skip visual snapshot tests in CI
- **e2e**: Remove platform suffix from snapshots and use cross-platform fonts
- **ci**: Add loader build step for E2E tests
- **ci**: Correct action order and exclude JS from xplat tests
- Add createRequire post-process for ESM compatibility
- **demo**: Remove Loading... placeholder text from demo pages
- **vite**: Simplify dev server config for demo-src
- **wc**: Fix wc-conditional initial render issue
- Workaround moon_db corruption after vitest CLI tests
- **astra**: Improve hash link handling in SPA navigation
- Enable show() initial true test (fixed by Fragment change)
- Use real DocumentFragment instead of span wrapper
- Remove routeGroup/routeParam exports after Routes enum refactor
- TypeScript type definitions and add test-ts task
- **wc**: Use exponential backoff for CSS injection to ensure DOM connection
- **wc**: Inject CSS into correct ShadowRoot using getRootNode()
- **sol**: Convert Buffer to string in dev server output
- Resolve all compiler warnings
- **sol_app**: Update debug test with luna:* attributes
- **sol_app**: Update static loader files with luna:* attributes
- **wc**: Improve hydrate_auto_dom to minimize flash during CSR
- Resolve moon check warnings and reduce e2e test noise
- **sol**: Show output path in rolldown bundling message
- **sol**: Remove duplicate server URL output in sol dev
- **sol**: Generate app/__gen__/types in sol new
- **sol**: Update serve_static to check dev/prod static paths
- **sol**: Improve hydration and dev command
- **sol**: Fix hydration and improve dev command
- **e2e**: Update loader path after packages->js rename
- **coverage**: Clean up old moonbit coverage files before each run
- **coverage**: Exclude _test.mbt files from coverage report
- **e2e**: Use Node.js native TS execution for playwright
- **cli/templates**: Update Node type to Node[Unit] and fix imports
- Export forEach via type-erased wrapper in api_js
- **luna**: Update dom.js import path after DOM module extraction
- Resolve all moon check warnings by adding factory functions and tests
- Update justfile and packages/ui to use vitest instead of bun test
- Update packages/ui export paths for new js/ directory structure
- Update justfile paths for new js/ directory structure
- Add root tsconfig.json for TSX support across the project

### Dependencies

- Update markdown to 0.3.3

### Documentation

- Reorganize specifications into spec/ with ADR format
- **css-factorize**: Add comprehensive design summary
- **css-factorize**: SSR compatibility analysis for Shadow DOM styles
- **css-factorize**: Add Shadow DOM boundary considerations
- **css-factorize**: Add pseudo-selector and media query API design
- **experiments/css-factorize**: Add API design and concerns
- **experiments/css-factorize**: Add benchmark results
- **astra**: Add components documentation
- Update CHANGELOG
- Update TODO with new items
- **internal**: Add Luna improvement proposals Part 2
- **internal**: Archive resolved feedback items
- Update TODO.md with completed items
- Add deploy adapters and ISR documentation
- Update TODO and add internal proposal
- Complete Japanese translations and fix astra build
- Update TODO.md - mark CLI scaffold as done
- Rename Luna Core to Luna UI and reorganize
- **tutorial**: Add CLI quick start to getting started guides
- **luna**: Add CLI quick start to README
- **stella**: Add comprehensive Web Components documentation
- **TODO**: Update dynamic route syntax to _id_ format
- **TODO**: Remove completed preload task
- Move completed tasks to docs/internal/done
- **internal**: Add renderer abstraction design notes
- Update TODO.md with Phase 4-6 completion status
- Emphasize Luna design philosophy and motivation
- Add draft blog post about Luna UI (Japanese)
- **luna**: Add README with setup guide and API examples
- Update READMEs to reflect current implementation
- Add Server Actions implementation log and TODO
- Update CLAUDE.md with just --list reference
- Update API documentation and fix outdated island architecture references
- Add Astra documentation section
- Add comprehensive tutorial series (Solid-style)
- Add "Why Luna?" page highlighting unique features
- **ja**: Add Japanese guide pages
- Add initial documentation site structure
- **markdown**: Add design spec, CRDT considerations, and perf tuning notes
- Add Sol build internal spec and virtual package documentation
- Add headless ui library to icebox
- Add UserReview section and reorganize TODO
- Add hydration problem analysis (DomNode vs VNode)
- **wc**: Add Island vs WC Island decision benchmarks and guidelines
- **wc**: Add Web Components SSR/Hydration integration plan
- **render_bench**: Add experiment 3 results (to_array hybrid approach)
- Update TODO with new items and mark dev/prod split as done
- **sol**: Update README with current architecture and playground info
- Add BF Cache optimization to TODO
- Update README and reorganize documentation
- Add MoonBit coding guidelines
- **cov-reporter**: Add README with module documentation
- Update documentation for Luna rename and project structure
- Add cross-target build guide and xany implementation plan
- **browser**: Add bundle size optimization notes to element_dsl
- Add WIP status and TODO roadmap to embedding ARCHITECTURE.md
- Add fixable hydration documentation (EN/JP)
- Update README with Solid-inspired Fine-Grained Reactivity

### Features

- **astra**: Add Pagefind search and suffix-based i18n
- **turbo**: Add lint:doc to release pipeline
- Add release-doc task with turbo dependency chain
- **turbo**: Add build:astra task for doc builds
- Change default task to incremental tests
- **turbo**: Add granular test tasks with caching
- Introduce turborepo for task dependency and caching
- **astra**: Support astra.json in docs directory
- **astra**: Add MetaFilesConfig for optional sitemap/feed/llms.txt generation
- **css**: Add CSS splitting and inline threshold configuration
- **css**: Add CSS utilities benchmark
- **luna/css**: Integrate css module with static_dom
- **luna/css**: Add CSS utility module for atomic CSS generation
- **css-factorize**: Add configurable StyleMode for Shadow DOM styles
- **experiments**: Add CSS rule factorization prototype
- **astra**: Add SVG icons for nav items
- **astra**: Add incremental build skip with content hash cache
- **docs**: Update landing page content and style
- **astra**: Redesign docs with moon-inspired theme
- **luna**: Add event-utils module for common event patterns
- **luna**: Add comprehensive event handler types
- **astra**: Add blog template with post cards and layouts
- **astra**: Add element-based header/footer composition
- **astra**: Add convention-based component discovery
- **astra**: Add ComponentRegistry for pluggable components
- **astra**: Add components and themes modules
- Add MDX support and SPA routing improvements
- Add blog template with frontmatter extensions
- Add generic disk cache with FileSystem trait
- Add ISR implementation and SQLite example
- **astra**: Add noindex frontmatter support
- **luna**: Add createElementNS for SVG/MathML support
- **astra**: Add dynamic route patterns to Cloudflare _routes.json
- **astra**: Add file-based dynamic route support
- **luna**: Add static content API with innerHTML optimization
- **luna**: Add CLI for project scaffolding
- **stella**: Add Web Components build system with Playwright tests
- **routes**: Implement hierarchical manifest and conflict detection
- **routes**: Add hierarchical manifest and dynamic route support
- **astra**: Add missing translation warnings to lint
- **core**: Add abstract render node types
- **playwright-chaos**: Add chaos crawler for link checking
- **luna**: Add ref prop support in JSX runtime
- **astra**: Add JSON schema validation to astra lint
- **astra**: Static paths take priority over dynamic _slug_ paths
- **astra**: Add dynamic routes with _slug_ pattern and Islands support
- **astra**: Add TSX component SSR support with renderer option
- **astra**: Add SSR flag for component pages
- **astra**: Add component directory support with E2E tests
- **astra**: Add component lint rules and JSON schemas for Phase 8
- **loader**: Add extended routers for Phase 7
- **astra**: Add Cloudflare Pages deploy target with _routes.json
- **astra**: Add Component content type for moon.pkg.json directories
- Implement Phase 3-4 of unified progressive architecture
- **astra**: Detect duplicate pages (index.md + index.html)
- **astra**: Add HTML file support alongside Markdown
- **astra**: Integrate lint into build-doc workflow
- **astra**: Add lint command for documentation checks
- **astra**: Add meta description auto-generation and inline CSS
- **astra**: Add prefetch for faster page navigation
- **astra**: Add custom HTML snippets and ogpText support
- **core**: Add unified RouteManifest architecture
- **astra**: Add parallel build with worker processes
- **astra**: Add js/astra npm package and `astra new` command
- **luna**: Enhance escape_js with more patterns
- **luna**: Restructure npm package with tsdown and TypeScript types
- **sol**: Add nested layout support and CSR cache strategy
- **middleware**: Add security headers middleware
- **sol**: Add progressive enhancement for form submissions
- **sol**: Add Server Actions with client-side integration
- Add middleware E2E tests
- **middleware**: Add method-style composition with .then()
- Implement Layout routing and catch-all routes for Sol
- **astra**: Add HMR hot reload for dev server
- Add CLI bin entries for sol and astra commands
- **astra**: Add DocumentTree intermediate representation for SSG outputs
- **astra**: Add FileSystem trait for testable file operations
- Add ESM support for moon test and update mizchi/js to 0.10.4
- **astra**: Docusaurus-style sidebar with chevron on right
- **astra**: Add footer links and remove Home from sidebar
- **astra**: Add OGP support, 404 page, and rename playground to demo
- **astra**: Add SPA navigation and trailing slash config
- **dsl**: Add dyn_ prefix for dynamic attributes
- Add TodoMVC example with bug fixes and IME support
- Add fine-grained reactive store APIs (SplitStore, LensStore)
- Add createStore for SolidJS-style reactive stores
- Add SolRoutes with typed handlers for Sol routing
- Rename island_from_ref to client and deprecate legacy island APIs
- Add Preact comparison tests and fix Fragment/show for Preact compatibility
- **sol**: Add HMR (Hot Module Replacement) support for dev mode
- **sol**: Add multi-runtime support with tests
- **astra**: Add file ordering with numeric prefixes
- **astra**: Add dark/light mode toggle to header
- **astra**: Add dev server and syntax highlighting
- **astra**: Add exclude option and move internal docs
- Add root package mizchi/luna with re-exports from core and signal
- **examples**: Add Modal example using Portal to SPA
- **portal**: Add Portal component with Shadow DOM support
- **api**: Add SolidJS-compatible API utilities and Owner-based Context
- **ssg**: Add MoonBit FFI bindings for Shiki syntax highlighting
- **router**: Add customizable root HTML template
- **ssg**: Add shiki syntax highlighting tests and ssg_test example
- **ssg**: Add shiki syntax highlighting with caching
- **ssg/markdown**: Replace FFI parser with native MoonBit implementation
- **core**: Add platform-independent CST-based markdown parser
- **ssg**: Add View Transition API support and keyboard navigation
- **sol**: Add SSG (Static Site Generator) module
- **examples**: Add benchmark game for Luna and React comparison
- **sol**: Add ChunkManifest for shared chunk preloading and warn-list suppression
- **experiments**: Add direction modes and Sol integration design
- **experiments**: Add View Transition API prototype
- **core**: Add ComponentRef[T] for type-safe Island embedding
- **sol**: Add async server component support with ServerNode
- **wc**: Add WcIsland route type and use_style CSS injection
- **wc**: Unify Luna Island and WC Island hydration
- **wc**: Implement Web Components SSR with CSR navigation support
- **sol**: Add npm scripts to sol_app example
- **sol**: Add CSR navigation loader for Sol framework
- **wc**: Add Web Components example with nested components and event bubbling
- **wcssr**: Add Web Components SSR library with DOM Parts polyfill
- **sol**: Split .sol output into dev/prod directories
- **sol**: Add /form page and dynamic route generation
- **sol**: Add contact form component and fix multi-island hydration
- **sol**: Add minify support and serve command
- **sol**: Implement CSR navigation with sol-link and sol-nav.js
- **sol**: Update templates to use server-side element DSL
- **sol**: Add server-side element DSL with using syntax
- **sol**: Restructure .sol directory to client/server layout
- **sol**: Move rolldown output to .sol/static and add examples/e2e
- **sol**: Add compiler.mbt with rolldown bindings
- **sol**: Add individual island hydration and sol dev improvements
- **core**: Add ErrorBoundary component for error handling
- **coverage**: Add unified coverage tool with source map support
- **coverage**: Add multi-source coverage collection infrastructure
- **scripts**: Add local build metrics tracker using node:sqlite
- **scripts**: Add test-sol-new.ts for template verification
- **e2e**: Add Sol CLI e2e tests with vitest
- **cli**: Rewrite CLI in MoonBit
- **router**: Add Routes-based routing with SpaRouter and E2E tests
- **examples/spa**: Add routing, async data, and component patterns
- **renderer**: Unify async rendering to VAsync with template-based streaming
- **dom/element**: Add ref_ parameter for direct DOM element access
- **dom/element**: Generate element factories from same data source
- **server_dom**: Add code generator for element factories
- **platform**: Add server_dom module for server-side SSR
- **dom**: Add generic type parameter [T] to EventHandler types
- **dom**: Add typed EventHandler type aliases
- **browser**: Add reference-based DOM reconciliation for list reordering
- **cli**: Add automated E2E testing for template app
- Add CLI and implement app framework (Step 1 & 2)
- **router**: Add declarative routing with CSR/SSR support
- **browser**: Add browser component tests and improve For rendering
- **browser**: Add JSX runtime functions
- **framework**: Add Island Architecture support and refactor e2e_server
- Implement isomorphic hydration with @dom.hydrate runtime
- Add embedding module and E2E test infrastructure with MoonBit Hono server
- Add JS benchmarks with 0x flamegraph and moveBefore API support
- Add smart_hydrate with heuristics and distance-based benchmarks
- Add shallow vs deep update benchmarks
- Add hydration and experimental hydration benchmarks
- Add SSR and DOM rendering benchmarks
- Add WebComponents integration for JS backend
- Add stream rendering support for SSR
- Add async SSR with parallel data fetching support
- Add async Resource pattern for environment-agnostic async state management
- Add Qwik-inspired resumable state serialization
- Add optional StringBuilder logger to hydration
- Add optional StringBuilder logger to hydration
- Restore SSR and hydration with mismatch recovery
- Add comprehensive sample application demonstrating all features
- Add JSX runtime for TSX syntax support
- Add DOM API exports for JavaScript/TypeScript usage
- Add type-safe event handlers and rename jsdom alias to js_dom
- Add Solid.js style Owner system for scoped reactivity
- Add portable SSR module (no JS dependencies)
- Add SSR (Server-Side Rendering) for Signals
- Add Signals library with fine-grained reactivity
- Initial commit - MoonBit UI Library v0.1.0

### Miscellaneous

- V0.2.6
- V0.2.5
- Minimize package.json scripts
- Changelog
- V0.2.4
- **astra**: Remove unused CSS split extraction function
- Update CHANGELOG
- **astra**: Format CLI code
- Bump version to 0.2.3
- Update TODO.md
- Add doc:dev run-script
- Format code
- Add release pre-check command
- V0.2.2
- V0.2.1
- Use non-standard ports for E2E tests to avoid conflicts
- Add cache and db files to gitignore
- Add git-cliff for changelog generation
- Bump version to 0.2.0
- Re-enable astra tests after markdown 0.3.2 update
- Fix platform check path
- Fix moon check paths for core packages
- Skip all astra tests (mooncakes markdown dependency)
- Check specific packages to avoid markdown dependency
- Skip astra tests (mooncakes markdown dependency)
- Skip astra/markdown tests (mooncakes dependency issue)
- Temporarily disable examples build
- **check**: Build workspace packages before TypeScript check
- **docs**: Remove Chaos Crawler step
- Rename luna.config.schema.json to astra.schema.json
- Enable parallel build for docs
- Update generated .mbti files
- Update astra config and docs
- Bump version to 0.1.5
- Fix gitignore to ignore docs/public/
- Update TODO and sol_app gitignore
- Update build config and tooling
- Remove docs/public/demo from git tracking
- Trigger docs workflow test
- Add docs workflow for Astra SSG generation
- Parallelize CI jobs and fix TypeScript errors
- Update dev dependencies and config
- Update justfile to test core/parser module
- Format and minor cleanups
- **sol_app**: Add Cloudflare Workers configuration
- Update TypeScript and clean up tsconfig
- Remove unused bench directory
- Update gitignore and add pnpm workspace config
- Add benchmark docs link, disable markdown xplat test
- Add __screenshots__ to gitignore
- Rename coverage-unified.ts to coverage.ts
- Remove legacy coverage-merge in favor of coverage-unified
- Update workflow to use justfile commands
- Remove unused imports from moon.pkg.json files
- Update docs, add wrangler, refactor browser_app example
- Update index.html to use SPA example path
- Remove deprecated reconcile module and clean up Resource struct
- Update justfile test paths to match new directory structure
- Add *.generated.mbti to gitignore
- Remove _deprecated directory (contents restored to src/)
- Add @types/bun and vite to devDependencies
- Add justfile for running all tests
- Add GitHub Actions workflow

### Performance

- **astra**: Preload loader.js in head
- **astra**: Add async to loader.js script tag
- **sol**: Skip sol generate on incremental rebuilds for faster HMR
- **escape**: Optimize WASM/Native escape to single-pass implementation
- **escape**: Add cross-target optimization with JS FFI
- **reconcile**: Skip unnecessary move_before calls in list reconciliation
- **browser**: Use JS FFI for apply_event_handler
- **browser**: Use JS FFI for HandlerMap to reduce bundle size
- **browser**: Use JS toString for Double instead of MoonBit ryu
- Optimize void element check and cache loop lengths
- Add escape fast path and size_hint optimizations
- Optimize SSR with StringBuilder for 5x native speedup

### Refactor

- Simplify justfile with turbo-centric design
- **turbo**: Delegate to just for task definitions
- **astra**: Use website/astra.json as primary config
- Rename docs to website
- **astra/cache**: Remove redundant code and consolidate BuildManifest
- **astra**: Tree-driven navigation with NavContext
- **astra**: Use components module in static_render
- Integrate Astra cache with core DiskCache
- Make core modules environment-agnostic
- Move sitemap/RSS/llms.txt generators to core/ssg
- Extract shared route pattern utilities to core
- Extract shared ISR types to core/isr module
- **astra**: Extract navigation scripts to assets module
- Move string utilities from ssg to internal/utils
- **astra**: Modularize and migrate to markdown 0.3.1
- **stella,wcr**: Rename packages to @luna_ui namespace
- **astra**: Add RendererType for explicit renderer dispatch
- **astra**: Use pnpm workspace for TSX SSR dependencies
- **examples**: Use dom/element DSL in bar.mbt
- **examples**: Remove duplicate helpers in bar.mbt
- **docs**: Flatten Luna docs hierarchy and fix dead links
- Rename npm packages from @mizchi/* to @luna_ui/* and fix dark mode
- **astra**: Remove root bin/, fix ESM dev server, update docs
- **loader**: Improve loader and sol-nav components
- **sol**: Update router, middleware and action tests
- Fix MoonBit doc comment blocks and reduce code duplication
- Replace C-style loops with functional methods and cleanup tests
- Extract shared SSG types to core/ssg for Sol/Astra integration
- Use FileSystem trait throughout CLI modules
- Reorganize tests by product and pyramid axes
- **sol**: Use esm_require from js.mbt for HMR server
- Remove createRequire injection from build-moon
- Replace internal/cli with mizchi/js/web/console
- Extract Luna runtime from core to src/luna
- Move mbti_utils to core/parser module
- Reorganize module structure for SSG and utilities
- **astra**: Improve sidebar and rename index files
- **wc**: Rewrite Web Components using Luna VNode DSL with inline CSS
- Rename data-hk to sol:hk for SSR hydration keys
- **docs**: Separate JS and MoonBit documentation and add 3-level sidebar nesting
- **docs**: Add overview section and renumber doc directories
- **docs**: Move tutorial content to tutorial-js section
- **docs**: Reorganize structure and add Web Components support
- **docs**: Reorganize with numeric prefixes and fix theme CSS
- Use arrow functions and Iter methods across codebase
- **todomvc**: Use arrow functions and derive JSON traits
- **todomvc**: Use typed APIs from mizchi/js package
- Unify internal name to Luna UI and refactor TodoMVC
- Remove Param and Group from Routes enum
- Move generated hydrate code to __gen__/client/
- Change server_dom DSL to use positional children argument
- Remove deprecated island APIs
- Eliminate code duplication across modules
- Simplify Option handling with if-is-Some pattern
- Migrate markdown parser to external mizchi/markdown package
- Rename luna:trigger to luna:client-trigger
- Separate astra.json from sol.config.json
- Separate astra CLI from sol CLI
- Add watch mode to sol dev, unify escape functions, deprecate island helpers
- Deduplicate code and add internal/utils module
- Rename src/sol/ssg to src/astra
- **routes**: Remove Routes::Island from route definitions
- **sol**: Replace rolldown.config.mjs with programmatic API
- Unify attribute naming to luna:* namespace
- **loader**: Unify wc-loader into js/loader with TypeScript and rolldown
- Move server_dom element factories to element/ subpackage
- Move api_js from src/lib to src/platform/js/api
- Remove src/renderer, move streaming to platform/js
- **client**: Use element DSL with using imports
- **action**: Use enum with Show trait instead of string
- **sol**: Implement v2 architecture with flattened structure
- **sol**: Rename app.mbt to runtime.mbt and add run() helper
- **sol**: Add unit tests and extract common functions
- Optimize loader and fix deprecated syntax warnings
- Consolidate loader and improve test configuration
- Split router into core/routes and platform/dom/router
- Move render_to_string to core/render for multi-target support
- Consolidate _with_ functions using optional parameters
- Improve coverage reporter with directory exclusions
- Use modern for-in loop syntax for array iteration
- Use idiomatic methods for collection operations
- Apply idiomatic MoonBit patterns across codebase
- Use modern for-in loop syntax for array iteration
- **coverage**: Extract coverage library as reusable module
- Migrate npm scripts to justfile
- **scripts**: Use node native TS execution
- **cli**: Embed templates as MoonBit string literals
- Remove packages/cli, move templates to src/sol/cli
- **cli**: Rename CLI from luna to sol
- Merge dom.js into index.js
- Unify JS exports through api_js module
- Improve tree-shaking and clean up exports
- **dsl**: Replace on() with events() method chaining DSL
- **router**: Consolidate router module and add Vite playground
- **dom**: Move hydration code to dom/client/ module
- **dom**: Move element DSL tests to element/ directory
- **renderer**: Consolidate duplicate Island and attribute rendering
- Reorganize src/ structure for platform/renderer separation
- Rename kg: prefix to ln: and embed module to shard
- **sol**: Rename app module to sol and fix type inference warnings
- Add @js alias for mizchi/js/core to clarify JS backend binding
- Rename kaguya to luna
- **browser**: Extract DOM module to src/browser/dom
- **browser**: Rename AttrVal to Attr with explicit variant names
- **examples**: Consolidate SPA example and add E2E tests
- **router**: Split into BrowserRouter and ServerRouter with labeled args
- Consolidate packages and fix deprecation warnings
- Restructure package layout (core, signal, server/renderer)
- Remove src/element and consolidate into @kaguya core
- **style**: Simplify style attribute to string format
- **browser**: Use lowercase event names directly
- **browser**: Make children a positional argument
- **browser**: Use optional params without default values
- **browser**: Use optional parameters (?) instead of labeled (~)
- **browser**: Simplify Element DSL API with labeled arguments
- Move resume module to signal/resume
- Flatten webcomponents into runtime/js directory
- Merge api package into runtime/js/webcomponents
- Reorganize runtime/js packages for clearer module separation
- Move framework package to top-level src directory
- Merge async module into signal package
- Reorganize server-side packages and rename deprecated directory
- Extract signal module and reorganize package structure
- Replace proto_vdom with new reconcile module and update test config
- Migrate from mizchi/js/npm to mizchi/npm_typed
- Optimize experimental_hydrate and reorganize benchmarks
- Migrate tests to vitest and move loader to packages/loader
- Consolidate benchmarks into src/_bench directory
- Move JS backend-specific code to src/js/
- Use is_empty(), clear(), and for-in loops in hydration code
- Use Array methods instead of manual loops
- Fix deprecated syntax in async_render.mbt
- Remove 'v' prefix from element/attr helper functions
- Replace C-style for loops with idiomatic for-in and iterators
- Separate element/attr helpers into dedicated package
- Unify hydrate and hydrate_with_options into single function
- Merge HydrationOptions into HydrationContext
- Unify HydrationOptions with labeled arguments
- Restructure packages and add TypeScript wrapper with camelCase API
- Eliminate .to_node() calls by returning Node from element functions
- Restructure packages and add TypeScript wrapper with camelCase API
- Use iterator pattern for cleaner loop syntax

### Security

- Remove url: prefix from ln:state for SSRF mitigation

### Styling

- **astra**: Add centered blog layout CSS
- **i18n**: Add globe emoji to language switcher trigger
- **examples**: Apply moon fmt to wiki example
- **astra**: Apply moon fmt formatting
- Fix moon fmt artifacts in doc comments

### Testing

- **sol**: Add E2E tests for CSS utilities + WebComponent boundary
- **css**: Add comprehensive unit tests for CSS utilities
- **luna**: Add forEach + SVG browser tests
- **astra**: Add E2E tests for _slug_ dynamic routes
- Add E2E and Vitest tests for Cloudflare deploy target
- Migrate jsx-runtime tests from bun:test to vitest
- **todomvc**: Stabilize edit tests with proper state synchronization
- **sol**: Add layout nesting depth tests
- Add unit tests for core/ssg module
- Enable conditional example test in spa.test.ts
- Update visual snapshots
- **astra**: Add E2E tests for dark theme toggle
- **astra**: Add E2E tests for HMR hot reload
- **sol**: Add E2E tests for sol_app example
- Add comprehensive signal behavior comparison tests
- Remove redundant E2E tests (csr-router, shard)
- **sol**: Add runtime_test.mbt for IslandConfig and StaticFileConfig
- **sol**: Add SSR/Hydration E2E tests inspired by Next.js patterns
- Add Router API exports and expand test coverage
- Improve coverage for platform/dom/client and core modules
- **e2e**: Add snapshot tests and remove debug logs
- **e2e**: Add Playwright tests for ref_ element reference feature
- **router**: Add SSR tests and fix path normalization
- Add coverage tests for signals, combinators, effects, and resume state
- Add defer cleanup to hydration tests and scope querySelector to container
- Add comprehensive hydration tests with SSR integration
- Rewrite signals tests with bun:test and add Owner system tests

### Bench

- Add render_to_string benchmarks for cross-target comparison

### Config

- Use dot reporter for vitest and playwright

### Examples

- **astra_app**: Add foo.html to test HTML file support
- Add astra_app demo for Unified Progressive Architecture

### V0.0.3

- Refactor VNode API - remove v prefix and improve naming

### Wip

- **astra**: Integrate CSS utility extraction into build pipeline
- **astra**: Add inject-utility-css command for build integration
- **luna/css**: Add static CSS extractor with warning detection
- Add middleware system with Railway Oriented Programming
- Misc changes
- Add types package generation for Props structs
- Sol generate - parse mbti with moonbitlang/parser


