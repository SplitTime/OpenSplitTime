# Based on a strategy described in
# https://www.cookieshq.co.uk/posts/creating-a-sitemap-with-ruby-on-rails-and-upload-it-to-amazon-s3

require 'aws-sdk'

namespace :sitemap do
  desc 'Upload the sitemap files to S3'
  task upload_to_s3: :environment do
    puts "Starting sitemap upload to S3..."

    bucket = Aws::S3::Resource.new.bucket(ENV['S3_BUCKET'])

    Dir.entries(File.join(Rails.root, "tmp", "sitemaps")).each do |file_name|
      next if %w(. .. .DS_Store).include?(file_name)
      bucket_path = "sitemaps/#{file_name}"
      file_path = File.join(Rails.root, "tmp", "sitemaps", file_name)

      begin
        obj = bucket.object(bucket_path)
        obj.upload_file(file_path, acl: 'public-read')
      rescue Exception => e
        raise e
      end
      puts "Saved #{file_name} to S3"
    end
  end

  desc 'Create the sitemap, then upload it to S3 and ping the search engines'
  task create_upload_and_ping: :environment do
    Rake::Task["sitemap:create"].invoke

    Rake::Task["sitemap:upload_to_s3"].invoke

    SitemapGenerator::Sitemap.ping_search_engines('https://www.opensplittime.org/sitemap.xml.gz')
  end
end
