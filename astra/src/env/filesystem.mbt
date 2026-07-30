///|
/// FileSystem Trait - Abstract file system operations
///
/// This trait abstracts file system operations to allow:
/// - Real filesystem via Node.js fs module
/// - In-memory filesystem via memfs
/// - Testing without writing real files
/// - Cross-platform compatibility

///|
/// File/directory statistics (platform-independent)
pub(open) trait FileStat {
  /// Returns true if this is a file
  fn isFile(Self) -> Bool

  /// Returns true if this is a directory
  fn isDirectory(Self) -> Bool

  /// Returns the modification time in milliseconds since epoch
  fn mtime_ms(Self) -> Float

  /// Returns the file size in bytes
  fn size(Self) -> Int
}

///|
/// Platform-independent file statistics
/// Used as the return type for stat_sync across all platforms
pub(all) struct StatInfo {
  is_file : Bool
  is_directory : Bool
  mtime_ms : Float
  size : Int
} derive(Eq, Debug)

///|
pub impl FileStat for StatInfo with fn isFile(self) {
  self.is_file
}

///|
pub impl FileStat for StatInfo with fn isDirectory(self) {
  self.is_directory
}

///|
pub impl FileStat for StatInfo with fn mtime_ms(self) {
  self.mtime_ms
}

///|
pub impl FileStat for StatInfo with fn size(self) {
  self.size
}

///|
/// Abstract file system operations
pub(open) trait FileSystem {
  /// Read file content as string (UTF-8)
  fn read_file_sync(Self, String) -> String raise Error

  /// Write string content to file
  fn write_file_sync(Self, String, String) -> Unit raise Error

  /// Check if path exists
  fn exists_sync(Self, String) -> Bool

  /// Create directory (recursive: Bool)
  fn mkdir_sync(Self, String, Bool) -> Unit raise Error

  /// Read directory contents
  fn readdir_sync(Self, String) -> Array[String] raise Error

  /// Get file/directory stats (returns something implementing FileStat)
  fn is_file_sync(Self, String) -> Bool raise Error

  /// Check if path is a directory
  fn is_directory_sync(Self, String) -> Bool raise Error

  /// Copy file or directory (recursive: Bool)
  fn cp_sync(Self, String, String, Bool) -> Unit raise Error

  /// Remove file
  fn unlink_sync(Self, String) -> Unit raise Error

  /// Remove directory (recursive: Bool)
  fn rmdir_sync(Self, String, Bool) -> Unit raise Error

  /// Get file/directory statistics
  /// Returns StatInfo with mtime_ms and size
  fn stat_sync(Self, String) -> StatInfo raise Error
}
