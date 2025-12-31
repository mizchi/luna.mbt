// Astra Components - Navigation (Breadcrumb, Prev/Next)
// Tree-driven navigation components using NavContext

///|
/// Build breadcrumb navigation from document tree
pub fn build_breadcrumb(
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta,
) -> @luna.Node[Unit] {
  match ctx.doc_tree {
    Some(tree) => {
      let nav_ctx = NavContext::build(tree, page.url_path, locale=page.locale)
      render_breadcrumb(nav_ctx)
    }
    None => empty()
  }
}

///|
/// Build prev/next navigation from document tree
pub fn build_prev_next(
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta,
) -> @luna.Node[Unit] {
  match ctx.doc_tree {
    Some(tree) => {
      let nav_ctx = NavContext::build(tree, page.url_path, locale=page.locale)
      render_prev_next(nav_ctx)
    }
    None => empty()
  }
}
