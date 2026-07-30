///|
/// NodeFsAdapter - FileSystem implementation for Node.js fs module
/// Wrapper type for Node.js fs module
pub struct NodeFsAdapter {}

///|
/// Create a new Node.js filesystem adapter
pub fn NodeFsAdapter::new() -> NodeFsAdapter {
  NodeFsAdapter::{  }
}

///|
pub impl @env.FileSystem for NodeFsAdapter with fn read_file_sync(self, path) {
  let _ = self
  @node_fs.read_file_as_string(path, encoding="utf8")
}

///|
pub impl @env.FileSystem for NodeFsAdapter with fn write_file_sync(
  self,
  path,
  content,
) {
  let _ = self
  @node_fs.writeFileSync(path, @js.any(content))
}

///|
pub impl @env.FileSystem for NodeFsAdapter with fn exists_sync(self, path) {
  let _ = self
  @node_fs.existsSync(path)
}

///|
pub impl @env.FileSystem for NodeFsAdapter with fn mkdir_sync(
  self,
  path,
  recursive,
) {
  let _ = self
  @node_fs.mkdirSync(path, recursive~)
}

///|
pub impl @env.FileSystem for NodeFsAdapter with fn readdir_sync(self, path) {
  let _ = self
  @node_fs.readdirSync(path)
}

///|
pub impl @env.FileSystem for NodeFsAdapter with fn is_file_sync(self, path) {
  let _ = self
  @node_fs.statSync(path).isFile()
}

///|
pub impl @env.FileSystem for NodeFsAdapter with fn is_directory_sync(self, path) {
  let _ = self
  @node_fs.statSync(path).isDirectory()
}

///|
pub impl @env.FileSystem for NodeFsAdapter with fn cp_sync(
  self,
  src,
  dest,
  recursive,
) {
  let _ = self
  @node_fs.cpSync(src, dest, recursive~)
}

///|
pub impl @env.FileSystem for NodeFsAdapter with fn unlink_sync(self, path) {
  let _ = self
  @node_fs.unlinkSync(path)
}

///|
pub impl @env.FileSystem for NodeFsAdapter with fn rmdir_sync(
  self,
  path,
  recursive,
) {
  let _ = self
  @node_fs.rmdirSync(path, recursive~)
}

///|
pub impl @env.FileSystem for NodeFsAdapter with fn stat_sync(self, path) {
  let _ = self
  let stat = @node_fs.statSync(path)
  @env.StatInfo::{
    is_file: stat.isFile(),
    is_directory: stat.isDirectory(),
    mtime_ms: stat.mtime_ms(),
    size: stat.size(),
  }
}
