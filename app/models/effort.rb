class Effort < ActiveRecord::Base
  enum gender: [:male, :female]
  belongs_to :event
  belongs_to :participant
  has_many :split_times, dependent: :destroy

  validates_presence_of :event_id
  validates_uniqueness_of :participant_id, scope: :event_id, unless: 'participant_id.nil?'
  validates_uniqueness_of :bib_number, scope: :event_id, allow_nil: true

  def self.columns_for_import
    id = ["id"]
    foreign_keys = Effort.column_names.find_all { |x| x.include?("_id") }
    stamps = Effort.column_names.find_all { |x| x.include?("_at") | x.include?("_by") }
    (column_names - (id + foreign_keys + stamps)).map &:to_sym
  end

  def full_name
    first_name + " " + last_name
  end

end
