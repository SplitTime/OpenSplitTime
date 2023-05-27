# frozen_string_literal: true

class Notification < ApplicationRecord
  include Auditable

  enum kind: [:participation, :progress]

  belongs_to :effort
  has_one :event, through: :effort
end
