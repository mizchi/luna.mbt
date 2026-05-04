/**
 * CSS Runtime Expander - ~200 bytes minified
 *
 * Expands compressed CSS format at runtime.
 * Trade CPU for bandwidth - good for large CSS bundles.
 */

/**
 * Expand compressed CSS payload and inject into document
 * @param {Object} payload - { D: declaration dict, U: utility defs, M: class mapping }
 */
export function expandCSS(payload) {
  const { D, U, M } = payload;
  let css = '';

  // Expand utilities
  for (const [name, encoded] of Object.entries(U)) {
    const decls = [];
    // Each char in encoded is a key in D
    for (let i = 0; i < encoded.length; i++) {
      const key = encoded[i];
      if (D[key]) decls.push(D[key]);
    }
    css += `.${name}{${decls.join(';')}}\n`;
  }

  // Inject style
  const style = document.createElement('style');
  style.textContent = css;
  document.head.appendChild(style);

  return M; // Return class mapping for element transformation
}

/**
 * Transform element classes using mapping
 * @param {Element} element
 * @param {Object} mapping - original class → utility classes
 */
export function transformClasses(element, mapping) {
  const classes = element.className.split(' ');
  const newClasses = [];

  for (const cls of classes) {
    if (mapping[cls]) {
      newClasses.push(...mapping[cls].split(' '));
    } else {
      newClasses.push(cls);
    }
  }

  element.className = [...new Set(newClasses)].join(' ');
}

// Minified version for embedding (~180 bytes)
export const minifiedRuntime = `function e(p){const{D,U,M}=p;let c='';for(const[n,e]of Object.entries(U)){const d=[];for(let i=0;i<e.length;i++)D[e[i]]&&d.push(D[e[i]]);c+='.'+n+'{'+d.join(';')+'}\\n'}const s=document.createElement('style');s.textContent=c;document.head.appendChild(s);return M}`;

// Demo
if (typeof window !== 'undefined') {
  window.expandCSS = expandCSS;
  window.transformClasses = transformClasses;
}
