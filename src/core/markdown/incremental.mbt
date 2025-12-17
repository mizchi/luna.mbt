///| Incremental parsing support
///| Allows partial re-parsing when document changes are localized

///| Describes a text edit operation
///| Using #valtype to avoid heap allocation for this small struct
#valtype
pub(all) struct EditInfo {
  offset : Int      // Where the edit starts in old source
  old_len : Int     // How many chars were deleted
  new_len : Int     // How many chars were inserted
}

///| Create an edit info for insertion
pub fn EditInfo::insert(offset : Int, len : Int) -> EditInfo {
  { offset, old_len: 0, new_len: len }
}

///| Create an edit info for deletion
pub fn EditInfo::delete(offset : Int, len : Int) -> EditInfo {
  { offset, old_len: len, new_len: 0 }
}

///| Create an edit info for replacement
pub fn EditInfo::replace(offset : Int, old_len : Int, new_len : Int) -> EditInfo {
  { offset, old_len, new_len }
}

///| Result of incremental parsing
pub(all) struct IncrementalResult {
  document : Document
  reused_before : Int   // Number of blocks reused from before edit
  reparsed : Int        // Number of blocks that were re-parsed
  reused_after : Int    // Number of blocks reused from after edit
}

///| Parse incrementally using edit hint
pub fn parse_incremental(
  old_doc : Document,
  old_source : String,
  new_source : String,
  edit : EditInfo
) -> IncrementalResult {
  let old_blocks = old_doc.children

  // Find blocks affected by the edit
  let (before_idx, after_idx) = find_affected_range(old_blocks, edit)

  // Determine the source range to re-parse
  let reparse_start = if before_idx > 0 {
    old_blocks[before_idx - 1].get_span().to
  } else {
    match old_doc.frontmatter {
      Some(fm) => fm.span.to
      None => 0
    }
  }

  let reparse_end_old = if after_idx < old_blocks.length() {
    old_blocks[after_idx].get_span().from
  } else {
    old_source.length()
  }

  // Adjust reparse_end for new source (account for edit delta)
  let delta = edit.new_len - edit.old_len
  let reparse_end_new = reparse_end_old + delta

  // Extract the region to re-parse from new source
  let reparse_region = new_source.unsafe_substring(
    start=reparse_start,
    end=clamp_int(reparse_end_new, reparse_start, new_source.length())
  )

  // Re-parse just this region
  let region_result = parse(reparse_region)
  let new_blocks_raw = region_result.document.children

  // Adjust spans in re-parsed blocks
  let new_blocks = adjust_spans(new_blocks_raw, reparse_start)

  // Build final document
  let final_blocks : Array[Block] = []

  // 1. Reuse blocks before the edit
  for i = 0; i < before_idx; i = i + 1 {
    final_blocks.push(old_blocks[i])
  }
  let reused_before = before_idx

  // 2. Add re-parsed blocks
  for block in new_blocks {
    final_blocks.push(block)
  }
  let reparsed = new_blocks.length()

  // 3. Reuse blocks after the edit (with adjusted spans)
  let reused_after_count = old_blocks.length() - after_idx
  for i = after_idx; i < old_blocks.length(); i = i + 1 {
    final_blocks.push(shift_block_span(old_blocks[i], delta))
  }

  let new_doc = Document::{
    frontmatter: old_doc.frontmatter,
    children: final_blocks,
    span: Span::new(0, new_source.length()),
  }

  {
    document: new_doc,
    reused_before,
    reparsed,
    reused_after: reused_after_count,
  }
}

///| Find the range of blocks affected by the edit
///| Returns (first_affected_idx, first_unaffected_after_idx)
fn find_affected_range(blocks : Array[Block], edit : EditInfo) -> (Int, Int) {
  let edit_start = edit.offset
  let edit_end = edit.offset + edit.old_len

  let mut first_affected = blocks.length()
  let mut first_unaffected = blocks.length()

  for i, block in blocks {
    let span = block.get_span()

    // Check if block overlaps with edit
    if span.to > edit_start && span.from < edit_end {
      if first_affected == blocks.length() {
        first_affected = i
      }
      first_unaffected = i + 1
    } else if span.from >= edit_end {
      // Block is entirely after the edit
      if first_unaffected == blocks.length() || first_unaffected <= i {
        first_unaffected = i
      }
      break
    }
  }

  // If edit is in a blank region between blocks, we still need to re-parse
  if first_affected == blocks.length() {
    // Find where the edit falls
    for i, block in blocks {
      let span = block.get_span()
      if span.from > edit_start {
        first_affected = i
        first_unaffected = i
        break
      }
      if span.to >= edit_start {
        first_affected = i
        first_unaffected = i + 1
        break
      }
    }
  }

  (first_affected, first_unaffected)
}

