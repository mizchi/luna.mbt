///| Markdown parser benchmarks
///| Run with: moon bench --target js -p mizchi/luna/core/markdown

///| Generate a sample markdown document of given size
fn generate_sample_markdown(paragraphs : Int) -> String {
  let buf = StringBuilder::new()

  // Frontmatter
  buf.write_string("---\n")
  buf.write_string("title: Benchmark Document\n")
  buf.write_string("author: Test\n")
  buf.write_string("---\n\n")

  // Title
  buf.write_string("# Benchmark Document\n\n")

  // Content
  for i = 0; i < paragraphs; i = i + 1 {
    // Heading
    buf.write_string("## Section \{i + 1}\n\n")

    // Paragraph
    buf.write_string("This is a paragraph of text. It contains some content that needs to be parsed. ")
    buf.write_string("Markdown is a lightweight markup language. ")
    buf.write_string("It is often used for formatting readme files.\n\n")

    // Code block
    buf.write_string("```javascript\n")
    buf.write_string("function hello() {\n")
    buf.write_string("  console.log('Hello, World!');\n")
    buf.write_string("}\n")
    buf.write_string("```\n\n")

    // List
    buf.write_string("- Item one\n")
    buf.write_string("- Item two\n")
    buf.write_string("- Item three\n\n")

    // Blockquote
    buf.write_string("> This is a blockquote.\n")
    buf.write_string("> It spans multiple lines.\n\n")
  }

  buf.to_string()
}

// Pre-generate test documents
let small_doc : String = generate_sample_markdown(5)

let medium_doc : String = generate_sample_markdown(20)

let large_doc : String = generate_sample_markdown(100)

test "parse: small document (5 sections)" (b : @bench.T) {
  b.bench(fn() {
    let result = parse(small_doc)
    b.keep(result)
  })
}

test "parse: medium document (20 sections)" (b : @bench.T) {
  b.bench(fn() {
    let result = parse(medium_doc)
    b.keep(result)
  })
}

test "parse: large document (100 sections)" (b : @bench.T) {
  b.bench(fn() {
    let result = parse(large_doc)
    b.keep(result)
  })
}

test "serialize: small document" (b : @bench.T) {
  let parsed = parse(small_doc)
  b.bench(fn() {
    let output = serialize(parsed.document)
    b.keep(output)
  })
}

test "serialize: medium document" (b : @bench.T) {
  let parsed = parse(medium_doc)
  b.bench(fn() {
    let output = serialize(parsed.document)
    b.keep(output)
  })
}

test "roundtrip: small document" (b : @bench.T) {
  b.bench(fn() {
    let result = parse(small_doc)
    let output = serialize(result.document)
    b.keep(output)
  })
}

test "roundtrip: medium document" (b : @bench.T) {
  b.bench(fn() {
    let result = parse(medium_doc)
    let output = serialize(result.document)
    b.keep(output)
  })
}

// === Granular benchmarks ===

// Inline parsing benchmarks
let inline_simple : String = "Hello World"

let inline_emphasis : String = "Hello *world* and **bold** and `code` here"

let inline_complex : String = "Check [this link](https://example.com \"title\") and ![image](img.png) with *emphasis* and **strong** and `code`"

let inline_many : String = "*a* **b** `c` *d* **e** `f` *g* **h** `i` *j* **k** `l`"

test "inline: simple text" (b : @bench.T) {
  b.bench(fn() {
    let result = parse_inlines(inline_simple)
    b.keep(result)
  })
}

test "inline: emphasis/strong/code" (b : @bench.T) {
  b.bench(fn() {
    let result = parse_inlines(inline_emphasis)
    b.keep(result)
  })
}

test "inline: links and images" (b : @bench.T) {
  b.bench(fn() {
    let result = parse_inlines(inline_complex)
    b.keep(result)
  })
}

test "inline: many markers" (b : @bench.T) {
  b.bench(fn() {
    let result = parse_inlines(inline_many)
    b.keep(result)
  })
}

