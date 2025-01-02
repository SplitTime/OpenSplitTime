class Notification < ApplicationRecord
  include Auditable

  enum kind: [:participation, :progress, :event_update]

  belongs_to :effort
  has_one :event, through: :effort
end
