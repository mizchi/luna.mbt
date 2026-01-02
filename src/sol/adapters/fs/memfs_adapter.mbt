///|
/// MemFSAdapter - FileSystem implementation for memfs
/// Wrapper type for memfs
pub struct MemFSAdapter {
  fs : @memfs.MemFS
  vol : @memfs.Volume
}

///|
/// Create a new in-memory filesystem
pub fn MemFSAdapter::new() -> MemFSAdapter {
  let (vol, fs) = @memfs.memfs()
  MemFSAdapter::{ fs, vol }
}

///|
/// Create from existing memfs instance
pub fn MemFSAdapter::from_memfs(
  vol : @memfs.Volume,
  fs : @memfs.MemFS,
) -> MemFSAdapter {
  MemFSAdapter::{ fs, vol }
}

///|
/// Get the underlying Volume for inspection
pub fn MemFSAdapter::volume(self : MemFSAdapter) -> @memfs.Volume {
  self.vol
}

///|
/// Get the underlying MemFS
pub fn MemFSAdapter::memfs(self : MemFSAdapter) -> @memfs.MemFS {
  self.fs
}

///|
pub impl @env.FileSystem for MemFSAdapter with read_file_sync(self, path) {
  @js.throwable(fn() { self.fs.readFileSync(path) })
}

///|
pub impl @env.FileSystem for MemFSAdapter with write_file_sync(
  self,
  path,
  content,
) {
  @js.throwable(fn() { self.fs.writeFileSync(path, content) })
}

///|
pub impl @env.FileSystem for MemFSAdapter with exists_sync(self, path) {
  self.fs.existsSync(path)
}

///|
pub impl @env.FileSystem for MemFSAdapter with mkdir_sync(self, path, recursive) {
  @js.throwable(fn() { self.fs.mkdirSync(path, recursive~) })
}

///|
pub impl @env.FileSystem for MemFSAdapter with readdir_sync(self, path) {
  @js.throwable(fn() { self.fs.readdirSync(path) })
}

///|
pub impl @env.FileSystem for MemFSAdapter with is_file_sync(self, path) {
  @js.throwable(fn() { self.fs.statSync(path).isFile() })
}

///|
pub impl @env.FileSystem for MemFSAdapter with is_directory_sync(self, path) {
  @js.throwable(fn() { self.fs.statSync(path).isDirectory() })
}

///|
pub impl @env.FileSystem for MemFSAdapter with cp_sync(
  self,
  src,
  dest,
  recursive,
) {
  @js.throwable(fn() { copy_recursive(self.fs, src, dest, recursive) })
}

///|
pub impl @env.FileSystem for MemFSAdapter with unlink_sync(self, path) {
  @js.throwable(fn() { self.fs.unlinkSync(path) })
}

///|
pub impl @env.FileSystem for MemFSAdapter with rmdir_sync(self, path, recursive) {
  @js.throwable(fn() { self.fs.rmdirSync(path, recursive~) })
}

///|
pub impl @env.FileSystem for MemFSAdapter with stat_sync(self, path) {
  @js.throwable(fn() {
    let stat = self.fs.statSync(path)
    @env.StatInfo::{
      is_file: stat.isFile(),
      is_directory: stat.isDirectory(),
      mtime_ms: stat.mtime_ms(),
      size: stat.size(),
    }
  })
}

// ============================================================
// Helper functions for cpSync implementation
// ============================================================

///|
/// Recursive copy implementation for memfs (which lacks cpSync)
fn copy_recursive(
  fs : @memfs.MemFS,
  src : String,
  dest : String,
  recursive : Bool,
) -> Unit {
  let stats = fs.statSync(src)
  if stats.isFile() {
    // Copy single file
    let content = fs.readFileSync(src)
    // Ensure parent directory exists
    let parent = dirname(dest)
    if not(parent.is_empty()) && not(fs.existsSync(parent)) {
      fs.mkdirSync(parent, recursive=true)
    }
    fs.writeFileSync(dest, content)
  } else if stats.isDirectory() && recursive {
    // Create destination directory
    if not(fs.existsSync(dest)) {
      fs.mkdirSync(dest, recursive=true)
    }
    // Copy all entries
    let entries = fs.readdirSync(src)
    for entry in entries {
      let src_path = join_path(src, entry)
      let dest_path = join_path(dest, entry)
      copy_recursive(fs, src_path, dest_path, recursive)
    }
  }
}

///|
/// Get directory name from path
fn dirname(path : String) -> String {
  let chars = path.to_array()
  let mut last_sep = -1
  for i, c in chars {
    if c == '/' {
      last_sep = i
    }
  }
  if last_sep < 0 {
    ""
  } else if last_sep == 0 {
    "/"
  } else {
    let result = StringBuilder::new()
    for i = 0; i < last_sep; i = i + 1 {
      result.write_char(chars[i])
    }
    result.to_string()
  }
}

///|
/// Join two path components
fn join_path(base : String, name : String) -> String {
  if base.has_suffix("/") {
    base + name
  } else {
    base + "/" + name
  }
}
