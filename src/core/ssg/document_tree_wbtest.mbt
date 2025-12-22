// Unit tests for DocumentTree types and methods

// =============================================================================
// SiteInfo Tests
// =============================================================================

///|
test "SiteInfo::new with defaults" {
  let site = SiteInfo::new(title="Test Site")
  inspect(site.title, content="Test Site")
  inspect(site.description, content="")
  inspect(site.base_url, content="")
  inspect(site.language, content="en")
  inspect(site.updated_at, content="")
}

///|
test "SiteInfo::new with all fields" {
  let site = SiteInfo::new(
    title="My Site",
    description="A test site",
    base_url="https://example.com",
    language="ja",
    updated_at="2024-12-23T10:00:00Z",
  )
  inspect(site.title, content="My Site")
  inspect(site.description, content="A test site")
  inspect(site.base_url, content="https://example.com")
  inspect(site.language, content="ja")
  inspect(site.updated_at, content="2024-12-23T10:00:00Z")
}

// =============================================================================
// PageInfo Tests
// =============================================================================

///|
test "PageInfo::new with required fields" {
  let page = PageInfo::new(id="test-page", url_path="/test/")
  inspect(page.id, content="test-page")
  inspect(page.url_path, content="/test/")
  inspect(page.source_path, content="")
  inspect(page.title, content="")
  inspect(page.locale, content="en")
}

///|
test "PageInfo::new with all fields" {
  let page = PageInfo::new(
    id="guide-intro",
    url_path="/guide/intro/",
    source_path="guide/intro.md",
    title="Introduction",
    description="Getting started",
    locale="ja",
    updated_at="2024-12-23",
    content_md="# Intro",
    headings=[Heading::new(level=1, text="Intro")],
    sort_key="001_intro",
  )
  inspect(page.id, content="guide-intro")
  inspect(page.title, content="Introduction")
  inspect(page.locale, content="ja")
  inspect(page.headings.length(), content="1")
}

///|
test "PageInfo::canonical_url without trailing slash in base" {
  let page = PageInfo::new(id="test", url_path="/guide/intro/")
  let url = page.canonical_url("https://example.com")
  inspect(url, content="https://example.com/guide/intro/")
}

///|
test "PageInfo::canonical_url with trailing slash in base" {
  let page = PageInfo::new(id="test", url_path="/guide/intro/")
  let url = page.canonical_url("https://example.com/")
  inspect(url, content="https://example.com/guide/intro/")
}

///|
test "PageInfo::canonical_url for root path" {
  let page = PageInfo::new(id="index", url_path="/")
  let url = page.canonical_url("https://example.com")
  inspect(url, content="https://example.com/")
}

// =============================================================================
// Heading Tests
// =============================================================================

///|
test "Heading::new with defaults" {
  let h = Heading::new(level=1, text="Title")
  inspect(h.level, content="1")
  inspect(h.text, content="Title")
  inspect(h.id, content="")
}

///|
test "Heading::new with id" {
  let h = Heading::new(level=2, text="Section", id="section-1")
  inspect(h.level, content="2")
  inspect(h.text, content="Section")
  inspect(h.id, content="section-1")
}

// =============================================================================
// TreeNode Tests
// =============================================================================

///|
test "TreeNode::Page construction" {
  let node = TreeNode::Page(page_id="index")
  match node {
    TreeNode::Page(page_id~) => inspect(page_id, content="index")
    _ => fail("Expected Page variant")
  }
}

///|
test "TreeNode::Section construction" {
  let node = TreeNode::Section(
    name="guide",
    path="/guide/",
    children=[TreeNode::Page(page_id="intro")],
  )
  match node {
    TreeNode::Section(name~, path~, children~) => {
      inspect(name, content="guide")
      inspect(path, content="/guide/")
      inspect(children.length(), content="1")
    }
    _ => fail("Expected Section variant")
  }
}

///|
test "TreeNode::flatten - single page" {
  let node = TreeNode::Page(page_id="index")
  let ids = node.flatten()
  inspect(ids.length(), content="1")
  inspect(ids[0], content="index")
}

///|
test "TreeNode::flatten - section with pages" {
  let node = TreeNode::Section(
    name="",
    path="/",
    children=[
      TreeNode::Page(page_id="index"),
      TreeNode::Section(
        name="guide",
        path="/guide/",
        children=[
          TreeNode::Page(page_id="guide-intro"),
          TreeNode::Page(page_id="guide-advanced"),
        ],
      ),
    ],
  )
  let ids = node.flatten()
  inspect(ids.length(), content="3")
  inspect(ids.contains("index"), content="true")
  inspect(ids.contains("guide-intro"), content="true")
  inspect(ids.contains("guide-advanced"), content="true")
}

