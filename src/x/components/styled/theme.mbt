///|
/// Theme Variables for Luna Styled Components
///
/// CSS custom properties for theming. Import this in your app
/// and include the CSS output to enable theming.

///|
/// CSS variables for theming
pub fn theme_variables() -> String {
  let css =
    #|:root {
    #|  /* Base colors */
    #|  --background: #ffffff;
    #|  --foreground: #1f2937;
    #|  --muted: #f3f4f6;
    #|  --muted-foreground: #6b7280;
    #|  --border: #e5e7eb;
    #|  --accent: #3b82f6;
    #|  --accent-foreground: #ffffff;
    #|  --switch-track-off: #d1d5db;
    #|  --switch-track-on: #3b82f6;
    #|
    #|  /* Link */
    #|  --link-color: #2563eb;
    #|  --link-hover: #1d4ed8;
    #|}
    #|
    #|:root[data-theme="dark"] {
    #|  /* Base colors */
    #|  --background: #1f2937;
    #|  --foreground: #f9fafb;
    #|  --muted: #374151;
    #|  --muted-foreground: #9ca3af;
    #|  --border: #374151;
    #|  --accent: #3b82f6;
    #|  --accent-foreground: #ffffff;
    #|  --switch-track-off: #4b5563;
    #|  --switch-track-on: #3b82f6;
    #|
    #|  /* Link */
    #|  --link-color: #60a5fa;
    #|  --link-hover: #93c5fd;
    #|}
    #|
    #|/* System dark mode (when no explicit theme is set) */
    #|@media (prefers-color-scheme: dark) {
    #|  :root:not([data-theme]) {
    #|    /* Base colors */
    #|    --background: #1f2937;
    #|    --foreground: #f9fafb;
    #|    --muted: #374151;
    #|    --muted-foreground: #9ca3af;
    #|    --border: #374151;
    #|    --accent: #3b82f6;
    #|    --accent-foreground: #ffffff;
    #|    --switch-track-off: #4b5563;
    #|    --switch-track-on: #3b82f6;
    #|
    #|    /* Link */
    #|    --link-color: #60a5fa;
    #|    --link-hover: #93c5fd;
    #|  }
    #|}
  css
}
