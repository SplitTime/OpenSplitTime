module Shortener
  class ShortenedUrlResource < Madmin::Resource
    # Attributes
    attribute :id, form: false
    attribute :url, index: true
    attribute :unique_key, index: true
    attribute :category, index: true
    attribute :use_count, form: false, index: true
    attribute :expires_at, index: true
    attribute :created_at, form: false
    attribute :updated_at, form: false

    # Associations
    attribute :owner

    # Uncomment this to customize the display name of records in the admin area.
    # def self.display_name(record)
    #   record.name
    # end

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
