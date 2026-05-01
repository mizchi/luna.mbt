// Frontmatter Conversion
// Converts @md_parser.Frontmatter to Frontmatter

///|
/// Convert CST Frontmatter to Frontmatter
pub fn from_cst(fm : @md_parser.Frontmatter) -> Frontmatter {
  // Use @md_fm utilities for extraction
  let image = match @md_fm.get_string(fm, "image") {
    Some(v) => Some(v)
    None =>
      match @md_fm.get_string(fm, "ogImage") {
        Some(v) => Some(v)
        None => @md_fm.get_string(fm, "og_image")
      }
  }
  let og_type = match @md_fm.get_string(fm, "ogType") {
    Some(v) => Some(v)
    None => @md_fm.get_string(fm, "og_type")
  }
  let twitter_card = match @md_fm.get_string(fm, "twitterCard") {
    Some(v) => Some(v)
    None => @md_fm.get_string(fm, "twitter_card")
  }
  Frontmatter::{
    title: @md_fm.get_string(fm, "title"),
    description: @md_fm.get_string(fm, "description"),
    layout: @md_fm.get_string(fm, "layout"),
    sidebar: @md_fm.get_bool(fm, "sidebar").unwrap_or(true),
    outline: None,
    islands: @md_fm.get_list(fm, "islands"),
    prev: None,
    next: None,
    image,
    og_type,
    twitter_card,
    ssr: @md_fm.get_bool(fm, "ssr").unwrap_or(false),
    renderer: None,
    noindex: @md_fm.get_bool(fm, "noindex").unwrap_or(false),
    revalidate: @md_fm.get_int(fm, "revalidate"),
    date: @md_fm.get_string(fm, "date"),
    author: @md_fm.get_string(fm, "author"),
    tags: @md_fm.get_list(fm, "tags"),
    draft: @md_fm.get_bool(fm, "draft").unwrap_or(false),
    featured: @md_fm.get_bool(fm, "featured").unwrap_or(false),
    cover_image: match @md_fm.get_string(fm, "cover_image") {
      Some(v) => Some(v)
      None => @md_fm.get_string(fm, "coverImage")
    },
  }
}
