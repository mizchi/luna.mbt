// Astra Components - Blog
// Blog-specific components: PostCard, PostList, Hero, TagList

// =============================================================================
// Blog Post Card
// =============================================================================

///|
/// Blog post card for listings
pub fn build_blog_post_card(page : @astra.PageMeta) -> @luna.Node[Unit] {
  let fm = page.frontmatter
  let title = fm.title.unwrap_or("Untitled")
  let description = fm.description.unwrap_or("")
  let date = fm.date.unwrap_or("")
  let author = fm.author.unwrap_or("")

  // Build card content
  let children : Array[@luna.Node[Unit]] = []

  // Cover image (optional)
  if fm.cover_image is Some(src) {
    children.push(
      h("div", [attr("class", "blog-card-image")], [
        h(
          "img",
          [attr("src", src), attr("alt", title), attr("loading", "lazy")],
          [],
        ),
      ]),
    )
  }

  // Card body
  let body_children : Array[@luna.Node[Unit]] = []

  // Meta info (date + author)
  if not(date.is_empty()) || not(author.is_empty()) {
    body_children.push(build_post_meta(date, author, None))
  }

  // Title
  body_children.push(
    h("h3", [attr("class", "blog-card-title")], [
      h("a", [attr("href", page.url_path)], [@luna.text(title)]),
    ]),
  )

  // Description
  if not(description.is_empty()) {
    body_children.push(
      h("p", [attr("class", "blog-card-description")], [@luna.text(description)]),
    )
  }

  // Tags
  if not(fm.tags.is_empty()) {
    body_children.push(build_tag_list(fm.tags))
  }
  children.push(h("div", [attr("class", "blog-card-body")], body_children))

  // Featured badge
  let card_class = if fm.featured {
    "blog-card blog-card-featured"
  } else {
    "blog-card"
  }
  h("article", [attr("class", card_class)], children)
}

// =============================================================================
// Post Meta (date, author, reading time)
// =============================================================================

///|
/// Build post meta info (date, author, reading time)
pub fn build_post_meta(
  date : String,
  author : String,
  reading_time : Int?,
) -> @luna.Node[Unit] {
  let items : Array[@luna.Node[Unit]] = []

  // Date
  if not(date.is_empty()) {
    items.push(
      h("time", [attr("class", "post-meta-date"), attr("datetime", date)], [
        @luna.text(format_date(date)),
      ]),
    )
  }

  // Author
  if not(author.is_empty()) {
    if not(items.is_empty()) {
      items.push(
        h("span", [attr("class", "post-meta-separator")], [@luna.text(" · ")]),
      )
    }
    items.push(
      h("span", [attr("class", "post-meta-author")], [@luna.text(author)]),
    )
  }

  // Reading time
  if reading_time is Some(minutes) {
    if not(items.is_empty()) {
      items.push(
        h("span", [attr("class", "post-meta-separator")], [@luna.text(" · ")]),
      )
    }
    items.push(
      h("span", [attr("class", "post-meta-reading-time")], [
        @luna.text("\{minutes} min read"),
      ]),
    )
  }
  h("div", [attr("class", "post-meta")], items)
}

///|
/// Format date for display (YYYY-MM-DD -> human readable)
fn format_date(date : String) -> String {
  // Simple format: keep as-is for now
  // TODO: Add proper date formatting with locale support
  date
}

// =============================================================================
// Tag List
// =============================================================================

///|
/// Build tag list with links
pub fn build_tag_list(tags : Array[String]) -> @luna.Node[Unit] {
  if tags.is_empty() {
    return empty()
  }
  let tag_nodes = tags.map(fn(tag) {
    h("a", [attr("href", "/tags/" + tag + "/"), attr("class", "tag")], [
      @luna.text(tag),
    ])
  })
  h("div", [attr("class", "tag-list")], tag_nodes)
}

///|
/// Build inline tag list (no links, just display)
pub fn build_tag_list_inline(tags : Array[String]) -> @luna.Node[Unit] {
  if tags.is_empty() {
    return empty()
  }
  let tag_nodes = tags.map(fn(tag) {
    h("span", [attr("class", "tag tag-inline")], [@luna.text(tag)])
  })
  h("div", [attr("class", "tag-list tag-list-inline")], tag_nodes)
}

// =============================================================================
// Blog Post List
// =============================================================================

///|
/// Build blog post list from pages
/// Filters to blog posts (pages with date) and sorts by date descending
pub fn build_blog_post_list(
  ctx : @astra.BuildContext,
  limit : Int?,
  featured_only : Bool,
) -> @luna.Node[Unit] {
  // Filter to blog posts (has date, not draft)
  let posts = filter_blog_posts(ctx.pages, featured_only~)

  // Apply limit
  let display_posts = match limit {
    Some(n) =>
      if posts.length() > n {
        posts.iter().take(n).collect()
      } else {
        posts
      }
    None => posts
  }
  if display_posts.is_empty() {
    return h("p", [attr("class", "blog-empty")], [@luna.text("No posts yet.")])
  }

  // Build post cards
  let cards = display_posts.map(fn(page) { build_blog_post_card(page) })
  h("div", [attr("class", "blog-post-list")], cards)
}