///| Adjust spans in blocks by adding an offset
fn adjust_spans(blocks : Array[Block], offset : Int) -> Array[Block] {
  let result : Array[Block] = []
  for block in blocks {
    result.push(shift_block_span(block, offset))
  }
  result
}

///| Shift a block's span by delta
fn shift_block_span(block : Block, delta : Int) -> Block {
  match block {
    Block::ThematicBreak(marker~, count~, span~, leading_trivia~, trailing_trivia~) =>
      Block::ThematicBreak(
        marker~,
        count~,
        span=Span::new(span.from + delta, span.to + delta),
        leading_trivia~,
        trailing_trivia~,
      )
    Block::Heading(level~, style~, children~, closing_hashes~, span~, leading_trivia~, trailing_trivia~) =>
      Block::Heading(
        level~,
        style~,
        children~,
        closing_hashes~,
        span=Span::new(span.from + delta, span.to + delta),
        leading_trivia~,
        trailing_trivia~,
      )
    Block::Paragraph(children~, span~, leading_trivia~, trailing_trivia~) =>
      Block::Paragraph(
        children~,
        span=Span::new(span.from + delta, span.to + delta),
        leading_trivia~,
        trailing_trivia~,
      )
    Block::FencedCode(fence_marker~, fence_length~, info~, code~, indent~, span~, leading_trivia~, trailing_trivia~) =>
      Block::FencedCode(
        fence_marker~,
        fence_length~,
        info~,
        code~,
        indent~,
        span=Span::new(span.from + delta, span.to + delta),
        leading_trivia~,
        trailing_trivia~,
      )
    Block::IndentedCode(code~, span~, leading_trivia~, trailing_trivia~) =>
      Block::IndentedCode(
        code~,
        span=Span::new(span.from + delta, span.to + delta),
        leading_trivia~,
        trailing_trivia~,
      )
    Block::Blockquote(children~, span~, leading_trivia~, trailing_trivia~) =>
      Block::Blockquote(
        children=adjust_spans(children, delta),
        span=Span::new(span.from + delta, span.to + delta),
        leading_trivia~,
        trailing_trivia~,
      )
    Block::BulletList(marker~, tight~, items~, span~, leading_trivia~, trailing_trivia~) =>
      Block::BulletList(
        marker~,
        tight~,
        items~,  // TODO: adjust item spans
        span=Span::new(span.from + delta, span.to + delta),
        leading_trivia~,
        trailing_trivia~,
      )
    Block::OrderedList(start~, delimiter~, tight~, items~, span~, leading_trivia~, trailing_trivia~) =>
      Block::OrderedList(
        start~,
        delimiter~,
        tight~,
        items~,  // TODO: adjust item spans
        span=Span::new(span.from + delta, span.to + delta),
        leading_trivia~,
        trailing_trivia~,
      )
    Block::Table(header~, alignments~, rows~, span~, leading_trivia~, trailing_trivia~) =>
      Block::Table(
        header~,
        alignments~,
        rows~,
        span=Span::new(span.from + delta, span.to + delta),
        leading_trivia~,
        trailing_trivia~,
      )
    Block::HtmlBlock(html~, span~, leading_trivia~, trailing_trivia~) =>
      Block::HtmlBlock(
        html~,
        span=Span::new(span.from + delta, span.to + delta),
        leading_trivia~,
        trailing_trivia~,
      )
    Block::BlankLines(count~, span~) =>
      Block::BlankLines(
        count~,
        span=Span::new(span.from + delta, span.to + delta),
      )
  }
}

///| Helper to get span from a block
fn Block::get_span(self : Block) -> Span {
  match self {
    Block::ThematicBreak(span~, ..) => span
    Block::Heading(span~, ..) => span
    Block::Paragraph(span~, ..) => span
    Block::FencedCode(span~, ..) => span
    Block::IndentedCode(span~, ..) => span
    Block::Blockquote(span~, ..) => span
    Block::BulletList(span~, ..) => span
    Block::OrderedList(span~, ..) => span
    Block::Table(span~, ..) => span
    Block::HtmlBlock(span~, ..) => span
    Block::BlankLines(span~, ..) => span
  }
}

///| Clamp a value between min and max (local helper)
fn clamp_int(value : Int, min : Int, max : Int) -> Int {
  if value < min {
    min
  } else if value > max {
    max
  } else {
    value
  }
}
