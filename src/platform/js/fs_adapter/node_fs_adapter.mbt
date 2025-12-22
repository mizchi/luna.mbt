/// NodeFsAdapter - FileSystem implementation for Node.js fs module

///|
/// Wrapper type for Node.js fs module
pub struct NodeFsAdapter {}

///|
/// Create a new Node.js filesystem adapter
pub fn NodeFsAdapter::new() -> NodeFsAdapter {
  NodeFsAdapter::{  }
}

///|
pub impl @env.FileSystem for NodeFsAdapter with read_file_sync(self, path) {
  let _ = self
  @js.throwable(fn() { @fs.read_file_as_string(path, encoding="utf8") })
}

///|
pub impl @env.FileSystem for NodeFsAdapter with write_file_sync(
  self,
  path,
  content,
) {
  let _ = self
  @js.throwable(fn() { @fs.writeFileSync(path, @js.any(content)) })
}

///|
pub impl @env.FileSystem for NodeFsAdapter with exists_sync(self, path) {
  let _ = self
  @fs.existsSync(path)
}

///|
pub impl @env.FileSystem for NodeFsAdapter with mkdir_sync(
  self,
  path,
  recursive,
) {
  let _ = self
  @js.throwable(fn() { @fs.mkdirSync(path, recursive~) })
}

///|
pub impl @env.FileSystem for NodeFsAdapter with readdir_sync(self, path) {
  let _ = self
  @js.throwable(fn() { @fs.readdirSync(path) })
}

///|
pub impl @env.FileSystem for NodeFsAdapter with is_file_sync(self, path) {
  let _ = self
  @js.throwable(fn() { @fs.statSync(path).isFile() })
}

///|
pub impl @env.FileSystem for NodeFsAdapter with is_directory_sync(self, path) {
  let _ = self
  @js.throwable(fn() { @fs.statSync(path).isDirectory() })
}

///|
pub impl @env.FileSystem for NodeFsAdapter with cp_sync(
  self,
  src,
  dest,
  recursive,
) {
  let _ = self
  @js.throwable(fn() { @fs.cpSync(src, dest, recursive~) })
}

///|
pub impl @env.FileSystem for NodeFsAdapter with unlink_sync(self, path) {
  let _ = self
  @js.throwable(fn() { @fs.unlinkSync(path) })
}

///|
pub impl @env.FileSystem for NodeFsAdapter with rmdir_sync(
  self,
  path,
  recursive,
) {
  let _ = self
  @js.throwable(fn() { @fs.rmdirSync(path, recursive~) })
}
