///| Benchmark for SSG markdown parser (pure MoonBit implementation)

// Sample markdown documents for benchmarking
let small_md : String = "# Title\n\nHello **world**.\n\n- Item 1\n- Item 2\n"

let medium_md : String = "---\ntitle: Test\ndescription: A test doc\n---\n\n# Main Title\n\nThis is a paragraph with *emphasis* and **strong** text.\n\n## Section 1\n\nMore content here with `code` inline.\n\n```javascript\nconst x = 1;\nconsole.log(x);\n```\n\n### Subsection\n\n- Item one\n- Item two\n- Item three\n\n> This is a blockquote\n> with multiple lines\n\n## Section 2\n\n| Header 1 | Header 2 |\n|----------|----------|\n| Cell 1   | Cell 2   |\n| Cell 3   | Cell 4   |\n\n[Link text](https://example.com)\n\n![Image](image.png \"Title\")\n"

fn generate_large_md() -> String {
  let buf = StringBuilder::new()
  buf.write_string("# Large Document\n\n")
  for i = 0; i < 50; i = i + 1 {
    buf.write_string("## Section \{i + 1}\n\n")
    buf.write_string("Paragraph with *emphasis* and **strong** and `code`.\n\n")
    buf.write_string("- Item 1\n- Item 2\n- Item 3\n\n")
    buf.write_string("```javascript\nconst x = \{i};\n```\n\n")
  }
  buf.to_string()
}

let large_md : String = generate_large_md()

// parse_markdown benchmarks (uses native MoonBit implementation)
test "parse_markdown: small document" (b : @bench.T) {
  b.bench(fn() {
    let result = parse_markdown(small_md)
    b.keep(result)
  })
}

test "parse_markdown: medium document" (b : @bench.T) {
  b.bench(fn() {
    let result = parse_markdown(medium_md)
    b.keep(result)
  })
}

test "parse_markdown: large document (50 sections)" (b : @bench.T) {
  b.bench(fn() {
    let result = parse_markdown(large_md)
    b.keep(result)
  })
}
