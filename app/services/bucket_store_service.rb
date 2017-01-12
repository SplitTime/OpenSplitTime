class BucketStoreService

  MAX_FILESIZE = 500.megabytes

  def self.upload_to_bucket(directory, file, id)
    if Rails.env == 'development'
      file.path
    elsif file_size_ok(file)
      obj = Aws::S3::Resource.new.bucket(ENV['S3_BUCKET']).object("#{directory}/#{id}/#{file.original_filename}")
      obj.upload_file(file.path, acl: 'public-read')
      obj.public_url
    else
      errors.add(:bucket_store_service, "Import file must be less than #{MAX_FILESIZE / 1024 / 1024} MB")
      false
    end
  end

  def self.file_size_ok(file)
    file.size <= MAX_FILESIZE
  end

end