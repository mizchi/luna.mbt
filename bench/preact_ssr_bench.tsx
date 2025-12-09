/** @jsxImportSource preact */
import { h } from "preact";
import { render } from "preact-render-to-string";

// =============================================================================
// Basic Rendering
// =============================================================================

Deno.bench("preact_ssr_simple_text", () => {
  render(<span>Hello, World!</span>);
});

Deno.bench("preact_ssr_simple_div", () => {
  render(<div></div>);
});

Deno.bench("preact_ssr_div_with_text", () => {
  render(<div>Hello</div>);
});

Deno.bench("preact_ssr_div_with_attrs", () => {
  render(<div id="main" class="container">Content</div>);
});

// =============================================================================
// Nested Elements
// =============================================================================

Deno.bench("preact_ssr_nested_3_levels", () => {
  render(
    <div>
      <div>
        <div>deep</div>
      </div>
    </div>
  );
});

Deno.bench("preact_ssr_nested_5_levels", () => {
  render(
    <div>
      <div>
        <div>
          <div>
            <div>very deep</div>
          </div>
        </div>
      </div>
    </div>
  );
});

Deno.bench("preact_ssr_nested_10_levels", () => {
  render(
    <div>
      <div>
        <div>
          <div>
            <div>
              <div>
                <div>
                  <div>
                    <div>
                      <div>extremely deep</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
});

// =============================================================================
// Lists
// =============================================================================

Deno.bench("preact_ssr_list_10_items", () => {
  const items = Array.from({ length: 10 }, (_, i) => <li key={i}>Item {i}</li>);
  render(<ul>{items}</ul>);
});

Deno.bench("preact_ssr_list_100_items", () => {
  const items = Array.from({ length: 100 }, (_, i) => <li key={i}>Item {i}</li>);
  render(<ul>{items}</ul>);
});

Deno.bench("preact_ssr_list_1000_items", () => {
  const items = Array.from({ length: 1000 }, (_, i) => <li key={i}>Item {i}</li>);
  render(<ul>{items}</ul>);
});

// =============================================================================
// Complex Components
// =============================================================================

function Card({ title, content }: { title: string; content: string }) {
  return (
    <div class="card">
      <div class="card-header">
        <h3>{title}</h3>
      </div>
      <div class="card-body">
        <p>{content}</p>
      </div>
      <div class="card-footer">
        <button class="btn">Action</button>
      </div>
    </div>
  );
}

Deno.bench("preact_ssr_card_component", () => {
  render(<Card title="Title" content="Some content here" />);
});

Deno.bench("preact_ssr_100_cards", () => {
  const cards = Array.from({ length: 100 }, (_, i) => (
    <div class="card" key={i}>
      <div class="card-header">
        <h3>Card {i}</h3>
      </div>
      <div class="card-body">
        <p>Content {i}</p>
      </div>
    </div>
  ));
  render(<div class="cards">{cards}</div>);
});

// =============================================================================
// Style Rendering
// =============================================================================

Deno.bench("preact_ssr_inline_style", () => {
  render(<div style={{ color: "red", fontSize: "16px", marginTop: "10px" }}></div>);
});

// =============================================================================
// Full Page Simulation
// =============================================================================

function Nav() {
  return (
    <div class="nav">
      <a href="/">Home</a>
      <a href="/about">About</a>
      <a href="/contact">Contact</a>
    </div>
  );
}

function Header({ title }: { title: string }) {
  return (
    <div class="header">
      <h1>{title}</h1>
    </div>
  );
}

function Sidebar() {
  return (
    <div class="sidebar">
      <ul>
        <li>Menu 1</li>
        <li>Menu 2</li>
        <li>Menu 3</li>
      </ul>
    </div>
  );
}

function Content() {
  return (
    <div class="content">
      <p>Welcome to our site!</p>
      <p>This is some content.</p>
    </div>
  );
}

function Footer() {
  return <div class="footer">© 2025</div>;
}

Deno.bench("preact_ssr_full_page", () => {
  render(
    <div class="page">
      <Nav />
      <Header title="My Website" />
      <div class="main">
        <Sidebar />
        <Content />
      </div>
      <Footer />
    </div>
  );
});

function BlogPost({ index }: { index: number }) {
  return (
    <div class="post">
      <h2>Post Title {index}</h2>
      <p class="meta">Posted on 2025-01-01</p>
      <p>
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod
        tempor incididunt ut labore et dolore magna aliqua.
      </p>
      <div class="tags">
        <span class="tag">MoonBit</span>
        <span class="tag">SSR</span>
      </div>
    </div>
  );
}

Deno.bench("preact_ssr_blog_page_10_posts", () => {
  const posts = Array.from({ length: 10 }, (_, i) => <BlogPost key={i} index={i} />);
  render(
    <div class="blog">
      <h1>My Blog</h1>
      <div class="posts">{posts}</div>
    </div>
  );
});
