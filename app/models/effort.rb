class Effort < ActiveRecord::Base
  belongs_to :event
  belongs_to :participant
  belongs_to :country
  has_many :split_times

  validates_presence_of :event_id, :participant_id, :start_time
  validates_uniqueness_of :participant_id, scope: :event_id
  validates_uniqueness_of :bib_number, scope: :event_id, allow_nil: true
  validates :country, presence: true, unless: 'country_id.nil?'
end