// Table parsing benchmarks
let table_simple : String = "| A | B |\n|---|---|\n| 1 | 2 |\n"

let table_medium : String = "| Col1 | Col2 | Col3 | Col4 |\n|:---|:---:|---:|---|\n| a | b | c | d |\n| e | f | g | h |\n| i | j | k | l |\n| m | n | o | p |\n| q | r | s | t |\n"

fn generate_large_table(rows : Int, cols : Int) -> String {
  let buf = StringBuilder::new()
  // Header
  buf.write_string("|")
  for c = 0; c < cols; c = c + 1 {
    buf.write_string(" H\{c} |")
  }
  buf.write_string("\n|")
  for c = 0; c < cols; c = c + 1 {
    buf.write_string("---|")
  }
  buf.write_string("\n")
  // Rows
  for r = 0; r < rows; r = r + 1 {
    buf.write_string("|")
    for c = 0; c < cols; c = c + 1 {
      buf.write_string(" R\{r}C\{c} |")
    }
    buf.write_string("\n")
  }
  buf.to_string()
}

let table_large : String = generate_large_table(20, 5)

test "table: simple 2x1" (b : @bench.T) {
  b.bench(fn() {
    let result = parse(table_simple)
    b.keep(result)
  })
}

test "table: medium 4x5" (b : @bench.T) {
  b.bench(fn() {
    let result = parse(table_medium)
    b.keep(result)
  })
}

test "table: large 5x20" (b : @bench.T) {
  b.bench(fn() {
    let result = parse(table_large)
    b.keep(result)
  })
}

// Scanner operation benchmarks
test "scanner: read_line 100x" (b : @bench.T) {
  let text = "line1\nline2\nline3\nline4\nline5\nline6\nline7\nline8\nline9\nline10\n".repeat(10)
  b.bench(fn() {
    let scanner = Scanner::new(text)
    let mut count = 0
    while not(scanner.is_eof()) {
      let _ = scanner.read_line()
      if char_is(scanner.peek(), '\n') {
        scanner.advance(1)
      }
      count += 1
    }
    b.keep(count)
  })
}

test "scanner: peek/advance intensive" (b : @bench.T) {
  let text = "abcdefghijklmnopqrstuvwxyz".repeat(100)
  b.bench(fn() {
    let scanner = Scanner::new(text)
    let mut count = 0
    while not(scanner.is_eof()) {
      let _ = scanner.peek()
      scanner.advance(1)
      count += 1
    }
    b.keep(count)
  })
}

// Block-only parsing (paragraph with no inline markers)
let block_only_doc : String = "# Title\n\nPlain paragraph one.\n\nPlain paragraph two.\n\n```\ncode block\n```\n\n- item 1\n- item 2\n- item 3\n\n> quote here\n"

test "block: minimal inline content" (b : @bench.T) {
  b.bench(fn() {
    let result = parse(block_only_doc)
    b.keep(result)
  })
}

// === Incremental parsing benchmarks ===

// Generate a document with many paragraphs for incremental testing
fn generate_paragraph_doc(count : Int) -> String {
  let buf = StringBuilder::new()
  buf.write_string("# Document Title\n\n")
  for i = 0; i < count; i = i + 1 {
    buf.write_string("Paragraph \{i + 1} with some content that needs parsing. ")
    buf.write_string("This is a *sample* paragraph with **formatting**.\n\n")
  }
  buf.to_string()
}

let incremental_doc_10 : String = generate_paragraph_doc(10)
let incremental_doc_50 : String = generate_paragraph_doc(50)
let incremental_doc_100 : String = generate_paragraph_doc(100)

// Pre-parse documents for incremental benchmarks
let incremental_parsed_10 : ParseResult = parse(incremental_doc_10)
let incremental_parsed_50 : ParseResult = parse(incremental_doc_50)
let incremental_parsed_100 : ParseResult = parse(incremental_doc_100)

