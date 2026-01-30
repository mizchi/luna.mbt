// Static Site Generator - Main Render Pipeline
//
// This module is the main entry point for static site generation.
// The implementation is split across multiple files for better maintainability:
//
// - html_utils.mbt: HTML/URL transformation utilities, sanitization
// - css_processor.mbt: CSS extraction, minification, utility processing
// - component_ssr.mbt: Server-side rendering for Luna and TSX components
// - asset_copier.mbt: Static asset copying, bundling, boot runtime
// - manifest_generator.mbt: Meta files and client manifest generation
// - html_builder.mbt: Page layout building and HTML document generation
// - page_generator.mbt: Site and page generation core logic
//
// Public API is re-exported from page_generator.mbt:
// - generate_site: Generate entire static site (sync)
// - generate_site_async: Generate entire static site (async, with Shiki)
// - generate_site_with_highlighter: Generate with pre-created highlighter
// - generate_single_page: Generate a single page (incremental builds)
//
// Other public functions:
// - copy_static_assets: Copy static assets (sync)
// - copy_static_assets_async: Copy static assets with CSS extraction (async)
// - generate_meta_files: Generate sitemap, RSS, llms.txt
// - generate_client_manifest: Generate client manifest for chunk loading
// - generate_404_page: Generate 404 error page
