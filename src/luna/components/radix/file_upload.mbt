///|
/// FileUpload/Dropzone component for Luna (Headless)
/// File upload with drag and drop support

///|
/// Create a headless file upload root
/// Outputs: <div class="radix-file-upload">children</div>
pub fn radix_file_upload(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-file-upload"))], children)
}

///|
/// Create a headless file upload dropzone
/// Outputs: <div class="radix-file-upload-dropzone" data-dragging="...">children</div>
pub fn radix_file_upload_dropzone(
  dragging? : Bool,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-file-upload-dropzone")),
  ]
  match dragging {
    Some(true) => attrs.push(("data-dragging", @luna.attr_static("")))
    _ => ()
  }
  match disabled {
    Some(true) => attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a headless file upload input
/// Outputs: <input class="radix-file-upload-input" type="file" />
pub fn radix_file_upload_input(
  accept? : String,
  multiple? : Bool,
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-file-upload-input")),
    ("type", @luna.attr_static("file")),
  ]
  match accept {
    Some(a) => attrs.push(("accept", @luna.attr_static(a)))
    None => ()
  }
  match multiple {
    Some(true) => attrs.push(("multiple", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("input", attrs, [])
}

///|
/// Create a headless file upload icon
/// Outputs: <div class="radix-file-upload-icon">children</div>
pub fn radix_file_upload_icon(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-file-upload-icon"))],
    children,
  )
}

///|
/// Create a headless file upload label
/// Outputs: <div class="radix-file-upload-label">children</div>
pub fn radix_file_upload_label(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-file-upload-label"))],
    children,
  )
}

///|
/// Create a headless file upload hint
/// Outputs: <div class="radix-file-upload-hint">children</div>
pub fn radix_file_upload_hint(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-file-upload-hint"))],
    children,
  )
}

///|
/// Create a headless file upload list (uploaded files)
/// Outputs: <div class="radix-file-upload-list">children</div>
pub fn radix_file_upload_list(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-file-upload-list"))],
    children,
  )
}

///|
/// Create a headless file upload item
/// Outputs: <div class="radix-file-upload-item">children</div>
pub fn radix_file_upload_item(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-file-upload-item"))],
    children,
  )
}

///|
/// Create a headless file upload item name
/// Outputs: <span class="radix-file-upload-item-name">children</span>
pub fn radix_file_upload_item_name(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "span",
    [("class", @luna.attr_static("radix-file-upload-item-name"))],
    children,
  )
}

///|
/// Create a headless file upload item size
/// Outputs: <span class="radix-file-upload-item-size">children</span>
pub fn radix_file_upload_item_size(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "span",
    [("class", @luna.attr_static("radix-file-upload-item-size"))],
    children,
  )
}

///|
/// Create a headless file upload item remove button
/// Outputs: <button class="radix-file-upload-item-remove">children</button>
pub fn radix_file_upload_item_remove(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "button",
    [
      ("class", @luna.attr_static("radix-file-upload-item-remove")),
      ("type", @luna.attr_static("button")),
    ],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the file upload component
fn file_upload_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.file-upload-dropzone {
    #|  display: flex;
    #|  flex-direction: column;
    #|  align-items: center;
    #|  justify-content: center;
    #|  padding: 2rem;
    #|  border: 2px dashed #e4e4e7;
    #|  border-radius: 8px;
    #|  background: #fafafa;
    #|  cursor: pointer;
    #|  transition: border-color 0.15s ease, background 0.15s ease;
    #|}
    #|
    #|.file-upload-dropzone:hover {
    #|  border-color: #a1a1aa;
    #|  background: #f4f4f5;
    #|}
    #|
    #|.file-upload-dropzone[data-dragging] {
    #|  border-color: #18181b;
    #|  background: #f4f4f5;
    #|}
    #|
    #|.file-upload-dropzone[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|.file-upload-input {
    #|  display: none;
    #|}
    #|
    #|.file-upload-icon {
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  width: 3rem;
    #|  height: 3rem;
    #|  margin-bottom: 0.75rem;
    #|  color: #71717a;
    #|}
    #|
    #|.file-upload-label {
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  color: #18181b;
    #|  margin-bottom: 0.25rem;
    #|}
    #|
    #|.file-upload-hint {
    #|  font-size: 0.75rem;
    #|  color: #71717a;
    #|}
    #|
    #|.file-upload-list {
    #|  margin-top: 1rem;
    #|  display: flex;
    #|  flex-direction: column;
    #|  gap: 0.5rem;
    #|}
    #|
    #|.file-upload-item {
    #|  display: flex;
    #|  align-items: center;
    #|  gap: 0.75rem;
    #|  padding: 0.5rem 0.75rem;
    #|  background: #f4f4f5;
    #|  border-radius: 6px;
    #|}
    #|
    #|.file-upload-item-name {
    #|  flex: 1;
    #|  font-size: 0.875rem;
    #|  color: #18181b;
    #|  white-space: nowrap;
    #|  overflow: hidden;
    #|  text-overflow: ellipsis;
    #|}
    #|
    #|.file-upload-item-size {
    #|  font-size: 0.75rem;
    #|  color: #71717a;
    #|  flex-shrink: 0;
    #|}
    #|
    #|.file-upload-item-remove {
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  width: 1.5rem;
    #|  height: 1.5rem;
    #|  padding: 0;
    #|  background: transparent;
    #|  border: none;
    #|  border-radius: 4px;
    #|  cursor: pointer;
    #|  color: #71717a;
    #|  transition: color 0.15s ease, background 0.15s ease;
    #|}
    #|
    #|.file-upload-item-remove:hover {
    #|  color: #ef4444;
    #|  background: #fee2e2;
    #|}
  css
}

///|
/// Create a styled file upload with Declarative Shadow DOM
pub fn radix_file_upload_styled(
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => file_upload_styles()
  }
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(css)]),
    @luna.h("slot", [], []),
  ]
  let all_children : Array[@luna.Node[Unit]] = [
    @luna.h(
      "template",
      [("shadowrootmode", @luna.attr_static("open"))],
      template_children,
    ),
  ]
  for child in children {
    all_children.push(child)
  }
  @luna.h("radix-file-upload", [], all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a file upload dropzone with luna/css atomic styles
pub fn radix_file_upload_dropzone_ucss(
  dragging? : Bool,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let mut class_names = file_upload_dropzone_styles()
  match dragging {
    Some(true) =>
      class_names = class_names +
        " " +
        @css.styles([("border-color", "#18181b"), ("background", "#f4f4f5")])
    _ => ()
  }
  match disabled {
    Some(true) =>
      class_names = class_names +
        " " +
        @css.styles([("opacity", "0.5"), ("cursor", "not-allowed")])
    _ => ()
  }
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
  ]
  match dragging {
    Some(true) => attrs.push(("data-dragging", @luna.attr_static("")))
    _ => ()
  }
  match disabled {
    Some(true) => attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a file upload item with luna/css atomic styles
pub fn radix_file_upload_item_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = file_upload_item_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}
