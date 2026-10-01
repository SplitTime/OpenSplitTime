class LotteryTicketResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :lottery_division_id
  attribute :lottery_entrant_id
  attribute :reference_number, index: true
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :lottery, index: true
  attribute :division, index: true
  attribute :entrant, index: true
  attribute :draw

  def self.display_name(record)
    "##{record.reference_number} (#{record.entrant_full_name})"
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
