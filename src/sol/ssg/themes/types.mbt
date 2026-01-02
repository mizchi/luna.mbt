// Sol SSG Themes - Type Definitions
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
  // === Core Colors ===
  /// Primary accent color (e.g., "#b45309")
  primary : String
  /// Secondary color (navigation highlights, subtle accents)
  secondary : String
  /// Accent color (hover states, selections)
  accent : String

  // === Semantic Colors ===
  /// Success state color (green)
  success : String
  /// Warning state color (yellow/orange)
  warning : String
  /// Error state color (red)
  error : String

  // === Text Colors ===
  /// Text color
  text : String
  /// Muted text color
  text_muted : String
  /// Heading text color
  heading : String
  /// Link color
  link : String
  /// Link hover color
  link_hover : String

  // === Background Colors ===
  /// Background color
  background : String
  /// Surface color (cards, modals)
  surface : String
  /// Sidebar background
  sidebar_bg : String
  /// Input field background
  input_bg : String
  /// Code block background
  code_bg : String

  // === UI Colors ===
  /// Border color
  border : String
  /// Focus ring color
  focus_ring : String
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
    // Core colors
    primary: "#b45309", // Amber-700
    secondary: "#6b7280", // Gray-500
    accent: "#f59e0b", // Amber-500
    // Semantic colors
    success: "#16a34a", // Green-600
    warning: "#d97706", // Amber-600
    error: "#dc2626", // Red-600
    // Text colors
    text: "#1f2937", // Gray-800
    text_muted: "#4b5563", // Gray-600
    heading: "#111827", // Gray-900
    link: "#b45309", // Same as primary
    link_hover: "#92400e", // Amber-800
    // Background colors
    background: "#ffffff",
    surface: "#fafafa", // Gray-50
    sidebar_bg: "#fafafa",
    input_bg: "#ffffff",
    code_bg: "#f3f4f6", // Gray-100
    // UI colors
    border: "#e5e7eb", // Gray-200
    focus_ring: "#f59e0b", // Amber-500
  }
}

///|
/// Default dark mode colors
pub fn default_dark_colors() -> ThemeColors {
  {
    // Core colors
    primary: "#fbbf24", // Amber-400
    secondary: "#9ca3af", // Gray-400
    accent: "#fcd34d", // Amber-300
    // Semantic colors
    success: "#22c55e", // Green-500
    warning: "#f59e0b", // Amber-500
    error: "#ef4444", // Red-500
    // Text colors
    text: "#f3f4f6", // Gray-100
    text_muted: "#d1d5db", // Gray-300
    heading: "#ffffff",
    link: "#fbbf24", // Same as primary
    link_hover: "#fcd34d", // Amber-300
    // Background colors
    background: "#0f0f0f",
    surface: "#171717",
    sidebar_bg: "#171717",
    input_bg: "#1f1f1f",
    code_bg: "#1f1f1f",
    // UI colors
    border: "#2d2d2d",
    focus_ring: "#fbbf24", // Amber-400
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
/// Minimal theme - clean and simple (Blue theme)
pub fn minimal_theme() -> Theme {
  {
    name: "minimal",
    default_layout: Home,
    light_colors: {
      // Core colors (Blue palette)
      primary: "#2563eb", // Blue-600
      secondary: "#6b7280", // Gray-500
      accent: "#3b82f6", // Blue-500
      // Semantic colors
      success: "#16a34a",
      warning: "#d97706",
      error: "#dc2626",
      // Text colors
      text: "#111827", // Gray-900
      text_muted: "#6b7280", // Gray-500
      heading: "#030712", // Gray-950
      link: "#2563eb",
      link_hover: "#1d4ed8", // Blue-700
      // Background colors
      background: "#ffffff",
      surface: "#f9fafb", // Gray-50
      sidebar_bg: "#f9fafb",
      input_bg: "#ffffff",
      code_bg: "#f3f4f6",
      // UI colors
      border: "#e5e7eb",
      focus_ring: "#3b82f6", // Blue-500
    },
    dark_colors: {
      // Core colors (Blue palette)
      primary: "#60a5fa", // Blue-400
      secondary: "#9ca3af", // Gray-400
      accent: "#93c5fd", // Blue-300
      // Semantic colors
      success: "#22c55e",
      warning: "#f59e0b",
      error: "#ef4444",
      // Text colors
      text: "#f9fafb",
      text_muted: "#9ca3af",
      heading: "#ffffff",
      link: "#60a5fa",
      link_hover: "#93c5fd", // Blue-300
      // Background colors
      background: "#111827", // Gray-900
      surface: "#1f2937", // Gray-800
      sidebar_bg: "#1f2937",
      input_bg: "#1f2937",
      code_bg: "#1f2937",
      // UI colors
      border: "#374151", // Gray-700
      focus_ring: "#60a5fa", // Blue-400
    },
    custom_css: None,
  }
}

///|
/// Generate CSS variables from theme colors
pub fn colors_to_css_vars(colors : ThemeColors) -> String {
  // Core colors
  "  --primary-color: \{colors.primary};\n" +
  "  --secondary-color: \{colors.secondary};\n" +
  "  --accent-color: \{colors.accent};\n" +
  // Semantic colors
  "  --success-color: \{colors.success};\n" +
  "  --warning-color: \{colors.warning};\n" +
  "  --error-color: \{colors.error};\n" +
  // Text colors
  "  --text-color: \{colors.text};\n" +
  "  --text-muted: \{colors.text_muted};\n" +
  "  --heading-color: \{colors.heading};\n" +
  "  --link-color: \{colors.link};\n" +
  "  --link-hover-color: \{colors.link_hover};\n" +
  // Background colors
  "  --bg-color: \{colors.background};\n" +
  "  --surface-color: \{colors.surface};\n" +
  "  --sidebar-bg: \{colors.sidebar_bg};\n" +
  "  --input-bg: \{colors.input_bg};\n" +
  "  --code-bg: \{colors.code_bg};\n" +
  // UI colors
  "  --border-color: \{colors.border};\n" +
  "  --focus-ring-color: \{colors.focus_ring};\n" +
  // Aliases for compatibility
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
