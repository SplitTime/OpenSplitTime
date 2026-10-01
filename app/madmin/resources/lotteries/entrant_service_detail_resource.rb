module Lotteries
  class EntrantServiceDetailResource < Madmin::Resource
    # Attributes
    attribute :lottery_entrant_id
    attribute :form_accepted_at, index: true
    attribute :form_rejected_at, index: true
    attribute :form_accepted_comments
    attribute :form_rejected_comments
    attribute :created_at, form: false
    attribute :updated_at, form: false
    attribute :completed_date, index: true

    # Associations
    attribute :entrant, index: true
    attribute :completed_form, index: false

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
