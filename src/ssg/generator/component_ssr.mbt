// Component SSR - Server-side rendering for Luna and TSX components

// =============================================================================
// Luna Component SSR
// =============================================================================

///|
/// Try to render a component from its compiled module (async)
/// Returns Some(vnode) if successful, None if component cannot be loaded
async fn render_component_ssr_async(
  cwd : String,
  source_path : String,
) -> @luna.Node[Unit, String]? {
  let component_name = get_component_name_from_path(source_path)

  // Get parent project root (for examples that are subdirectories)
  let parent_root = @path.dirname(@path.dirname(cwd))

  // Try multiple possible locations for the compiled component
  let possible_paths = [
    // 1. Direct component name (most common for standalone projects)
    @path.join2(
      @path.join2(cwd, "target/js/release/build"),
      component_name + "/" + component_name + ".js",
    ),
    // 2. Standard docs directory convention
    @path.join2(
      @path.join2(cwd, "target/js/release/build/docs"),
      source_path + "/" + component_name + ".js",
    ),
    // 3. Flat structure (component directly in docs build)
    @path.join2(
      @path.join2(cwd, "target/js/release/build/docs"),
      component_name + "/" + component_name + ".js",
    ),
    // 4. Tests directory (for testing SSR)
    @path.join2(
      @path.join2(cwd, "target/js/release/build/tests"),
      component_name + "/" + component_name + ".js",
    ),
    // 5. Source-relative build
    @path.join2(
      @path.join2(cwd, "target/js/release/build"),
      source_path + "/" + component_name + ".js",
    ),
    // 6. Parent project's tests directory (for examples in subdirectories)
    @path.join2(
      @path.join2(parent_root, "target/js/release/build/tests"),
      component_name + "/" + component_name + ".js",
    ),
    // 7. Parent project's source build
    @path.join2(
      @path.join2(parent_root, "target/js/release/build"),
      source_path + "/" + component_name + ".js",
    ),
  ]

  // Find first existing module
  let mut module_path : String? = None
  for path in possible_paths {
    if @fs.existsSync(path) {
      module_path = Some(path)
      break
    }
  }

  // Check if any module was found
  guard module_path is Some(path) else {
    println(
      "  Warning: Component '\{component_name}' not compiled. Tried paths:",
    )
    for p in possible_paths {
      println("    - \{p}")
    }
    return None
  }

  // Load the module and call render()
  match load_component_module(path) {
    Some(vnode) => {
      println("  SSR: Component '\{component_name}' rendered successfully")
      Some(vnode)
    }
    None => {
      println(
        "  Warning: Component '\{component_name}' has no render() function",
      )
      None
    }
  }
}

///|
/// Load a component module and call its render() function
/// Uses dynamic import and expects the module to export a render() function
async fn load_component_module(module_path : String) -> @luna.Node[Unit, String]? {
  ffi_load_component_render(module_path).wait()
}

///|
/// FFI to dynamically import a component module and call render()
/// Returns a Promise that resolves to the VNode or undefined
extern "js" fn ffi_load_component_render(
  module_path : String,
) -> @js.Promise[@luna.Node[Unit, String]?] =
  #| async (modulePath) => {
  #|   try {
  #|     // Use file:// URL for Node.js dynamic import
  #|     const fileUrl = 'file://' + modulePath;
  #|     const mod = await import(fileUrl);
  #|     if (typeof mod.render === 'function') {
  #|       return mod.render();
  #|     }
  #|     return undefined;
  #|   } catch (e) {
  #|     console.error('  Error loading component:', e.message);
  #|     return undefined;
  #|   }
  #| }

///|
/// Synchronous wrapper for component SSR (for backwards compatibility)
/// Falls back to placeholder if async loading is not available
fn render_component_ssr(
  _cwd : String,
  source_path : String,
) -> @luna.Node[Unit, String]? {
  let component_name = get_component_name_from_path(source_path)
  println("  Info: Component '\{component_name}' - use async build for SSR")
  None
}

// =============================================================================
// TSX Component SSR
// =============================================================================

