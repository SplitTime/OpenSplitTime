class FileStore
  require 'open-uri'

  MAX_FILESIZE = 2.megabytes

  def self.public_upload(directory, file, id)
    if Rails.env.test?
      file.path
    elsif file_size_ok(file)
      key = "#{directory}/#{id}/#{file.original_filename}"
      public_url = S3FileManager.public_upload(key, file)
      public_url
    else
      errors.add(:bucket_store_service, "Import file must be less than #{MAX_FILESIZE / 1024 / 1024} MB")
      false
    end
  end

  # Returns a File or StringIO object in memory
  def self.get(path_or_url)
    case
    when uri?(path_or_url)
      begin
        open(path_or_url)
      rescue OpenURI::HTTPError
        nil
      end
    when local_path?(path_or_url)
      full_path = "#{Rails.root}#{path_or_url}"
      File.exists?(full_path) ? File.new(full_path) : nil
    else # Assume it is an s3 key
      begin
        S3FileManager.read(path_or_url)
      rescue Aws::S3::Errors::NoSuchKey
        nil
      end
    end
  end

  def self.file_size_ok(file)
    file.size <= MAX_FILESIZE
  end

  def self.uri?(string)
    string.start_with?('http://', 'https://')
  end

  def self.local_path?(string)
    string.start_with?('/')
  end
end
