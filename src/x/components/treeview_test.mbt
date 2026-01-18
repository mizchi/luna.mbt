///|
/// Tests for TreeView component logic

///|
/// Helper to create test tree structure
fn test_tree() -> Array[TreeNode] {
  [
    tree_node("documents", "Documents", children=[
      tree_node("report", "report.pdf"),
      tree_node("notes", "notes.txt"),
      tree_node("projects", "Projects", children=[
        tree_node("project-a", "Project A"),
        tree_node("project-b", "Project B"),
      ]),
    ]),
    tree_node("images", "Images", children=[
      tree_node("photo1", "photo1.jpg"),
      tree_node("photo2", "photo2.png"),
    ]),
    tree_node("readme", "readme.md"),
  ]
}

///|
test "flatten_visible_nodes: all collapsed" {
  let nodes = test_tree()
  let expanded : Map[String, Bool] = {}
  let visible = flatten_visible_nodes(nodes, expanded)
  // Only root level nodes should be visible
  inspect!(visible.length(), content="3")
  inspect!(visible[0], content="documents")
  inspect!(visible[1], content="images")
  inspect!(visible[2], content="readme")
}

///|
test "flatten_visible_nodes: documents expanded" {
  let nodes = test_tree()
  let expanded : Map[String, Bool] = { "documents": true }
  let visible = flatten_visible_nodes(nodes, expanded)
  // documents + its 3 children + images + readme = 6
  inspect!(visible.length(), content="6")
  inspect!(visible[0], content="documents")
  inspect!(visible[1], content="report")
  inspect!(visible[2], content="notes")
  inspect!(visible[3], content="projects")
  inspect!(visible[4], content="images")
  inspect!(visible[5], content="readme")
}

///|
test "flatten_visible_nodes: documents and projects expanded" {
  let nodes = test_tree()
  let expanded : Map[String, Bool] = { "documents": true, "projects": true }
  let visible = flatten_visible_nodes(nodes, expanded)
  // documents + report + notes + projects + project-a + project-b + images + readme = 8
  inspect!(visible.length(), content="8")
  inspect!(visible[0], content="documents")
  inspect!(visible[1], content="report")
  inspect!(visible[2], content="notes")
  inspect!(visible[3], content="projects")
  inspect!(visible[4], content="project-a")
  inspect!(visible[5], content="project-b")
  inspect!(visible[6], content="images")
  inspect!(visible[7], content="readme")
}

///|
test "flatten_visible_nodes: all expanded" {
  let nodes = test_tree()
  let expanded : Map[String, Bool] = {
    "documents": true,
    "projects": true,
    "images": true,
  }
  let visible = flatten_visible_nodes(nodes, expanded)
  // documents(1) + report + notes + projects + project-a + project-b (6)
  // + images + photo1 + photo2 (3)
  // + readme (1) = 10
  inspect!(visible.length(), content="10")
  inspect!(visible[0], content="documents")
  inspect!(visible[1], content="report")
  inspect!(visible[2], content="notes")
  inspect!(visible[3], content="projects")
  inspect!(visible[4], content="project-a")
  inspect!(visible[5], content="project-b")
  inspect!(visible[6], content="images")
  inspect!(visible[7], content="photo1")
  inspect!(visible[8], content="photo2")
  inspect!(visible[9], content="readme")
}

///|
test "find_node: finds root node" {
  let nodes = test_tree()
  let found = find_node(nodes, "documents")
  guard found is Some(node) else { fail!("should find documents") }
  inspect!(node.label, content="Documents")
}

///|
test "find_node: finds nested node" {
  let nodes = test_tree()
  let found = find_node(nodes, "project-a")
  guard found is Some(node) else { fail!("should find project-a") }
  inspect!(node.label, content="Project A")
}

///|
test "find_node: returns None for non-existent" {
  let nodes = test_tree()
  let found = find_node(nodes, "non-existent")
  inspect!(found.is_empty(), content="true")
}

///|
test "find_parent_id: root node has no parent" {
  let nodes = test_tree()
  let parent = find_parent_id(nodes, "documents", None)
  inspect!(parent.is_empty(), content="true")
}

///|
test "find_parent_id: finds direct parent" {
  let nodes = test_tree()
  let parent = find_parent_id(nodes, "report", None)
  guard parent is Some(pid) else { fail!("should find parent") }
  inspect!(pid, content="documents")
}

///|
test "find_parent_id: finds nested parent" {
  let nodes = test_tree()
  let parent = find_parent_id(nodes, "project-a", None)
  guard parent is Some(pid) else { fail!("should find parent") }
  inspect!(pid, content="projects")
}

///|
test "tree_node: creates node with children" {
  let node = tree_node("test", "Test", children=[
    tree_node("child1", "Child 1"),
    tree_node("child2", "Child 2"),
  ])
  inspect!(node.id, content="test")
  inspect!(node.label, content="Test")
  inspect!(node.children.length(), content="2")
  inspect!(has_children(node), content="true")
}

///|
test "tree_node: creates leaf node" {
  let node = tree_node("leaf", "Leaf Node")
  inspect!(node.id, content="leaf")
  inspect!(node.label, content="Leaf Node")
  inspect!(node.children.length(), content="0")
  inspect!(has_children(node), content="false")
}
