require "pathname"
require "language_pack"

# Manipulates/handles contents of the cache directory
class LanguagePack::Cache
  # @param [String] path to the cache store
  def initialize(cache_path)
    @cache_base = Pathname.new(cache_path)
  end

  # removes the the specified path from the cache
  # @param [String] relative path from the cache_base
  def clear(path)
    target = (@cache_base + path)
    target.exist? && target.rmtree
  end

  # Overwrite cache contents
  # When called the cache destination will be cleared and the new contents coppied over
  # This method is perferable as LanguagePack::Cache#add can cause accidental cache bloat.
  #
  # @param [String] path of contents to store. it will be stored using this a relative path from the cache_base.
  # @param [String] relative path to store the cache contents, if nil it will assume the from path
  def store(from, path = nil)
    path ||= from
    clear path
    copy from, (@cache_base + path)
  end

  # Adds file to cache without clearing the destination
  # Use LanguagePack::Cache#store to avoid accidental cache bloat
  def add(from, path = nil)
    path ||= from
    copy from, (@cache_base + path)
  end

  # load cache contents
  # @param [String] relative path of the cache contents
  # @param [String] path of where to store it locally, if nil, assume same relative path as the cache contents
  def load(path, dest = nil)
    dest ||= path
    copy (@cache_base + path), dest
  end

  # Store a path as an archive, which is more efficient for directories
  # with a lot of files (e.g. asset caches).
  # @param [String] path relative directory to store as an archive
  def store_archive(path)
    return false unless File.exist?(path)
    tar = archive_path(path)
    tar.delete if tar.exist?
    FileUtils.mkdir_p File.dirname(tar)
    system("tar -cf #{tar} #{path}")
  end

  # Store a path as an archive only if it has changed, based on the hash returned by `load_archive`.
  # @param [String] path relative directory to store as an archive
  # @param [String] previous_hash the previous hash of the directory from `load_archive`
  def store_archive_if_changed(path, previous_hash)
    store_archive(path) if dir_hash(path) != previous_hash
  end

  # Load a directory from an archive
  # @param [String] path relative directory path to restore
  # @return [String] a hash of the expanded directory contents, for use with `store_archive_if_changed`
  def load_archive(path)
    tar = archive_path(path)
    return false unless tar.exist?
    system("tar -xf #{tar}")
    dir_hash(path)
  end

  # Returns the archive file path given an app relative path
  def archive_path(path)
    (@cache_base + path).cleanpath.sub_ext(".tar")
  end

  def load_without_overwrite(path, dest=nil)
    dest ||= path
    copy (@cache_base + path), dest, '-a -n'
  end

  # copy cache contents
  # @param [String] source directory
  # @param [String] destination directory
  def copy(from, to, options='-a')
    return false unless File.exist?(from)
    FileUtils.mkdir_p File.dirname(to)
    system("cp #{options} #{from}/. #{to}")
  end

  # copy contents between to places in the cache
  # @param [String] source cache directory
  # @param [String] destination directory
  def cache_copy(from,to)
    copy(@cache_base + from, @cache_base + to)
  end

  # check if the cache content exists
  # @param [String] relative path of the cache contents
  # @param [Boolean] true if the path exists in the cache and false if otherwise
  def exists?(path)
    File.exists?(@cache_base + path)
  end

  # Returns a hash of a directory's recursive filenames and mtimes.
  def dir_hash(path)
    `ls -laAgGR --time-style=+%s #{path} | awk '{print $4 $5}' | sha1sum | head -c 40`
  end
end