///|
/// Render a TSX component via Node.js (async)
/// Looks for <dirname>.tsx or index.tsx and calls its default export
async fn render_tsx_component_ssr_async(
  cwd : String,
  docs_dir : String,
  source_path : String,
) -> @luna.Node[Unit, String]? {
  let component_name = get_component_name_from_path(source_path)

  // Build the TSX file path
  // Try <component_name>.tsx first, then index.tsx
  let tsx_path = @path.join2(
    @path.join2(@path.join2(cwd, docs_dir), source_path),
    component_name + ".tsx",
  )
  let tsx_index_path = @path.join2(
    @path.join2(@path.join2(cwd, docs_dir), source_path),
    "index.tsx",
  )
  let actual_path = if @fs.existsSync(tsx_path) {
    tsx_path
  } else if @fs.existsSync(tsx_index_path) {
    tsx_index_path
  } else {
    println(
      "  Warning: TSX component '\{component_name}' not found at \{tsx_path}",
    )
    return None
  }

  // Call Node.js to render the TSX component
  match load_tsx_component(actual_path) {
    Some(html) => {
      println("  SSR: TSX component '\{component_name}' rendered successfully")
      Some(@luna.raw_html(html))
    }
    None => {
      println("  Warning: TSX component '\{component_name}' SSR failed")
      None
    }
  }
}

///|
/// Load and render a TSX component via FFI
async fn load_tsx_component(tsx_path : String) -> String? {
  ffi_render_tsx_component(tsx_path).wait()
}

///|
/// FFI to render a TSX component using Node.js
/// Uses esbuild to transform TSX and React to render
extern "js" fn ffi_render_tsx_component(
  tsx_path : String,
) -> @js.Promise[String?] =
  #| async (tsxPath) => {
  #|   try {
  #|     const fs = await import('fs');
  #|     const path = await import('path');
  #|     const { createRequire } = await import('module');
  #|
  #|     // Find workspace root by looking for pnpm-workspace.yaml or package.json
  #|     const findWorkspaceRoot = (startDir) => {
  #|       let dir = startDir;
  #|       while (dir !== path.dirname(dir)) {
  #|         if (fs.existsSync(path.join(dir, 'pnpm-workspace.yaml'))) return dir;
  #|         if (fs.existsSync(path.join(dir, 'pnpm-lock.yaml'))) return dir;
  #|         dir = path.dirname(dir);
  #|       }
  #|       return startDir; // fallback to start dir
  #|     };
  #|
  #|     // Create require function relative to workspace root (for pnpm hoisted deps)
  #|     const workspaceRoot = findWorkspaceRoot(path.dirname(tsxPath));
  #|     const rootRequire = createRequire(path.join(workspaceRoot, 'package.json'));
  #|
  #|     // Load dependencies from workspace root node_modules
  #|     const esbuild = rootRequire('esbuild');
  #|     const React = rootRequire('react');
  #|     const ReactDOMServer = rootRequire('react-dom/server');
  #|
  #|     // Read TSX source
  #|     const source = fs.readFileSync(tsxPath, 'utf-8');
  #|
  #|     // Transform TSX to JS using esbuild
  #|     const result = await esbuild.transform(source, {
  #|       loader: 'tsx',
  #|       jsx: 'automatic',
  #|       format: 'esm',
  #|       target: 'node18',
  #|     });
  #|
  #|     // Write to temp file and import
  #|     const tempDir = path.dirname(tsxPath);
  #|     const tempFile = path.join(tempDir, '.tsx_temp_' + Date.now() + '.mjs');
  #|     fs.writeFileSync(tempFile, result.code);
  #|
  #|     try {
  #|       const mod = await import('file://' + tempFile);
  #|       const Component = mod.default;
  #|       if (!Component) {
  #|         console.error('  TSX: No default export found');
  #|         return undefined;
  #|       }
  #|
  #|       const element = React.createElement(Component);
  #|       const html = ReactDOMServer.renderToString(element);
  #|       return html;
  #|     } finally {
  #|       // Cleanup temp file
  #|       try { fs.unlinkSync(tempFile); } catch {}
  #|     }
  #|   } catch (e) {
  #|     console.error('  TSX SSR error:', e.message);
  #|     return undefined;
  #|   }
  #| }

///|
/// Extract component name from source path
/// e.g., "counter" from "counter/" or "my-component" from "my-component/"
fn get_component_name_from_path(source_path : String) -> String {
  // Remove trailing slash if present
  let path = if source_path.has_suffix("/") {
    let len = source_path.length()
    let buf = StringBuilder::new()
    let mut idx = 0
    for c in source_path {
      if idx < len - 1 {
        buf.write_char(c)
      }
      idx = idx + 1
    }
    buf.to_string()
  } else {
    source_path
  }

  // Get last segment of path
  let mut last_slash = -1
  let mut idx = 0
  for c in path {
    if c == '/' {
      last_slash = idx
    }
    idx = idx + 1
  }
  if last_slash >= 0 && last_slash < path.length() - 1 {
    @utils.slice_view_from(path, last_slash + 1)
  } else {
    path
  }
}
