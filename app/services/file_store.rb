class FileStore

  MAX_FILESIZE = 50.megabytes

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

  def self.read(path_or_url)
    case
    when uri?(path_or_url)
      key = URI.decode(URI.parse(path_or_url).path[1..-1])
      S3FileManager.read(key)
    when local_path?(path_or_url)
      full_path = "#{Rails.root}#{path_or_url}"
      File.new(full_path)
    else # Assume it is an s3 key
      S3FileManager.read(path_or_url)
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
