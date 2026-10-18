// Component SSR - Server-side rendering for Luna and TSX components

// =============================================================================
// Luna Component SSR
// =============================================================================

///|
/// Try to render a component from its compiled module (async)
/// Returns Some(vnode) if successful, None if component cannot be loaded
async fn render_component_ssr_async(
  cwd : String,
  docs_dir : String,
  source_path : String,
) -> @luna.Node[Unit, String]? {
  let component_name = get_component_name_from_path(source_path)

  // Get parent project root (for examples that are subdirectories)
  let parent_root = @path.dirname(@path.dirname(cwd))

  // Try multiple possible locations for the compiled component
  let possible_paths = [
    // 1. Direct component name (most common for standalone projects)
    @path.join2(
      @path.join2(cwd, "_build/js/release/build"),
      component_name + "/" + component_name + ".js",
    ),
    // 2. Standard docs directory convention
    @path.join2(
      @path.join2(cwd, "_build/js/release/build/docs"),
      source_path + "/" + component_name + ".js",
    ),
    // 3. Flat structure (component directly in docs build)
    @path.join2(
      @path.join2(cwd, "_build/js/release/build/docs"),
      component_name + "/" + component_name + ".js",
    ),
    // 4. Tests directory (for testing SSR)
    @path.join2(
      @path.join2(cwd, "_build/js/release/build/tests"),
      component_name + "/" + component_name + ".js",
    ),
    // 5. Source-relative build
    @path.join2(
      @path.join2(cwd, "_build/js/release/build"),
      source_path + "/" + component_name + ".js",
    ),
    // 6. Parent project's tests directory (for examples in subdirectories)
    @path.join2(
      @path.join2(parent_root, "_build/js/release/build/tests"),
      component_name + "/" + component_name + ".js",
    ),
    // 7. Parent project's source build
    @path.join2(
      @path.join2(parent_root, "_build/js/release/build"),
      source_path + "/" + component_name + ".js",
    ),
  ]

  // Namespaced artifacts may live in this module or an ancestor workspace.
  let mut module_path = ffi_find_compiled_component(cwd, docs_dir, source_path).wait()
  for path in possible_paths {
    if module_path is None && @fs.existsSync(path) {
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
async fn load_component_module(
  module_path : String,
) -> @luna.Node[Unit, String]? {
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
  #|     const { pathToFileURL } = await import('node:url');
  #|     const { resolve } = await import('node:path');
  #|     const fileUrl = pathToFileURL(resolve(modulePath)).href;
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
  #|     const { pathToFileURL } = await import('node:url');
  #|     const { randomUUID } = await import('node:crypto');
  #|     tsxPath = path.resolve(tsxPath);
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
  #|     const tempFile = path.join(tempDir, '.tsx_temp_' + randomUUID() + '.mjs');
  #|     fs.writeFileSync(tempFile, result.code);
  #|
  #|     try {
  #|       const mod = await import(pathToFileURL(tempFile).href);
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
    let buf = StringBuilder()
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

///|
/// Locate Moon's namespaced JS artifact without assuming a fixed repository
/// depth. Module names and source directories come from its own manifest.
extern "js" fn ffi_find_compiled_component(
  cwd : String,
  docs_dir : String,
  source_path : String,
) -> @js.Promise[String?] =
  #| async (cwd, docsDir, sourcePath) => {
  #|   const fs = await import('node:fs');
  #|   const path = await import('node:path');
  #|   const project = path.resolve(cwd);
  #|   try {
  #|     let manifest;
  #|     const modern = path.join(project, 'moon.mod');
  #|     if (fs.existsSync(modern)) {
  #|       const text = fs.readFileSync(modern, 'utf8');
  #|       const field = (pattern) => {
  #|         const match = text.match(pattern);
  #|         return match ? JSON.parse(match[1]) : undefined;
  #|       };
  #|       manifest = {
  #|         name: field(/^name\s*=\s*("(?:[^"\\]|\\.)*")/m),
  #|         source: field(/^source\s*=\s*("(?:[^"\\]|\\.)*")/m),
  #|       };
  #|     } else {
  #|       manifest = JSON.parse(fs.readFileSync(path.join(project, 'moon.mod.json'), 'utf8'));
  #|     }
  #|     if (!manifest.name) return undefined;
  #|     const sourceRoot = path.resolve(project, manifest.source || '.');
  #|     const packageDir = path.resolve(project, docsDir, sourcePath);
  #|     const relative = path.relative(sourceRoot, packageDir);
  #|     if (relative.startsWith('..') || path.isAbsolute(relative)) return undefined;
  #|     const entry = path.join(relative, path.basename(packageDir) + '.js');
  #|     for (let dir = project; ; dir = path.dirname(dir)) {
  #|       const base = path.join(dir, '_build/js/release/build');
  #|       for (const candidate of [path.join(base, manifest.name, entry), path.join(base, entry)]) {
  #|         if (fs.existsSync(candidate)) return candidate;
  #|       }
  #|       if (dir === path.dirname(dir)) return undefined;
  #|     }
  #|   } catch {
  #|     return undefined;
  #|   }
  #| }
