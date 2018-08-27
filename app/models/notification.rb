# frozen_string_literal: true

class Notification < ApplicationRecord
  include Auditable

  belongs_to :effort
  has_one :event, through: :effort
end
