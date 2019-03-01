# frozen_string_literal: true

class MigrateToActiveStorage
  require 'open-uri'
  require 'aws-sdk-s3'

  def perform
    get_blob_id = 'LASTVAL()'

    ActiveRecord::Base.connection.raw_connection.prepare("active_storage_blob_statement", <<-SQL)
      INSERT INTO active_storage_blobs (
        key, filename, content_type, metadata, byte_size, checksum, created_at
      ) VALUES ($1, $2, $3, '{}', $4, $5, $6)
    SQL

    ActiveRecord::Base.connection.raw_connection.prepare("active_storage_attachment_statement", <<-SQL)
      INSERT INTO active_storage_attachments (
        name, record_type, record_id, blob_id, created_at
      ) VALUES ($1, $2, $3, #{get_blob_id}, $4)
    SQL

    model_map = {Course => :gpx, Effort => :photo, Partner => :banner, Person => :photo}

    model_map.each do |model, attribute|
      model.where.not("#{attribute}_file_name" => nil).find_each.each do |resource|
        make_active_storage_records(resource, attribute, model)
      end
    end
  end

  private

  def make_active_storage_records(resource, attribute, model)
    blob_key = key(resource, attribute).sub(/\A\//, '')
    filename = resource.send("#{attribute}_file_name")
    content_type = resource.send("#{attribute}_content_type")
    file_size = resource.send("#{attribute}_file_size")
    file_checksum = checksum(resource, attribute)
    created_at = resource.updated_at.iso8601

    blob_values = [blob_key, filename, content_type, file_size, file_checksum, created_at]

    ActiveRecord::Base.connection.raw_connection.exec_prepared(
        "active_storage_blob_statement",
        blob_values
    )

    blob_name = attribute
    record_type = model.name
    record_id = resource.id

    attachment_values = [blob_name, record_type, record_id, created_at]
    ActiveRecord::Base.connection.raw_connection.exec_prepared(
        "active_storage_attachment_statement",
        attachment_values
    )
  end

  def key(resource, attribute)
    resource.send("#{attribute}").path
  end

  def checksum(resource, attribute)
    resource_url = resource.send(attribute).expiring_url(60)
    Rails.logger.info "Copy metadata for file: #{resource.send(attribute).path}"
    uri = URI.parse(resource_url)

    opened_uri = uri.open.read

    Digest::MD5.base64digest(opened_uri)
  end
end
