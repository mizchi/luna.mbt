// ColorPalette - TSX SSR component for the components demo.
//
// Renders three labeled color swatches at build time via React's
// renderToString (the renderer is selected by page.json's
// "renderer": "react"). No client JS is shipped — output is plain HTML.

const SWATCHES = [
  { hex: "#4f46e5", name: "Indigo" },
  { hex: "#10b981", name: "Emerald" },
  { hex: "#f59e0b", name: "Amber" },
];

export default function ColorPalette() {
  return (
    <div className="color-palette-component">
      <h2>ColorPalette (TSX)</h2>
      <p>Three swatches rendered server-side from a .tsx file via React renderToString.</p>
      <div className="color-palette-swatches">
        {SWATCHES.map((s) => (
          <span
            key={s.hex}
            className="swatch"
            style={{ background: s.hex }}
            title={s.name}
          >
            {s.hex}
          </span>
        ))}
      </div>
    </div>
  );
}
