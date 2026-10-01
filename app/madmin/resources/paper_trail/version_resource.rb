module PaperTrail
  class VersionResource < Madmin::Resource
    # Attributes
    attribute :id, form: false
    attribute :item, index: true
    attribute :event, index: true
    attribute :whodunnit, index: true
    attribute :object
    attribute :created_at, form: false
    attribute :object_changes

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