///|
test "TreeNode::flatten - empty section" {
  let node = TreeNode::Section(name="empty", path="/empty/", children=[])
  let ids = node.flatten()
  inspect(ids.length(), content="0")
}

// =============================================================================
// DocumentTree Tests
// =============================================================================

///|
fn create_test_document_tree() -> DocumentTree {
  let site = SiteInfo::new(
    title="Test Site",
    base_url="https://example.com",
    language="en",
  )
  let pages : Array[PageInfo] = [
    PageInfo::new(
      id="index",
      url_path="/",
      title="Home",
      locale="en",
      updated_at="2024-12-23",
    ),
    PageInfo::new(
      id="guide-intro",
      url_path="/guide/intro/",
      title="Introduction",
      locale="en",
      updated_at="2024-12-22",
    ),
    PageInfo::new(
      id="guide-advanced",
      url_path="/guide/advanced/",
      title="Advanced",
      locale="en",
      updated_at="2024-12-21",
    ),
    PageInfo::new(
      id="ja-index",
      url_path="/ja/",
      title="ホーム",
      locale="ja",
      updated_at="2024-12-20",
    ),
  ]
  let root = TreeNode::Section(
    name="",
    path="/",
    children=[
      TreeNode::Page(page_id="index"),
      TreeNode::Section(
        name="guide",
        path="/guide/",
        children=[
          TreeNode::Page(page_id="guide-intro"),
          TreeNode::Page(page_id="guide-advanced"),
        ],
      ),
    ],
  )
  DocumentTree::new(site~, pages~, root~)
}

///|
test "DocumentTree::new with defaults" {
  let site = SiteInfo::new(title="Test")
  let tree = DocumentTree::new(site~)
  inspect(tree.pages.length(), content="0")
  match tree.root {
    TreeNode::Section(name~, ..) => inspect(name, content="")
    _ => fail("Expected Section root")
  }
}

///|
test "DocumentTree::get_page - existing" {
  let tree = create_test_document_tree()
  let page = tree.get_page("guide-intro")
  inspect(page is Some(_), content="true")
  inspect(page.unwrap().title, content="Introduction")
}

///|
test "DocumentTree::get_page - non-existing" {
  let tree = create_test_document_tree()
  let page = tree.get_page("non-existent")
  inspect(page is None, content="true")
}

///|
test "DocumentTree::get_page_by_url - existing" {
  let tree = create_test_document_tree()
  let page = tree.get_page_by_url("/guide/intro/")
  inspect(page is Some(_), content="true")
  inspect(page.unwrap().id, content="guide-intro")
}

///|
test "DocumentTree::get_page_by_url - root" {
  let tree = create_test_document_tree()
  let page = tree.get_page_by_url("/")
  inspect(page is Some(_), content="true")
  inspect(page.unwrap().id, content="index")
}

///|
test "DocumentTree::get_page_by_url - non-existing" {
  let tree = create_test_document_tree()
  let page = tree.get_page_by_url("/non-existent/")
  inspect(page is None, content="true")
}

///|
test "DocumentTree::get_pages_by_locale - en" {
  let tree = create_test_document_tree()
  let pages = tree.get_pages_by_locale("en")
  inspect(pages.length(), content="3")
}

///|
test "DocumentTree::get_pages_by_locale - ja" {
  let tree = create_test_document_tree()
  let pages = tree.get_pages_by_locale("ja")
  inspect(pages.length(), content="1")
  inspect(pages[0].id, content="ja-index")
}

///|
test "DocumentTree::get_pages_by_locale - non-existing locale" {
  let tree = create_test_document_tree()
  let pages = tree.get_pages_by_locale("fr")
  inspect(pages.length(), content="0")
}

///|
test "DocumentTree::get_pages_sorted_by_date - all pages" {
  let tree = create_test_document_tree()
  let pages = tree.get_pages_sorted_by_date()
  inspect(pages.length(), content="4")
  // Should be sorted newest first
  inspect(pages[0].id, content="index") // 2024-12-23
  inspect(pages[1].id, content="guide-intro") // 2024-12-22
  inspect(pages[2].id, content="guide-advanced") // 2024-12-21
  inspect(pages[3].id, content="ja-index") // 2024-12-20
}

///|
test "DocumentTree::get_pages_sorted_by_date - with limit" {
  let tree = create_test_document_tree()
  let pages = tree.get_pages_sorted_by_date(limit=2)
  inspect(pages.length(), content="2")
  inspect(pages[0].id, content="index")
  inspect(pages[1].id, content="guide-intro")
}

///|
test "DocumentTree::get_pages_sorted_by_date - limit exceeds count" {
  let tree = create_test_document_tree()
  let pages = tree.get_pages_sorted_by_date(limit=100)
  inspect(pages.length(), content="4")
}
