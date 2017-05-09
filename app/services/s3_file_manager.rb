class S3FileManager

  def self.public_upload(key, file)
    obj = Aws::S3::Resource.new.bucket(ENV['S3_BUCKET']).object(key)
    obj.upload_file(file.path, acl: 'public-read')
    obj.public_url
  end

  # Returns a StringIO object containing the entire contents of the file
  def self.read(key)
    obj = Aws::S3::Resource.new.bucket(ENV['S3_BUCKET']).object(key)
    obj.get.body
  end
end
