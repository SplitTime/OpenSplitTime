class LotteryDivisionResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :maximum_entries, index: true
  attribute :maximum_wait_list, index: true

  # Associations
  attribute :lottery, index: true
  attribute :entrants
  attribute :tickets
  attribute :draws

  def self.display_name(record)
    "#{record.lottery.name}: #{record.name}"
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
