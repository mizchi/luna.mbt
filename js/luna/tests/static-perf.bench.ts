import { bench, describe } from "vitest";

// Generate HTML for list items
function generateListHTML(count: number): string {
  let html = "<ul>";
  for (let i = 0; i < count; i++) {
    html += `<li>Item ${i}</li>`;
  }
  html += "</ul>";
  return html;
}

// Generate DOM using createElement (like render_vnode_to_dom)
function createListDOM(count: number): Node {
  const ul = document.createElement("ul");
  for (let i = 0; i < count; i++) {
    const li = document.createElement("li");
    li.textContent = `Item ${i}`;
    ul.appendChild(li);
  }
  return ul;
}

describe("Static Content: innerHTML vs createElement (Real Browser)", () => {
  const html100 = generateListHTML(100);
  const html500 = generateListHTML(500);
  const html1000 = generateListHTML(1000);

  describe("100 items", () => {
    bench("createElement (render_vnode_to_dom style)", () => {
      const container = document.createElement("div");
      container.appendChild(createListDOM(100));
    });

    bench("innerHTML (inject_static style)", () => {
      const container = document.createElement("div");
      container.innerHTML = html100;
    });
  });

  describe("500 items", () => {
    bench("createElement (render_vnode_to_dom style)", () => {
      const container = document.createElement("div");
      container.appendChild(createListDOM(500));
    });

    bench("innerHTML (inject_static style)", () => {
      const container = document.createElement("div");
      container.innerHTML = html500;
    });
  });

  describe("1000 items", () => {
    bench("createElement (render_vnode_to_dom style)", () => {
      const container = document.createElement("div");
      container.appendChild(createListDOM(1000));
    });

    bench("innerHTML (inject_static style)", () => {
      const container = document.createElement("div");
      container.innerHTML = html1000;
    });
  });
});