///|
/// Filter pages to blog posts
/// Returns pages that have a date and are not drafts, sorted by date descending
fn filter_blog_posts(
  pages : Array[@astra.PageMeta],
  featured_only? : Bool = false,
) -> Array[@astra.PageMeta] {
  // Filter: has date, not draft, optionally featured only
  let filtered : Array[@astra.PageMeta] = []
  for page in pages {
    let fm = page.frontmatter
    if fm.date is Some(_) && not(fm.draft) {
      if featured_only {
        if fm.featured {
          filtered.push(page)
        }
      } else {
        filtered.push(page)
      }
    }
  }

  // Sort by date descending (newest first)
  filtered.sort_by(fn(a, b) {
    let date_a = a.frontmatter.date.unwrap_or("")
    let date_b = b.frontmatter.date.unwrap_or("")
    // Descending order: b compared to a
    date_b.compare(date_a)
  })
  filtered
}

///|
/// Get blog posts for a specific tag
pub fn get_posts_by_tag(
  pages : Array[@astra.PageMeta],
  tag : String,
) -> Array[@astra.PageMeta] {
  let result : Array[@astra.PageMeta] = []
  for page in pages {
    let fm = page.frontmatter
    if fm.date is Some(_) && not(fm.draft) {
      for t in fm.tags {
        if t == tag {
          result.push(page)
          break
        }
      }
    }
  }
  // Sort by date descending
  result.sort_by(fn(a, b) {
    let date_a = a.frontmatter.date.unwrap_or("")
    let date_b = b.frontmatter.date.unwrap_or("")
    date_b.compare(date_a)
  })
  result
}

// =============================================================================
// Blog Hero
// =============================================================================

///|
/// Build blog hero section for home/landing pages
pub fn build_blog_hero(
  title : String,
  subtitle : String?,
  cta_text : String?,
  cta_link : String?,
) -> @luna.Node[Unit] {
  let children : Array[@luna.Node[Unit]] = []

  // Title
  children.push(h("h1", [attr("class", "hero-title")], [@luna.text(title)]))

  // Subtitle
  if subtitle is Some(sub) {
    children.push(h("p", [attr("class", "hero-subtitle")], [@luna.text(sub)]))
  }

  // CTA button
  match (cta_text, cta_link) {
    (Some(text), Some(link)) =>
      children.push(
        h("a", [attr("href", link), attr("class", "hero-cta")], [
          @luna.text(text),
        ]),
      )
    _ => ()
  }
  h("section", [attr("class", "hero")], [
    h("div", [attr("class", "hero-content")], children),
  ])
}

///|
/// Build hero from page frontmatter
pub fn build_hero_from_page(page : @astra.PageMeta) -> @luna.Node[Unit] {
  let fm = page.frontmatter
  let title = fm.title.unwrap_or("Welcome")
  let subtitle = fm.description
  // Default CTA for home pages
  build_blog_hero(title, subtitle, Some("Read Blog"), Some("/blog/"))
}

// =============================================================================
// Featured Posts Section
// =============================================================================

///|
/// Build featured posts section
pub fn build_featured_posts(
  ctx : @astra.BuildContext,
  limit : Int,
) -> @luna.Node[Unit] {
  let posts = filter_blog_posts(ctx.pages, featured_only=true)
  if posts.is_empty() {
    // Fall back to latest posts if no featured posts
    return build_blog_post_list(ctx, Some(limit), false)
  }
  let display_posts : Array[@astra.PageMeta] = if posts.length() > limit {
    posts.iter().take(limit).collect()
  } else {
    posts
  }
  let cards = display_posts.map(fn(page) { build_blog_post_card(page) })
  h("section", [attr("class", "featured-posts")], [
    h("h2", [attr("class", "featured-posts-title")], [
      @luna.text("Featured Posts"),
    ]),
    h("div", [attr("class", "blog-post-list")], cards),
  ])
}

// =============================================================================
// Recent Posts Section
// =============================================================================

///|
/// Build recent posts section with title
pub fn build_recent_posts(
  ctx : @astra.BuildContext,
  limit : Int,
  title : String,
) -> @luna.Node[Unit] {
  h("section", [attr("class", "recent-posts")], [
    h("h2", [attr("class", "recent-posts-title")], [@luna.text(title)]),
    build_blog_post_list(ctx, Some(limit), false),
  ])
}
