///|
test "MemFSAdapter basic read/write" {
  let fs = MemFSAdapter::new()
  let mem = fs.memfs()
  mem.writeFileSync("/test.txt", "Hello, World!")
  let content = mem.readFileSync("/test.txt")
  inspect(content, content="Hello, World!")
}

///|
test "MemFSAdapter exists_sync" {
  let fs = MemFSAdapter::new()
  let mem = fs.memfs()
  inspect(mem.existsSync("/test.txt"), content="false")
  mem.writeFileSync("/test.txt", "content")
  inspect(mem.existsSync("/test.txt"), content="true")
}

///|
test "MemFSAdapter mkdir_sync recursive" {
  let fs = MemFSAdapter::new()
  let mem = fs.memfs()
  mem.mkdirSync("/a/b/c", recursive=true)
  inspect(mem.existsSync("/a"), content="true")
  inspect(mem.existsSync("/a/b"), content="true")
  inspect(mem.existsSync("/a/b/c"), content="true")
}

///|
test "MemFSAdapter readdir_sync" {
  let fs = MemFSAdapter::new()
  let mem = fs.memfs()
  mem.mkdirSync("/dir")
  mem.writeFileSync("/dir/a.txt", "a")
  mem.writeFileSync("/dir/b.txt", "b")
  let entries = mem.readdirSync("/dir")
  inspect(entries.length(), content="2")
}

///|
test "MemFSAdapter stat_sync" {
  let fs = MemFSAdapter::new()
  let mem = fs.memfs()
  mem.writeFileSync("/test.txt", "Hello")
  let stat = mem.statSync("/test.txt")
  inspect(stat.isFile(), content="true")
  inspect(stat.isDirectory(), content="false")
  inspect(stat.size(), content="5")
}

///|
test "MemFSAdapter unlink_sync" {
  let fs = MemFSAdapter::new()
  let mem = fs.memfs()
  mem.writeFileSync("/test.txt", "content")
  inspect(mem.existsSync("/test.txt"), content="true")
  mem.unlinkSync("/test.txt")
  inspect(mem.existsSync("/test.txt"), content="false")
}

///|
test "MemFSAdapter rmdir_sync" {
  let fs = MemFSAdapter::new()
  let mem = fs.memfs()
  mem.mkdirSync("/dir")
  mem.writeFileSync("/dir/file.txt", "content")
  mem.rmdirSync("/dir", recursive=true)
  inspect(mem.existsSync("/dir"), content="false")
}
