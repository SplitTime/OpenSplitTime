module ActiveStorage
  class BlobResource < Madmin::Resource
    # Attributes
    attribute :id, form: false
    attribute :key
    attribute :filename, index: true
    attribute :content_type, index: true
    attribute :byte_size, index: true
    attribute :checksum
    attribute :created_at, form: false
    attribute :service_name, index: true
    attribute :analyzed
    attribute :identified
    attribute :composed
    attribute :preview_image, index: false

    # Associations
    attribute :variant_records
    attribute :attachments

    def self.display_name(record)
      record.filename.to_s
    end

    # Uncomment this to customize the default sort column and direction.
    # def self.default_sort_column
    #   "created_at"
    # end
    #
    # def self.default_sort_direction
    #   "desc"
    # end
  end
end
