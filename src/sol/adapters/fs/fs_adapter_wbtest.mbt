///|
test "dirname helper" {
  inspect(dirname("/a/b/c.txt"), content="/a/b")
  inspect(dirname("/file.txt"), content="/")
  inspect(dirname("file.txt"), content="")
  inspect(dirname("/"), content="/")
}

///|
test "join_path helper" {
  inspect(join_path("/a", "b"), content="/a/b")
  inspect(join_path("/a/", "b"), content="/a/b")
  inspect(join_path("", "b"), content="/b")
}

///|
test "cp_sync file via trait" {
  let adapter = MemFSAdapter::new()
  let mem = adapter.memfs()
  mem.writeFileSync("/src.txt", "copied content")
  // Use internal copy_recursive function
  copy_recursive(mem, "/src.txt", "/dest.txt", false)
  let content = mem.readFileSync("/dest.txt")
  inspect(content, content="copied content")
}

///|
test "cp_sync directory recursive" {
  let adapter = MemFSAdapter::new()
  let mem = adapter.memfs()
  mem.mkdirSync("/src/sub", recursive=true)
  mem.writeFileSync("/src/a.txt", "a")
  mem.writeFileSync("/src/sub/b.txt", "b")
  // Use internal copy_recursive function
  copy_recursive(mem, "/src", "/dest", true)
  inspect(mem.existsSync("/dest/a.txt"), content="true")
  inspect(mem.existsSync("/dest/sub/b.txt"), content="true")
  let content = mem.readFileSync("/dest/sub/b.txt")
  inspect(content, content="b")
}

///|
test "FileSystem trait read/write" {
  let adapter = MemFSAdapter::new()
  @env.FileSystem::write_file_sync(adapter, "/trait.txt", "trait content")
  let content = @env.FileSystem::read_file_sync(adapter, "/trait.txt")
  inspect(content, content="trait content")
}

///|
test "FileSystem trait exists_sync" {
  let adapter = MemFSAdapter::new()
  inspect(@env.FileSystem::exists_sync(adapter, "/test.txt"), content="false")
  @env.FileSystem::write_file_sync(adapter, "/test.txt", "content")
  inspect(@env.FileSystem::exists_sync(adapter, "/test.txt"), content="true")
}

///|
test "FileSystem trait mkdir_sync" {
  let adapter = MemFSAdapter::new()
  @env.FileSystem::mkdir_sync(adapter, "/a/b/c", true)
  inspect(@env.FileSystem::exists_sync(adapter, "/a/b/c"), content="true")
}
