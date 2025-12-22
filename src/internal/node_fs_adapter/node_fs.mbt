/// NodeFS - FileSystem implementation for Node.js fs module

///|
/// Wrapper type for Node.js fs module
pub struct NodeFS {}

///|
/// Create a NodeFS instance
pub fn NodeFS::new() -> NodeFS {
  NodeFS::{  }
}

///|
pub impl @env.FileSystem for NodeFS with read_file_sync(self, path) {
  ignore(self)
  @fs.read_file_as_string(path)
}

///|
pub impl @env.FileSystem for NodeFS with write_file_sync(self, path, content) {
  ignore(self)
  @fs.writeFileSync(path, @js.any(content))
}

///|
pub impl @env.FileSystem for NodeFS with exists_sync(self, path) {
  ignore(self)
  @fs.existsSync(path)
}

///|
pub impl @env.FileSystem for NodeFS with mkdir_sync(self, path, recursive) {
  ignore(self)
  @fs.mkdirSync(path, recursive~)
}

///|
pub impl @env.FileSystem for NodeFS with readdir_sync(self, path) {
  ignore(self)
  @fs.readdirSync(path)
}

///|
pub impl @env.FileSystem for NodeFS with is_file_sync(self, path) {
  ignore(self)
  @fs.statSync(path).isFile()
}

///|
pub impl @env.FileSystem for NodeFS with is_directory_sync(self, path) {
  ignore(self)
  @fs.statSync(path).isDirectory()
}

///|
pub impl @env.FileSystem for NodeFS with cp_sync(self, src, dest, recursive) {
  ignore(self)
  @fs.cpSync(src, dest, recursive~)
}

///|
pub impl @env.FileSystem for NodeFS with unlink_sync(self, path) {
  ignore(self)
  @fs.unlinkSync(path)
}

///|
pub impl @env.FileSystem for NodeFS with rmdir_sync(self, path, recursive) {
  ignore(self)
  @fs.rmSync(path, recursive~, force=true)
}
