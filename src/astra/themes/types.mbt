// Astra Themes - Type Definitions
// Defines the structure for customizable themes

///|
/// Theme layout type
pub(all) enum ThemeLayout {
  /// Documentation site layout (sidebar + content + TOC)
  Doc
  /// Home/Landing page layout (full-width, no sidebar)
  Home
  /// Blog layout (content-focused, optional sidebar)
  Blog
  /// Landing page layout (hero sections, CTAs)
  Landing
}

///|
/// Theme color scheme
pub(all) struct ThemeColors {
  /// Primary accent color (e.g., "#b45309")
  primary : String
  /// Text color
  text : String
  /// Muted text color
  text_muted : String
  /// Background color
  background : String
  /// Sidebar background
  sidebar_bg : String
  /// Border color
  border : String
  /// Code block background
  code_bg : String
}

///|
/// Theme configuration
pub(all) struct Theme {
  /// Theme name identifier
  name : String
  /// Default layout for this theme
  default_layout : ThemeLayout
  /// Light mode colors
  light_colors : ThemeColors
  /// Dark mode colors
  dark_colors : ThemeColors
  /// Custom CSS to inject (optional)
  custom_css : String?
}

///|
/// Default light mode colors
pub fn default_light_colors() -> ThemeColors {
  {
    primary: "#b45309",
    text: "#1f2937",
    text_muted: "#4b5563",
    background: "#ffffff",
    sidebar_bg: "#fafafa",
    border: "#e5e7eb",
    code_bg: "#f3f4f6",
  }
}

///|
/// Default dark mode colors
pub fn default_dark_colors() -> ThemeColors {
  {
    primary: "#fbbf24",
    text: "#f3f4f6",
    text_muted: "#d1d5db",
    background: "#0f0f0f",
    sidebar_bg: "#171717",
    border: "#2d2d2d",
    code_bg: "#1f1f1f",
  }
}

///|
/// Default documentation theme
pub fn default_theme() -> Theme {
  {
    name: "default",
    default_layout: Doc,
    light_colors: default_light_colors(),
    dark_colors: default_dark_colors(),
    custom_css: None,
  }
}

///|
/// Blog theme - content-focused with wider main area
pub fn blog_theme() -> Theme {
  let custom =
    #|.doc-main { max-width: 720px; margin-left: auto; margin-right: auto; }
    #|.sidebar { display: none; }
    #|.toc { display: none; }
  {
    name: "blog",
    default_layout: Blog,
    light_colors: default_light_colors(),
    dark_colors: default_dark_colors(),
    custom_css: Some(custom),
  }
}

///|
/// Minimal theme - clean and simple
pub fn minimal_theme() -> Theme {
  {
    name: "minimal",
    default_layout: Home,
    light_colors: {
      primary: "#2563eb",
      text: "#111827",
      text_muted: "#6b7280",
      background: "#ffffff",
      sidebar_bg: "#f9fafb",
      border: "#e5e7eb",
      code_bg: "#f3f4f6",
    },
    dark_colors: {
      primary: "#60a5fa",
      text: "#f9fafb",
      text_muted: "#9ca3af",
      background: "#111827",
      sidebar_bg: "#1f2937",
      border: "#374151",
      code_bg: "#1f2937",
    },
    custom_css: None,
  }
}

///|
/// Generate CSS variables from theme colors
pub fn colors_to_css_vars(colors : ThemeColors) -> String {
  "  --primary-color: \{colors.primary};\n" +
  "  --text-color: \{colors.text};\n" +
  "  --text-muted: \{colors.text_muted};\n" +
  "  --bg-color: \{colors.background};\n" +
  "  --sidebar-bg: \{colors.sidebar_bg};\n" +
  "  --border-color: \{colors.border};\n" +
  "  --code-bg: \{colors.code_bg};\n" +
  "  --link-color: var(--primary-color);\n" +
  "  --nav-link-color: var(--text-muted);"
}

///|
/// Generate complete theme CSS
pub fn theme_to_css(theme : Theme) -> String {
  let light_vars = colors_to_css_vars(theme.light_colors)
  let dark_vars = colors_to_css_vars(theme.dark_colors)

  let mut css = ":root {\n\{light_vars}\n}\n\n" +
    "html.dark {\n\{dark_vars}\n}\n\n" +
    "@media (prefers-color-scheme: dark) {\n" +
    "  :root:not(.light) {\n\{dark_vars}\n  }\n}"

  // Add custom CSS if provided
  if theme.custom_css is Some(custom) {
    css = css + "\n\n/* Custom theme styles */\n" + custom
  }
  css
}