// Helper to create edited version (change middle paragraph)
fn edit_middle_paragraph(source : String) -> (String, EditInfo) {
  // Find approximately middle position
  let mid = source.length() / 2
  // Find start of a line near middle
  let mut edit_pos = mid
  for i = mid; i > 0; i = i - 1 {
    match source.get_char(i) {
      Some('\n') => {
        edit_pos = i + 1
        break
      }
      _ => continue
    }
  }

  // Replace "Paragraph" with "CHANGED" at that position
  let search = "Paragraph"
  let replace = "PARAGRAPH"
  let edit_offset = match source.find(search) {
    Some(pos) => pos + (edit_pos / 10)  // Offset to get middle occurrence
    None => edit_pos
  }

  let new_source = source.unsafe_substring(start=0, end=edit_offset) +
    replace +
    source.unsafe_substring(start=edit_offset + search.length(), end=source.length())

  let edit = EditInfo::replace(edit_offset, search.length(), replace.length())
  (new_source, edit)
}

// Baseline: Full re-parse of 10-paragraph document
test "full parse: 10 paragraphs" (b : @bench.T) {
  b.bench(fn() {
    let result = parse(incremental_doc_10)
    b.keep(result)
  })
}

// Incremental: Edit middle of 10-paragraph document
test "incremental: 10 paragraphs, edit middle" (b : @bench.T) {
  let (new_source, edit) = edit_middle_paragraph(incremental_doc_10)
  let old_doc = incremental_parsed_10.document
  b.bench(fn() {
    let result = parse_incremental(old_doc, incremental_doc_10, new_source, edit)
    b.keep(result)
  })
}

// Baseline: Full re-parse of 50-paragraph document
test "full parse: 50 paragraphs" (b : @bench.T) {
  b.bench(fn() {
    let result = parse(incremental_doc_50)
    b.keep(result)
  })
}

// Incremental: Edit middle of 50-paragraph document
test "incremental: 50 paragraphs, edit middle" (b : @bench.T) {
  let (new_source, edit) = edit_middle_paragraph(incremental_doc_50)
  let old_doc = incremental_parsed_50.document
  b.bench(fn() {
    let result = parse_incremental(old_doc, incremental_doc_50, new_source, edit)
    b.keep(result)
  })
}

// Baseline: Full re-parse of 100-paragraph document
test "full parse: 100 paragraphs" (b : @bench.T) {
  b.bench(fn() {
    let result = parse(incremental_doc_100)
    b.keep(result)
  })
}

// Incremental: Edit middle of 100-paragraph document
test "incremental: 100 paragraphs, edit middle" (b : @bench.T) {
  let (new_source, edit) = edit_middle_paragraph(incremental_doc_100)
  let old_doc = incremental_parsed_100.document
  b.bench(fn() {
    let result = parse_incremental(old_doc, incremental_doc_100, new_source, edit)
    b.keep(result)
  })
}

// Edge case: Edit at the beginning
test "incremental: 50 paragraphs, edit start" (b : @bench.T) {
  let new_source = "# CHANGED Title\n" + incremental_doc_50.unsafe_substring(start=18, end=incremental_doc_50.length())
  let edit = EditInfo::replace(2, 8, 14)  // "Document" -> "CHANGED"
  let old_doc = incremental_parsed_50.document
  b.bench(fn() {
    let result = parse_incremental(old_doc, incremental_doc_50, new_source, edit)
    b.keep(result)
  })
}

// Edge case: Edit at the end
test "incremental: 50 paragraphs, edit end" (b : @bench.T) {
  let new_source = incremental_doc_50 + "New final paragraph added here.\n\n"
  let edit = EditInfo::insert(incremental_doc_50.length(), 34)
  let old_doc = incremental_parsed_50.document
  b.bench(fn() {
    let result = parse_incremental(old_doc, incremental_doc_50, new_source, edit)
    b.keep(result)
  })
}
