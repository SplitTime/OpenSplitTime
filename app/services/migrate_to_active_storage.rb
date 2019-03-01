# frozen_string_literal: true

class MigrateToActiveStorage
  require 'open-uri'
  require 'aws-sdk-s3'

  def self.perform(klass, attribute)
    new(klass, attribute).perform
  end

  def initialize(klass, attribute)
    @klass = klass
    @attribute = attribute
  end

  def perform
    get_blob_id = "LASTVAL()" # last value grabbed in postgres database

    ActiveRecord::Base.connection.raw_connection.prepare("active_storage_blob_statement", <<-SQL)
      INSERT INTO active_storage_blobs (
        key, filename, content_type, metadata, byte_size, checksum, created_at
      ) VALUES ($1, $2, $3, '{}', $4, $5, $6)
    SQL
    # With the values, SQL was complaining if I didn't have named variables ($1, etc.).

    ActiveRecord::Base.connection.raw_connection.prepare("active_storage_attachment_statement", <<-SQL)
      INSERT INTO active_storage_attachments (
        name, record_type, record_id, blob_id, created_at
      ) VALUES ($1, $2, $3, #{get_blob_id}, $4)
    SQL

    ActiveRecord::Base.transaction do
      klass.find_each.each do |resource|
        next if resource.send("#{attribute}_file_name").blank?

        make_active_storage_records(resource)
      end
    end
  end

  private

  attr_reader :klass, :attribute

  def make_active_storage_records(resource)
    blob_key = key(resource)
    filename = resource.send("#{attribute}_file_name")
    content_type = resource.send("#{attribute}_content_type")
    file_size = resource.send("#{attribute}_file_size")
    file_checksum = checksum(resource)
    created_at = resource.updated_at.iso8601

    blob_values = [blob_key, filename, content_type, file_size, file_checksum, created_at]
    ActiveRecord::Base.connection.raw_connection.exec_prepared(
        "active_storage_blob_statement",
        blob_values
    )

    # This will allow `klass.resource` calls to return an asset.
    blob_name = attribute
    record_type = klass.name
    record_id = resource.id

    attachment_values = [blob_name, record_type, record_id, created_at]
    ActiveRecord::Base.connection.raw_connection.exec_prepared(
        "active_storage_attachment_statement",
        attachment_values
    )
  end

  def key(resource)
    # This differs from the standard key mentioned in the
    # migration guide, because on S3 our file is
    # located under several nested folders. Just
    # putting the filename as the key means Active Storage
    # searches the root directory and the file is not there.
    resource.send(attribute).path
  end

  def checksum(resource)
    resource_url = resource.send(attribute).expiring_url(60)
    Rails.logger.info "Copy metadata for file: #{resource.send(attribute).path}"
    uri = URI.parse(resource_url)

    opened_uri = uri.open.read

    Digest::MD5.base64digest(opened_uri)
  end
end
