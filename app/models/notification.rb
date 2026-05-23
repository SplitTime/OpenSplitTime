class Notification < ApplicationRecord
  enum :kind, {
    participation: 0,
    progress: 1,
    event_update: 2,
  }

  belongs_to :effort
  has_one :event, through: :effort
end
